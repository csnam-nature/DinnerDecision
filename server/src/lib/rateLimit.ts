import { ApiError } from '../http';

/**
 * IP별 1분 호출 제한. IP는 소금값과 함께 해시해서 앞 16자리만 저장한다.
 * D1에 한 번만 쓰고(UPSERT … RETURNING) 그 결과로 판단한다.
 */
export async function checkRateLimit(
  db: D1Database,
  ip: string,
  options: { limitPerMinute: number; salt: string; nowMs: number },
): Promise<void> {
  const window = Math.floor(options.nowMs / 60_000);
  const key = await hashIp(ip, options.salt);
  const row = await db
    .prepare(
      `INSERT INTO rate_limits (key, window, count) VALUES (?, ?, 1)
       ON CONFLICT (key, window) DO UPDATE SET count = count + 1
       RETURNING count`,
    )
    .bind(key, window)
    .first<{ count: number }>();
  if ((row?.count ?? 0) > options.limitPerMinute) {
    throw new ApiError(429, 'RATE_LIMITED', '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요');
  }
}

export async function hashIp(ip: string, salt: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(`${salt}:${ip}`));
  return [...new Uint8Array(digest).slice(0, 8)].map((b) => b.toString(16).padStart(2, '0')).join('');
}
