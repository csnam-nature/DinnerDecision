import type { Env } from '../env';
import { ApiError, json, koreanCoordinate } from '../http';
import { KakaoClient, type FetchLike } from '../lib/kakao';

/**
 * GET /region?lat=37.5446&lng=127.0559
 * → { name: "성수동2가", detail: "서울특별시 성동구 성수동2가", adminName: "성수2가1동" }
 * 좌표를 저장하지 않으려고 캐시하지 않는다. 앱이 위치가 바뀔 때만 부른다.
 */
export async function handleRegion(url: URL, env: Env, fetchFn?: FetchLike): Promise<Response> {
  const { lat, lng } = koreanCoordinate(url);
  const region = await new KakaoClient(env.KAKAO_REST_KEY, fetchFn).region(lat, lng);
  if (!region) throw new ApiError(404, 'REGION_NOT_FOUND', '이 위치의 동 이름을 찾지 못했습니다');
  return json(region);
}
