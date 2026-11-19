import type { Env } from '../env';
import { json, koreanCoordinate } from '../http';
import type { FetchLike } from '../lib/kakao';
import { KmaClient, type CurrentWeather } from '../lib/kma';
import { toKmaGrid } from '../lib/kmaGrid';

/** 기상청 초단기 자료는 매시 갱신된다. 같은 격자는 20분 동안 다시 부르지 않는다. */
export const WEATHER_TTL_MS = 20 * 60 * 1000;

export interface WeatherResponse extends CurrentWeather {
  /** 미세먼지(에어코리아)는 아직 붙이지 않았다. */
  dust: null;
  attribution: string;
}

/**
 * GET /weather?lat=37.5446&lng=127.0559
 * → { tempC, precipitation, sky, rain1hMm, humidity, observedAt, dust, attribution }
 */
export async function handleWeather(url: URL, env: Env, nowMs: number, fetchFn?: FetchLike): Promise<Response> {
  const { lat, lng } = koreanCoordinate(url);
  const grid = toKmaGrid(lat, lng);
  const key = `${grid.nx},${grid.ny}`;

  const cached = await env.DB.prepare('SELECT data FROM weather_cells WHERE grid = ? AND expires_at > ?')
    .bind(key, nowMs)
    .first<{ data: string }>();
  if (cached) return json(JSON.parse(cached.data));

  const weather = await new KmaClient(env.KMA_SERVICE_KEY ?? '', fetchFn).current(grid, nowMs);
  const body: WeatherResponse = { ...weather, dust: null, attribution: '날씨: 기상청' };
  await env.DB.prepare('INSERT OR REPLACE INTO weather_cells (grid, data, expires_at) VALUES (?, ?, ?)')
    .bind(key, JSON.stringify(body), nowMs + WEATHER_TTL_MS)
    .run();
  return json(body);
}
