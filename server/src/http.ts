/** 앱이 오류 종류를 구분할 수 있도록 code를 함께 보낸다. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export function json(body: unknown, status = 200, headers: HeadersInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      ...headers,
    },
  });
}

export function errorResponse(error: ApiError): Response {
  return json({ error: { code: error.code, message: error.message } }, error.status);
}

/** 쿼리의 숫자 값. 없거나 숫자가 아니면 400. */
export function numberParam(url: URL, name: string): number {
  const raw = url.searchParams.get(name);
  const value = raw === null || raw.trim() === '' ? Number.NaN : Number(raw);
  if (!Number.isFinite(value)) {
    throw new ApiError(400, 'BAD_REQUEST', `${name} 값이 필요합니다`);
  }
  return value;
}

/** 카카오 로컬은 국내만 지원하므로 대한민국 근처 좌표만 받는다. */
export function koreanCoordinate(url: URL): { lat: number; lng: number } {
  const lat = numberParam(url, 'lat');
  const lng = numberParam(url, 'lng');
  if (lat < 32 || lat > 39.5 || lng < 123 || lng > 132.5) {
    throw new ApiError(400, 'OUT_OF_SERVICE_AREA', '국내 좌표만 지원합니다');
  }
  return { lat, lng };
}
