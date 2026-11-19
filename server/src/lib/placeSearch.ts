import { ApiError } from '../http';
import { cellKey, type CellRecord, type CellStore, type CellWrite } from './cellStore';
import { boundsAround, distanceMeters, distanceToBounds, quarter, type Bounds } from './geo';
import { geohashBounds, geohashesCovering } from './geohash';
import { KAKAO_MAX_RESULTS, KAKAO_PAGE_SIZE, type KakaoClient, type Place } from './kakao';

/**
 * 반경 안 음식점 검색 (PLAN.md 4.2 영역 분할).
 *
 * 카카오 카테고리 검색은 한 조건에 최대 45개만 주므로,
 * 지도를 고정된 칸(geohash 5자리, 약 4km)으로 나누고 45개가 넘는 칸은 4등분을 반복한다.
 * 칸 결과는 24시간 캐시해서 같은 동네 사용자끼리 나눠 쓴다. 칸은 사용자 위치와 무관하게
 * 고정되어 있어서, 캐시에는 식당 정보와 칸 이름만 남고 요청한 좌표는 남지 않는다.
 *
 * 요청 한 번에 카카오 호출은 budget 번까지만 한다. 다 못 채운 칸은 complete=false 로 알리고,
 * 앱이 다시 부르면 캐시된 칸은 건너뛰고 남은 칸부터 이어서 채운다.
 */
export const TILE_PRECISION = 5;
export const MAX_DEPTH = 6;
export const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

/** 새 칸 하나에 필요한 최대 호출 수 (45개 = 15개 × 3페이지). */
const CALLS_PER_CELL = Math.ceil(KAKAO_MAX_RESULTS / KAKAO_PAGE_SIZE);

export interface SearchOptions {
  lat: number;
  lng: number;
  radiusM: number;
  /** 카카오 호출 최대 횟수. */
  budget: number;
  nowMs: number;
  /** 동시에 보내는 카카오 요청 수. Workers는 동시 연결 6개까지. */
  concurrency?: number;
}

export interface NearbyPlace extends Place {
  /** 10m 단위로 반올림한 직선 거리. */
  distanceM: number;
}

export interface SearchResult {
  places: NearbyPlace[];
  /** 반경 안 칸을 모두 확인했는지. false면 다시 부르면 더 채워진다. */
  complete: boolean;
  /** 아주 좁은 칸에도 45개가 넘어 일부가 빠졌을 수 있는지. */
  truncated: boolean;
  kakaoCalls: number;
  cachedCells: number;
}

interface Cell {
  tile: string;
  path: string;
  bounds: Bounds;
}

export async function searchNearby(
  kakao: KakaoClient,
  store: CellStore,
  options: SearchOptions,
): Promise<SearchResult> {
  const { lat, lng, radiusM, nowMs } = options;
  const concurrency = options.concurrency ?? 6;
  const touchesCircle = (b: Bounds) => distanceToBounds(lat, lng, b) <= radiusM;

  const tiles = geohashesCovering(boundsAround(lat, lng, radiusM), TILE_PRECISION).filter((t) =>
    touchesCircle(geohashBounds(t)),
  );
  const cache = await store.load(tiles, nowMs);

  const found = new Map<string, Place>();
  const writes: CellWrite[] = [];
  let budget = options.budget;
  let kakaoCalls = 0;
  let cachedCells = 0;
  let complete = true;
  let truncated = false;
  let failure: unknown = null;

  const remember = (cell: Cell, record: CellRecord) => {
    writes.push({ tile: cell.tile, path: cell.path, record });
  };
  const children = (cell: Cell): Cell[] =>
    quarter(cell.bounds).map((bounds, i) => ({ tile: cell.tile, path: cell.path + i, bounds }));
  const addLeaf = (places: Place[], isTruncated: boolean) => {
    for (const p of places) found.set(p.id, p);
    truncated ||= isTruncated;
  };

  const visit = async (cell: Cell, next: Cell[]) => {
    const cached = cache.get(cellKey(cell.tile, cell.path));
    if (cached) {
      cachedCells++;
      if (cached.kind === 'split') next.push(...children(cell));
      else addLeaf(cached.places, cached.truncated);
      return;
    }
    if (failure !== null || budget < CALLS_PER_CELL) {
      complete = false;
      return;
    }
    // 첫 await 전에 예약해야 동시에 도는 다른 칸과 겹치지 않는다.
    budget -= CALLS_PER_CELL;
    let used = 0;
    try {
      used++;
      const first = await kakao.searchRestaurants(cell.bounds, 1);
      kakaoCalls++;
      if (first.totalCount > KAKAO_MAX_RESULTS && cell.path.length < MAX_DEPTH) {
        remember(cell, { kind: 'split' });
        next.push(...children(cell));
        return;
      }
      const places = [...first.places];
      let isEnd = first.isEnd;
      for (let page = 2; !isEnd && page <= CALLS_PER_CELL; page++) {
        used++;
        const more = await kakao.searchRestaurants(cell.bounds, page);
        kakaoCalls++;
        places.push(...more.places);
        isEnd = more.isEnd;
      }
      const isTruncated = first.totalCount > KAKAO_MAX_RESULTS;
      remember(cell, { kind: 'leaf', places, truncated: isTruncated });
      addLeaf(places, isTruncated);
    } catch (error) {
      // 이 칸은 저장하지 않고 다음 요청에서 다시 시도한다.
      failure ??= error;
      complete = false;
    } finally {
      budget += CALLS_PER_CELL - used;
    }
  };

  let round: Cell[] = tiles.map((tile) => ({ tile, path: '', bounds: geohashBounds(tile) }));
  while (round.length > 0) {
    // 가까운 칸부터 채워야 호출 한도에 걸려도 쓸모 있는 결과가 남는다.
    const cells = round
      .filter((c) => touchesCircle(c.bounds))
      .sort((a, b) => distanceToBounds(lat, lng, a.bounds) - distanceToBounds(lat, lng, b.bounds));
    const next: Cell[] = [];
    await runPool(cells, concurrency, (cell) => visit(cell, next));
    round = next;
  }

  if (writes.length > 0) await store.save(writes, nowMs + CACHE_TTL_MS);
  if (found.size === 0 && failure !== null) {
    throw failure instanceof ApiError
      ? failure
      : new ApiError(502, 'UPSTREAM_ERROR', '식당 정보를 가져오지 못했습니다');
  }

  const places: NearbyPlace[] = [];
  for (const p of found.values()) {
    const d = distanceMeters(lat, lng, p.lat, p.lng);
    if (d <= radiusM) places.push({ ...p, distanceM: Math.round(d / 10) * 10 });
  }
  places.sort((a, b) => a.distanceM - b.distanceM || a.id.localeCompare(b.id));
  return { places, complete, truncated, kakaoCalls, cachedCells };
}

async function runPool<T>(items: T[], limit: number, task: (item: T) => Promise<void>) {
  let index = 0;
  const worker = async () => {
    while (index < items.length) await task(items[index++]!);
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
}
