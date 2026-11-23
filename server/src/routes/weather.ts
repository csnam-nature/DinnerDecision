import type { Env } from '../env';
import { json, koreanCoordinate } from '../http';
import { AirKoreaClient, type DustLevel, type DustReading } from '../lib/airkorea';
import { KakaoClient, type FetchLike } from '../lib/kakao';
import { KmaClient, type CurrentWeather } from '../lib/kma';
import { toKmaGrid } from '../lib/kmaGrid';

/** 기상청 초단기 자료와 에어코리아 실시간 자료는 매시 갱신된다. 같은 격자는 20분 동안 다시 부르지 않는다. */
export const WEATHER_TTL_MS = 20 * 60 * 1000;
/** 격자 → 가까운 측정소. 측정소는 거의 바뀌지 않는다. */
export const STATION_TTL_MS = 30 * 24 * 60 * 60 * 1000;
/** 미세먼지는 이 시간 안에 못 받으면 '모름'으로 두고 날씨만 준다 (앱은 15초에 포기한다). */
export const DUST_BUDGET_MS = 6000;

export interface WeatherResponse extends CurrentWeather {
  /** 미세먼지 등급 (PM10·PM2.5 중 나쁜 쪽). 못 받으면 null. */
  dust: DustLevel | null;
  dustDetail: Omit<DustReading, 'level'> | null;
  attribution: string;
}

/**
 * GET /weather?lat=37.545&lng=127.056
 * → { tempC, precipitation, sky, rain1hMm, humidity, observedAt, dust, dustDetail, attribution }
 */
export async function handleWeather(url: URL, env: Env, nowMs: number, fetchFn?: FetchLike): Promise<Response> {
  const { lat, lng } = koreanCoordinate(url);
  const grid = toKmaGrid(lat, lng);
  const key = `${grid.nx},${grid.ny}`;

  const cached = await env.DB.prepare('SELECT data FROM weather_cells WHERE grid = ? AND expires_at > ?')
    .bind(key, nowMs)
    .first<{ data: string }>();
  if (cached) return json(JSON.parse(cached.data));

  // 날씨와 미세먼지를 같이 받는다. 미세먼지가 실패해도 날씨는 준다.
  const [weather, dust] = await Promise.all([
    new KmaClient(env.KMA_SERVICE_KEY ?? '', fetchFn, env.KMA_BASE_URL || undefined).current(grid, nowMs),
    withinBudget(currentDust(env, key, lat, lng, nowMs, fetchFn), DUST_BUDGET_MS),
  ]);
  const body: WeatherResponse = {
    ...weather,
    dust: dust?.level ?? null,
    dustDetail: dust
      ? {
          pm10: dust.pm10,
          pm10Level: dust.pm10Level,
          pm25: dust.pm25,
          pm25Level: dust.pm25Level,
          station: dust.station,
          measuredAt: dust.measuredAt,
        }
      : null,
    // 에어코리아 자료는 실시간 관측값이라 검증 전 값일 수 있다 (출처 표시 필요).
    attribution: dust ? '날씨: 기상청 · 미세먼지: 에어코리아(한국환경공단, 실시간 미확정 자료)' : '날씨: 기상청',
  };
  await env.DB.prepare('INSERT OR REPLACE INTO weather_cells (grid, data, expires_at) VALUES (?, ?, ?)')
    .bind(key, JSON.stringify(body), nowMs + WEATHER_TTL_MS)
    .run();
  return json(body);
}

/** 격자에서 가장 가까운 측정소의 지금 미세먼지. 키가 없거나 실패하면 null. */
async function currentDust(
  env: Env,
  gridKey: string,
  lat: number,
  lng: number,
  nowMs: number,
  fetchFn?: FetchLike,
): Promise<DustReading | null> {
  // 공공데이터포털 키는 계정에 하나라 기상청 키를 같이 쓴다 (서비스마다 활용신청은 따로).
  const serviceKey = env.AIRKOREA_SERVICE_KEY || env.KMA_SERVICE_KEY;
  if (!serviceKey) return null;
  const air = new AirKoreaClient(serviceKey, fetchFn);

  let station = (
    await env.DB.prepare('SELECT station FROM air_stations WHERE grid = ? AND expires_at > ?')
      .bind(gridKey, nowMs)
      .first<{ station: string }>()
  )?.station;
  if (!station) {
    const tm = await new KakaoClient(env.KAKAO_REST_KEY, fetchFn).toTm(lat, lng);
    if (!tm) return null;
    station = (await air.nearestStation(tm)) ?? undefined;
    if (!station) return null;
    await env.DB.prepare('INSERT OR REPLACE INTO air_stations (grid, station, expires_at) VALUES (?, ?, ?)')
      .bind(gridKey, station, nowMs + STATION_TTL_MS)
      .run();
  }
  return air.reading(station);
}

/** [ms] 안에 끝나지 않거나 실패하면 null. */
async function withinBudget<T>(work: Promise<T | null>, ms: number): Promise<T | null> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<null>((resolve) => {
    timer = setTimeout(() => {
      console.warn(JSON.stringify({ dust: 'timeout', ms }));
      resolve(null);
    }, ms);
  });
  try {
    return await Promise.race([
      work.catch((error) => {
        console.warn(JSON.stringify({ dust: 'failed', error: String(error) }));
        return null;
      }),
      timeout,
    ]);
  } finally {
    clearTimeout(timer);
  }
}
