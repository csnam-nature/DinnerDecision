import { describe, expect, it } from 'vitest';
import { D1CellStore, purgeExpired } from '../src/lib/cellStore';
import { distanceMeters } from '../src/lib/geo';
import { KakaoClient } from '../src/lib/kakao';
import { CACHE_TTL_MS, searchNearby } from '../src/lib/placeSearch';
import { createTestD1, fakeKakao, rowCount, scatterPlaces } from './support';

const here = { lat: 37.5446, lng: 127.0559 };
const now = Date.UTC(2026, 10, 19, 9);

function setup(count: number, spreadM = 1500, kakaoOptions = {}) {
  const all = scatterPlaces(here.lat, here.lng, count, spreadM);
  const kakao = fakeKakao(all, kakaoOptions);
  const db = createTestD1();
  return {
    all,
    kakao,
    db,
    run: (budget = 40, nowMs = now) =>
      searchNearby(new KakaoClient('test-key', kakao.fetchFn), new D1CellStore(db), {
        ...here,
        radiusM: 1000,
        budget,
        nowMs,
      }),
  };
}

const insideRadius = (all: ReturnType<typeof scatterPlaces>) =>
  all.filter((p) => distanceMeters(here.lat, here.lng, p.lat, p.lng) <= 1000).map((p) => p.id);

describe('searchNearby', () => {
  it('식당이 적으면 한 번에 반경 안 전부를 가까운 순으로 준다', async () => {
    const { all, run } = setup(30);
    const result = await run();
    expect(result.complete).toBe(true);
    expect(result.truncated).toBe(false);
    expect(result.places.map((p) => p.id).sort()).toEqual(insideRadius(all).sort());
    const distances = result.places.map((p) => p.distanceM);
    expect(distances).toEqual([...distances].sort((a, b) => a - b));
    expect(result.places[0]).toMatchObject({ category: expect.stringContaining('음식점'), url: expect.any(String) });
  });

  it('45개가 넘는 칸은 나눠서 빠짐없이 모은다', async () => {
    const { all, run } = setup(2000);
    const result = await run(1000);
    expect(result.places.length).toBeGreaterThan(500);
    expect(result.complete).toBe(true);
    expect(result.places.map((p) => p.id).sort()).toEqual(insideRadius(all).sort());
  });

  it('호출 한도를 넘으면 일부만 주고, 다시 부르면 캐시 다음부터 이어서 채운다', async () => {
    // 반경 안 약 700곳: 한 번에 40회로는 다 못 채운다.
    const { all, kakao, run } = setup(2000);
    const first = await run(40);
    expect(first.complete).toBe(false);
    expect(first.kakaoCalls).toBeLessThanOrEqual(40);
    expect(first.places.length).toBeGreaterThan(0);

    let result = first;
    for (let i = 0; i < 20 && !result.complete; i++) result = await run(40);
    expect(result.complete).toBe(true);
    expect(result.places.map((p) => p.id).sort()).toEqual(insideRadius(all).sort());

    // 다 채운 뒤에는 카카오를 부르지 않는다.
    const before = kakao.calls.length;
    const cached = await run(40);
    expect(kakao.calls.length).toBe(before);
    expect(cached.kakaoCalls).toBe(0);
    expect(cached.places.length).toBe(result.places.length);
  });

  it('캐시가 만료되면 다시 검색한다', async () => {
    const { kakao, db, run } = setup(30);
    await run();
    const calls = kakao.calls.length;
    await run(40, now + CACHE_TTL_MS + 1);
    expect(kakao.calls.length).toBeGreaterThan(calls);

    await purgeExpired(db, now + CACHE_TTL_MS + 1);
    expect(rowCount(db, 'place_cells')).toBeGreaterThan(0); // 새로 저장한 칸은 남는다
    await purgeExpired(db, now + 3 * CACHE_TTL_MS);
    expect(rowCount(db, 'place_cells')).toBe(0);
  });

  it('카카오가 처음부터 실패하면 오류를 낸다', async () => {
    const { run } = setup(30, 1500, { failAfter: 0, status: 429 });
    await expect(run()).rejects.toMatchObject({ status: 503, code: 'UPSTREAM_LIMIT' });
  });

  it('중간에 실패하면 받은 데까지 주고 complete=false', async () => {
    // 첫 요청(35회)은 성공, 두 번째 요청 중간부터 실패
    const { run } = setup(2000, 1500, { failAfter: 40 });
    const first = await run(40);
    const second = await run(40);
    expect(second.complete).toBe(false);
    expect(second.places.length).toBeGreaterThan(first.places.length);
  });

  it('캐시에 좌표 대신 칸 이름만 저장한다', async () => {
    const { db, run } = setup(30);
    await run();
    const rows = (await db.prepare('SELECT tile, path FROM place_cells').all<{ tile: string; path: string }>()).results;
    expect(rows.length).toBeGreaterThan(0);
    for (const row of rows) {
      expect(row.tile).toMatch(/^[0-9bcdefghjkmnpqrstuvwxyz]{5}$/);
      expect(row.path).toMatch(/^[0-3]*$/);
    }
  });
});
