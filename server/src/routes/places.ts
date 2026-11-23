import { intVar, type Env } from '../env';
import { ApiError, json, koreanCoordinate } from '../http';
import { D1CellStore } from '../lib/cellStore';
import { KakaoClient, type FetchLike } from '../lib/kakao';
import { searchNearby } from '../lib/placeSearch';

export const MIN_RADIUS_M = 100;
/**
 * 설정 화면에서 고를 수 있는 가장 넓은 반경(2km) + 여유 100m.
 * 앱은 위경도를 약 100m 단위로 줄여 보내므로, 반경 끝 식당이 빠지지 않게 조금 넓게 요청한다.
 */
export const MAX_RADIUS_M = 2100;
export const DEFAULT_CALL_BUDGET = 40;

/**
 * GET /places?lat=37.5446&lng=127.0559&radius=1000
 * → { places: [...], complete, truncated, attribution }
 */
export async function handlePlaces(url: URL, env: Env, nowMs: number, fetchFn?: FetchLike): Promise<Response> {
  const { lat, lng } = koreanCoordinate(url);
  const radiusM = Math.round(Number(url.searchParams.get('radius') ?? MAX_RADIUS_M));
  if (!Number.isFinite(radiusM) || radiusM < MIN_RADIUS_M || radiusM > MAX_RADIUS_M) {
    throw new ApiError(400, 'BAD_REQUEST', `radius는 ${MIN_RADIUS_M}~${MAX_RADIUS_M} 사이여야 합니다`);
  }
  const result = await searchNearby(new KakaoClient(env.KAKAO_REST_KEY, fetchFn), new D1CellStore(env.DB), {
    lat,
    lng,
    radiusM,
    budget: Math.min(intVar(env.KAKAO_CALL_BUDGET, DEFAULT_CALL_BUDGET), 45),
    nowMs,
  });
  console.log(
    JSON.stringify({
      route: 'places',
      count: result.places.length,
      complete: result.complete,
      kakaoCalls: result.kakaoCalls,
      cachedCells: result.cachedCells,
    }),
  );
  return json({
    places: result.places,
    complete: result.complete,
    truncated: result.truncated,
    attribution: '장소 정보: 카카오',
  });
}
