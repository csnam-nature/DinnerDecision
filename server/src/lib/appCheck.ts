import { ApiError } from '../http';
import type { FetchLike } from './kakao';

/**
 * Firebase App Check 토큰 검증.
 * https://firebase.google.com/docs/app-check/custom-resource-backend
 *
 * 앱이 보낸 X-Firebase-AppCheck 헤더의 JWT를 Google 공개키(JWKS)로 확인한다.
 * - 서명: RS256
 * - iss: https://firebaseappcheck.googleapis.com/<프로젝트 번호>
 * - aud: projects/<프로젝트 번호> 포함
 * - exp: 지나지 않음
 */
export const APP_CHECK_JWKS_URL = 'https://firebaseappcheck.googleapis.com/v1/jwks';
const JWKS_TTL_MS = 6 * 60 * 60 * 1000;
const CLOCK_SKEW_S = 60;

interface Jwk extends JsonWebKey {
  kid: string;
}

/** 같은 Worker 인스턴스 안에서는 공개키를 다시 받지 않는다. */
let jwksCache: { keys: Jwk[]; fetchedAt: number } | null = null;

export function resetJwksCacheForTest() {
  jwksCache = null;
}

export interface AppCheckConfig {
  projectNumber: string;
  /** 비어 있으면 같은 프로젝트의 앱은 모두 허용. */
  appIds: string[];
  nowMs: number;
  fetchFn?: FetchLike;
}

/** 검증에 성공하면 앱 ID(sub)를 돌려주고, 실패하면 ApiError(401). */
export async function verifyAppCheckToken(token: string, config: AppCheckConfig): Promise<string> {
  const parts = token.split('.');
  if (parts.length !== 3) throw invalid('토큰 형식이 아닙니다');
  const [headerPart, payloadPart, signaturePart] = parts as [string, string, string];

  const header = decodeJson(headerPart) as { alg?: string; typ?: string; kid?: string };
  if (header.alg !== 'RS256' || header.typ !== 'JWT' || !header.kid) throw invalid('토큰 헤더가 올바르지 않습니다');

  const jwk = await findKey(header.kid, config);
  const key = await crypto.subtle.importKey(
    'jwk',
    { kty: jwk.kty, n: jwk.n, e: jwk.e, alg: 'RS256', ext: true },
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const ok = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    base64UrlDecode(signaturePart),
    new TextEncoder().encode(`${headerPart}.${payloadPart}`),
  );
  if (!ok) throw invalid('서명이 맞지 않습니다');

  const payload = decodeJson(payloadPart) as { iss?: string; aud?: string[] | string; exp?: number; sub?: string };
  const nowS = Math.floor(config.nowMs / 1000);
  if (payload.iss !== `https://firebaseappcheck.googleapis.com/${config.projectNumber}`) {
    throw invalid('발급자가 다릅니다');
  }
  const audiences = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
  if (!audiences.includes(`projects/${config.projectNumber}`)) throw invalid('대상 프로젝트가 다릅니다');
  if (typeof payload.exp !== 'number' || payload.exp + CLOCK_SKEW_S < nowS) throw invalid('만료된 토큰입니다');
  if (!payload.sub) throw invalid('앱 ID가 없습니다');
  if (config.appIds.length > 0 && !config.appIds.includes(payload.sub)) throw invalid('등록되지 않은 앱입니다');
  return payload.sub;
}

async function findKey(kid: string, config: AppCheckConfig): Promise<Jwk> {
  const fresh = jwksCache && config.nowMs - jwksCache.fetchedAt < JWKS_TTL_MS;
  let key = fresh ? jwksCache!.keys.find((k) => k.kid === kid) : undefined;
  if (!key) {
    // 키가 바뀌었을 수 있으니 한 번 새로 받는다.
    const fetchFn = config.fetchFn ?? ((input, init) => fetch(input, init));
    const response = await fetchFn(APP_CHECK_JWKS_URL);
    if (!response.ok) throw new ApiError(503, 'APP_CHECK_UNAVAILABLE', 'App Check 공개키를 받지 못했습니다');
    const body = (await response.json()) as { keys: Jwk[] };
    jwksCache = { keys: body.keys, fetchedAt: config.nowMs };
    key = body.keys.find((k) => k.kid === kid);
  }
  if (!key) throw invalid('알 수 없는 키입니다');
  return key;
}

function invalid(reason: string) {
  return new ApiError(401, 'APP_CHECK_FAILED', `앱 인증 실패: ${reason}`);
}

function decodeJson(part: string): unknown {
  try {
    return JSON.parse(new TextDecoder().decode(base64UrlDecode(part)));
  } catch {
    throw invalid('토큰을 읽을 수 없습니다');
  }
}

export function base64UrlDecode(input: string): Uint8Array<ArrayBuffer> {
  const base64 = input.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(input.length / 4) * 4, '=');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
