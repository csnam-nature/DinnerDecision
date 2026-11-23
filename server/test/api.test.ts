import { afterEach, describe, expect, it } from 'vitest';
import type { Env } from '../src/env';
import { handleRequest } from '../src/app';
import { APP_CHECK_JWKS_URL, resetJwksCacheForTest } from '../src/lib/appCheck';
import type { FetchLike } from '../src/lib/kakao';
import { createTestD1, fakeKakao, scatterPlaces } from './support';

const now = Date.UTC(2026, 10, 19, 9);

function makeEnv(overrides: Partial<Env> = {}): Env {
  return { DB: createTestD1(), KAKAO_REST_KEY: 'test-key', ...overrides };
}

async function call(path: string, env: Env, fetchFn: FetchLike, headers: HeadersInit = {}) {
  const response = await handleRequest(
    new Request(`https://dinner-api.example${path}`, { headers: { 'CF-Connecting-IP': '203.0.113.7', ...headers } }),
    env,
    { nowMs: () => now, fetchFn },
  );
  return { status: response.status, body: (await response.json()) as any };
}

const kakao = () => fakeKakao(scatterPlaces(37.5446, 127.0559, 30, 1500));

describe('API', () => {
  afterEach(() => resetJwksCacheForTest());

  it('/health', async () => {
    const { status, body } = await call('/health', makeEnv(), kakao().fetchFn);
    expect(status).toBe(200);
    expect(body.ok).toBe(true);
  });

  it('/privacy 는 앱 인증 없이 열리는 개인정보처리방침 페이지', async () => {
    const env = makeEnv({ APP_CHECK_MODE: 'enforce', FIREBASE_PROJECT_NUMBER: '1' });
    const response = await handleRequest(new Request('https://x/privacy'), env, { nowMs: () => now });
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain('text/html');
    const html = await response.text();
    expect(html).toContain('개인정보처리방침');
    expect(html).toContain('저장하거나 기록하지 않습니다');
    expect(html).toContain('naturetec');
    expect(html).not.toContain('[운영자');
  });

  it('/places 는 식당 목록과 출처를 준다', async () => {
    const { status, body } = await call('/places?lat=37.5446&lng=127.0559&radius=1000', makeEnv(), kakao().fetchFn);
    expect(status).toBe(200);
    expect(body.complete).toBe(true);
    expect(body.attribution).toContain('카카오');
    expect(body.places[0]).toEqual({
      id: expect.any(String),
      name: expect.any(String),
      category: expect.any(String),
      phone: expect.any(String),
      address: expect.any(String),
      roadAddress: expect.any(String),
      lat: expect.any(Number),
      lng: expect.any(Number),
      url: expect.any(String),
      distanceM: expect.any(Number),
    });
  });

  it('잘못된 좌표·반경은 400', async () => {
    const env = makeEnv();
    const fetchFn = kakao().fetchFn;
    expect((await call('/places?lat=abc&lng=127', env, fetchFn)).body.error.code).toBe('BAD_REQUEST');
    expect((await call('/places?lat=35.6&lng=139.7', env, fetchFn)).body.error.code).toBe('OUT_OF_SERVICE_AREA');
    expect((await call('/places?lat=37.5&lng=127&radius=3000', env, fetchFn)).status).toBe(400);
  });

  it('/region 은 동 이름을 준다', async () => {
    const { status, body } = await call('/region?lat=37.5446&lng=127.0559', makeEnv(), kakao().fetchFn);
    expect(status).toBe(200);
    expect(body).toEqual({ name: '성수동2가', detail: '서울특별시 성동구 성수동2가', adminName: '성수2가1동' });
  });

  it('/search 는 주소 결과를 먼저, 그다음 장소를 준다', async () => {
    const { status, body } = await call(`/search?query=${encodeURIComponent('성수이로 1')}`, makeEnv(), kakao().fetchFn);
    expect(status).toBe(200);
    expect(body.results).toEqual([
      { name: '서울 성동구 성수동2가 289-10', detail: '서울 성동구 성수이로 1', lat: 37.5446, lng: 127.0559 },
      { name: '강남역 2호선', detail: '서울 강남구 강남대로 396', lat: 37.4979, lng: 127.0276 },
    ]);
    expect((await call('/search?query=a', makeEnv(), kakao().fetchFn)).status).toBe(400);
  });

  it('카카오 키가 틀리면 502 UPSTREAM_AUTH', async () => {
    const { status, body } = await call('/region?lat=37.5&lng=127', makeEnv({ KAKAO_REST_KEY: 'wrong' }), kakao().fetchFn);
    expect(status).toBe(502);
    expect(body.error.code).toBe('UPSTREAM_AUTH');
  });

  it('없는 주소는 404, GET 외는 405', async () => {
    expect((await call('/nope', makeEnv(), kakao().fetchFn)).status).toBe(404);
    const response = await handleRequest(new Request('https://x/places', { method: 'POST' }), makeEnv(), {
      nowMs: () => now,
    });
    expect(response.status).toBe(405);
  });

  it('같은 IP가 1분에 너무 많이 부르면 429', async () => {
    const env = makeEnv({ RATE_LIMIT_PER_MINUTE: '3' });
    const fetchFn = kakao().fetchFn;
    const statuses: number[] = [];
    for (let i = 0; i < 4; i++) statuses.push((await call('/region?lat=37.5&lng=127', env, fetchFn)).status);
    expect(statuses).toEqual([200, 200, 200, 429]);
    // 다른 IP는 괜찮다.
    const other = await call('/region?lat=37.5&lng=127', env, fetchFn, { 'CF-Connecting-IP': '198.51.100.1' });
    expect(other.status).toBe(200);
  });

  describe('App Check', () => {
    const projectNumber = '123456789';

    async function keyPair() {
      const pair = (await crypto.subtle.generateKey(
        { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
        true,
        ['sign', 'verify'],
      )) as CryptoKeyPair;
      const jwk = (await crypto.subtle.exportKey('jwk', pair.publicKey)) as JsonWebKey;
      return { pair, jwk: { ...jwk, kid: 'key-1', use: 'sig', alg: 'RS256' } };
    }

    const b64url = (data: Uint8Array | string) =>
      Buffer.from(typeof data === 'string' ? new TextEncoder().encode(data) : data).toString('base64url');

    async function sign(privateKey: CryptoKey, payload: object, kid = 'key-1') {
      const head = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT', kid }));
      const body = b64url(JSON.stringify(payload));
      const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(`${head}.${body}`));
      return `${head}.${body}.${b64url(new Uint8Array(signature))}`;
    }

    const validPayload = () => ({
      iss: `https://firebaseappcheck.googleapis.com/${projectNumber}`,
      aud: [`projects/${projectNumber}`, 'projects/dinner-decision'],
      sub: '1:123456789:android:abc',
      exp: Math.floor(now / 1000) + 3600,
      iat: Math.floor(now / 1000),
    });

    async function setupAppCheck() {
      const { pair, jwk } = await keyPair();
      const base = kakao();
      const fetchFn: FetchLike = async (input, init) =>
        input === APP_CHECK_JWKS_URL ? Response.json({ keys: [jwk] }) : base.fetchFn(input, init);
      const env = makeEnv({ APP_CHECK_MODE: 'enforce', FIREBASE_PROJECT_NUMBER: projectNumber });
      return { pair, fetchFn, env };
    }

    it('올바른 토큰은 통과한다', async () => {
      const { pair, fetchFn, env } = await setupAppCheck();
      const token = await sign(pair.privateKey, validPayload());
      const { status } = await call('/region?lat=37.5&lng=127', env, fetchFn, { 'X-Firebase-AppCheck': token });
      expect(status).toBe(200);
    });

    it('토큰이 없거나, 만료됐거나, 다른 프로젝트거나, 서명이 틀리면 401', async () => {
      const { pair, fetchFn, env } = await setupAppCheck();
      const other = await keyPair();
      const tokens = [
        undefined,
        'not-a-jwt',
        await sign(pair.privateKey, { ...validPayload(), exp: Math.floor(now / 1000) - 3600 }),
        await sign(pair.privateKey, { ...validPayload(), aud: ['projects/999'] }),
        await sign(pair.privateKey, { ...validPayload(), iss: 'https://evil.example/123456789' }),
        await sign(other.pair.privateKey, validPayload()),
        await sign(pair.privateKey, validPayload(), 'unknown-kid'),
      ];
      for (const token of tokens) {
        const headers: Record<string, string> = token ? { 'X-Firebase-AppCheck': token } : {};
        const { status, body } = await call('/region?lat=37.5&lng=127', env, fetchFn, headers);
        expect(status, String(token)).toBe(401);
        expect(body.error.code).toBe('APP_CHECK_FAILED');
      }
    });

    it('monitor 모드에서는 실패해도 통과시킨다', async () => {
      const { fetchFn, env } = await setupAppCheck();
      const { status } = await call('/region?lat=37.5&lng=127', { ...env, APP_CHECK_MODE: 'monitor' }, fetchFn);
      expect(status).toBe(200);
    });

    it('허용한 앱 ID가 아니면 401', async () => {
      const { pair, fetchFn, env } = await setupAppCheck();
      const token = await sign(pair.privateKey, validPayload());
      const { status } = await call(
        '/region?lat=37.5&lng=127',
        { ...env, FIREBASE_APP_IDS: '1:123456789:ios:zzz' },
        fetchFn,
        { 'X-Firebase-AppCheck': token },
      );
      expect(status).toBe(401);
    });
  });
});
