import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import type { FetchLike } from '../src/lib/kakao';

/**
 * 테스트용 D1. node:sqlite 위에 D1 API 중 서버가 쓰는 부분만 흉내 낸다.
 * 실제 D1도 SQLite라 SQL은 그대로 확인할 수 있다.
 */
export function createTestD1(): D1Database {
  const sqlite = new DatabaseSync(':memory:');
  sqlite.exec(readFileSync(new URL('../migrations/0001_init.sql', import.meta.url), 'utf8'));

  const statement = (sql: string, params: unknown[] = []) => {
    const values = params as Array<string | number | null>;
    return {
      sql,
      params,
      bind: (...next: unknown[]) => statement(sql, next),
      first: async (column?: string) => {
        const row = sqlite.prepare(sql).get(...values) as Record<string, unknown> | undefined;
        if (!row) return null;
        return column ? row[column] : row;
      },
      all: async () => ({ results: sqlite.prepare(sql).all(...values), success: true, meta: {} }),
      run: async () => {
        sqlite.prepare(sql).run(...values);
        return { results: [], success: true, meta: {} };
      },
    };
  };

  const db = {
    prepare: (sql: string) => statement(sql),
    batch: async (statements: Array<ReturnType<typeof statement>>) => {
      sqlite.exec('BEGIN');
      try {
        for (const s of statements) sqlite.prepare(s.sql).run(...(s.params as Array<string | number | null>));
        sqlite.exec('COMMIT');
      } catch (error) {
        sqlite.exec('ROLLBACK');
        throw error;
      }
      return [];
    },
    rawCount: (table: string) =>
      (sqlite.prepare(`SELECT COUNT(*) AS n FROM ${table}`).get() as { n: number }).n,
  };
  return db as unknown as D1Database;
}

export const rowCount = (db: D1Database, table: string): number =>
  (db as unknown as { rawCount: (t: string) => number }).rawCount(table);

export interface FakePlace {
  id: string;
  lat: number;
  lng: number;
  category?: string;
}

/** 중심 주변에 식당을 고르게(결정적으로) 흩뿌린다. */
export function scatterPlaces(lat: number, lng: number, count: number, spreadM: number): FakePlace[] {
  const places: FakePlace[] = [];
  let seed = 42;
  const random = () => {
    seed = (seed * 1103515245 + 12345) % 2 ** 31;
    return seed / 2 ** 31;
  };
  const dLat = spreadM / 111_320;
  const dLng = dLat / Math.cos((lat * Math.PI) / 180);
  for (let i = 0; i < count; i++) {
    places.push({
      id: String(1000 + i),
      lat: lat + (random() * 2 - 1) * dLat,
      lng: lng + (random() * 2 - 1) * dLng,
      category: i % 3 === 0 ? '음식점 > 한식 > 해장국' : '음식점 > 중식 > 중국요리',
    });
  }
  return places;
}

/**
 * 가짜 카카오 로컬 API. 카테고리 검색은 rect 안 식당을 15개씩, 최대 45개까지 준다.
 * calls에 부른 주소가 쌓인다.
 */
export function fakeKakao(places: FakePlace[], options: { failAfter?: number; status?: number } = {}) {
  const calls: string[] = [];
  const fetchFn: FetchLike = async (input, init) => {
    calls.push(input);
    const auth = new Headers(init?.headers).get('Authorization');
    if (auth !== 'KakaoAK test-key') return new Response('{}', { status: 401 });
    if (options.failAfter !== undefined && calls.length > options.failAfter) {
      return new Response('{}', { status: options.status ?? 500 });
    }
    const url = new URL(input);
    if (url.pathname.endsWith('/search/category.json')) {
      const [minLng, minLat, maxLng, maxLat] = url.searchParams.get('rect')!.split(',').map(Number) as [
        number,
        number,
        number,
        number,
      ];
      const page = Number(url.searchParams.get('page'));
      const size = Number(url.searchParams.get('size'));
      const inside = places.filter((p) => p.lat >= minLat && p.lat <= maxLat && p.lng >= minLng && p.lng <= maxLng);
      const pageable = inside.slice(0, 45);
      const documents = pageable.slice((page - 1) * size, page * size).map((p) => ({
        id: p.id,
        place_name: `식당${p.id}`,
        category_name: p.category ?? '음식점 > 한식',
        category_group_code: 'FD6',
        phone: '02-000-0000',
        address_name: '서울 성동구 성수동2가 1',
        road_address_name: '서울 성동구 성수이로 1',
        x: String(p.lng),
        y: String(p.lat),
        place_url: `http://place.map.kakao.com/${p.id}`,
        distance: '',
      }));
      return Response.json({
        meta: { total_count: inside.length, pageable_count: pageable.length, is_end: page * size >= pageable.length },
        documents,
      });
    }
    if (url.pathname.endsWith('/geo/coord2regioncode.json')) {
      return Response.json({
        meta: { total_count: 2 },
        documents: [
          {
            region_type: 'B',
            region_1depth_name: '서울특별시',
            region_2depth_name: '성동구',
            region_3depth_name: '성수동2가',
          },
          {
            region_type: 'H',
            region_1depth_name: '서울특별시',
            region_2depth_name: '성동구',
            region_3depth_name: '성수2가1동',
          },
        ],
      });
    }
    if (url.pathname.endsWith('/search/address.json')) {
      const query = url.searchParams.get('query')!;
      const documents = query.includes('성수이로')
        ? [{ address_name: '서울 성동구 성수동2가 289-10', x: '127.0559', y: '37.5446', road_address: { address_name: '서울 성동구 성수이로 1' } }]
        : [];
      return Response.json({ meta: { total_count: documents.length }, documents });
    }
    if (url.pathname.endsWith('/search/keyword.json')) {
      return Response.json({
        meta: { total_count: 1 },
        documents: [
          { place_name: '강남역 2호선', road_address_name: '서울 강남구 강남대로 396', address_name: '서울 강남구 역삼동 858', x: '127.0276', y: '37.4979' },
        ],
      });
    }
    return new Response('not found', { status: 404 });
  };
  return { fetchFn, calls };
}
