import type { Place } from './kakao';

/** 칸 하나의 캐시. leaf는 식당 목록, split은 아래 4칸으로 나눴다는 표시. */
export type CellRecord =
  | { kind: 'leaf'; places: Place[]; truncated: boolean }
  | { kind: 'split' };

export interface CellWrite {
  tile: string;
  path: string;
  record: CellRecord;
}

/** 칸 캐시 저장소. 한 요청에서 읽기 1번, 쓰기 1번(batch)만 하도록 묶어서 다룬다. */
export interface CellStore {
  /** tiles 아래의 아직 유효한 칸 전부. 키는 `${tile}/${path}`. */
  load(tiles: string[], nowMs: number): Promise<Map<string, CellRecord>>;
  save(writes: CellWrite[], expiresAtMs: number): Promise<void>;
}

export const cellKey = (tile: string, path: string) => `${tile}/${path}`;

/** Cloudflare D1 구현. 테이블은 migrations/0001_init.sql */
export class D1CellStore implements CellStore {
  constructor(private readonly db: D1Database) {}

  async load(tiles: string[], nowMs: number): Promise<Map<string, CellRecord>> {
    const result = new Map<string, CellRecord>();
    if (tiles.length === 0) return result;
    const marks = tiles.map(() => '?').join(',');
    const { results } = await this.db
      .prepare(
        `SELECT tile, path, kind, data, truncated FROM place_cells
         WHERE tile IN (${marks}) AND expires_at > ?`,
      )
      .bind(...tiles, nowMs)
      .all<{ tile: string; path: string; kind: string; data: string | null; truncated: number }>();
    for (const row of results) {
      const record: CellRecord =
        row.kind === 'split'
          ? { kind: 'split' }
          : { kind: 'leaf', places: JSON.parse(row.data ?? '[]') as Place[], truncated: row.truncated === 1 };
      result.set(cellKey(row.tile, row.path), record);
    }
    return result;
  }

  async save(writes: CellWrite[], expiresAtMs: number): Promise<void> {
    if (writes.length === 0) return;
    const statement = this.db.prepare(
      `INSERT OR REPLACE INTO place_cells (tile, path, kind, data, truncated, expires_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
    );
    await this.db.batch(
      writes.map(({ tile, path, record }) =>
        statement.bind(
          tile,
          path,
          record.kind,
          record.kind === 'leaf' ? JSON.stringify(record.places) : null,
          record.kind === 'leaf' && record.truncated ? 1 : 0,
          expiresAtMs,
        ),
      ),
    );
  }
}

/** 지난 캐시와 호출 제한 기록 지우기. 하루 한 번 cron 으로 부른다. */
export async function purgeExpired(db: D1Database, nowMs: number): Promise<void> {
  const currentWindow = Math.floor(nowMs / 60_000);
  await db.batch([
    db.prepare('DELETE FROM place_cells WHERE expires_at <= ?').bind(nowMs),
    db.prepare('DELETE FROM rate_limits WHERE window < ?').bind(currentWindow - 1),
  ]);
}
