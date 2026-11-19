import { intVar, type Env } from './env';
import { ApiError, errorResponse, json } from './http';
import { verifyAppCheckToken } from './lib/appCheck';
import type { FetchLike } from './lib/kakao';
import { checkRateLimit } from './lib/rateLimit';
import { handlePlaces } from './routes/places';
import { handleRegion } from './routes/region';
import { handleSearch } from './routes/search';
import { handleWeather } from './routes/weather';

export const API_VERSION = '1';

/** 테스트에서 시각과 외부 호출을 바꿔 끼울 수 있게 따로 둔다. */
export interface Deps {
  nowMs: () => number;
  fetchFn?: FetchLike;
}

export async function handleRequest(request: Request, env: Env, deps: Deps): Promise<Response> {
  const url = new URL(request.url);
  try {
    if (request.method !== 'GET') throw new ApiError(405, 'METHOD_NOT_ALLOWED', 'GET만 지원합니다');
    if (url.pathname === '/health') return json({ ok: true, version: API_VERSION });

    const nowMs = deps.nowMs();
    await checkAppCheck(request, env, nowMs, deps.fetchFn);
    await checkRateLimit(env.DB, request.headers.get('CF-Connecting-IP') ?? 'unknown', {
      limitPerMinute: intVar(env.RATE_LIMIT_PER_MINUTE, 30),
      salt: env.RATE_LIMIT_SALT ?? 'dinner-api',
      nowMs,
    });

    switch (url.pathname) {
      case '/places':
        return await handlePlaces(url, env, nowMs, deps.fetchFn);
      case '/region':
        return await handleRegion(url, env, deps.fetchFn);
      case '/search':
        return await handleSearch(url, env, deps.fetchFn);
      case '/weather':
        return await handleWeather(url, env, nowMs, deps.fetchFn);
      default:
        throw new ApiError(404, 'NOT_FOUND', '없는 주소입니다');
    }
  } catch (error) {
    if (error instanceof ApiError) return errorResponse(error);
    // 좌표가 로그에 남지 않도록 경로만 남긴다.
    console.error(JSON.stringify({ route: url.pathname, error: String(error) }));
    return errorResponse(new ApiError(500, 'INTERNAL', '서버 오류가 발생했습니다'));
  }
}

async function checkAppCheck(request: Request, env: Env, nowMs: number, fetchFn?: FetchLike) {
  const mode = env.APP_CHECK_MODE ?? 'off';
  if (mode === 'off') return;
  if (!env.FIREBASE_PROJECT_NUMBER) {
    throw new ApiError(500, 'SERVER_NOT_CONFIGURED', 'FIREBASE_PROJECT_NUMBER가 설정되지 않았습니다');
  }
  try {
    const token = request.headers.get('X-Firebase-AppCheck');
    if (!token) throw new ApiError(401, 'APP_CHECK_FAILED', '앱 인증 토큰이 없습니다');
    await verifyAppCheckToken(token, {
      projectNumber: env.FIREBASE_PROJECT_NUMBER,
      appIds: (env.FIREBASE_APP_IDS ?? '')
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s),
      nowMs,
      fetchFn,
    });
  } catch (error) {
    if (mode === 'enforce') throw error;
    console.warn(JSON.stringify({ appCheck: 'failed', mode, error: String(error) }));
  }
}
