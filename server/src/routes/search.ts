import type { Env } from '../env';
import { ApiError, json } from '../http';
import { KakaoClient, type FetchLike } from '../lib/kakao';

/**
 * GET /search?query=강남역
 * → { results: [{ name, detail, lat, lng }] }
 * 위치 권한을 주지 않았거나 다른 곳을 보고 싶을 때 쓰는 위치 직접 설정 (F-01).
 * 검색어는 로그에 남기지 않는다.
 */
export async function handleSearch(url: URL, env: Env, fetchFn?: FetchLike): Promise<Response> {
  const query = (url.searchParams.get('query') ?? '').trim();
  if (query.length < 2 || query.length > 60) {
    throw new ApiError(400, 'BAD_REQUEST', '검색어는 2~60자로 입력해 주세요');
  }
  const results = await new KakaoClient(env.KAKAO_REST_KEY, fetchFn).searchLocation(query, 10);
  return json({ results });
}
