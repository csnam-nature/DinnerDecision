import { describe, expect, it } from 'vitest';
import type { Env } from '../src/env';
import { handleRequest } from '../src/app';
import { baseTime, precipitationOf } from '../src/lib/kma';
import type { FetchLike } from '../src/lib/kakao';
import { toKmaGrid } from '../src/lib/kmaGrid';
import { createTestD1 } from './support';

/** 한국 시간으로 시각을 만든다. */
const kst = (y: number, mo: number, d: number, h: number, mi: number) => Date.UTC(y, mo - 1, d, h - 9, mi);

describe('기상청 격자', () => {
  it('알려진 지점을 기상청 격자로 바꾼다', () => {
    expect(toKmaGrid(37.5665, 126.978)).toEqual({ nx: 60, ny: 127 }); // 서울시청
    expect(toKmaGrid(35.1798, 129.075)).toEqual({ nx: 98, ny: 76 }); // 부산시청
  });
});

describe('발표 시각', () => {
  it('초단기실황은 정각 자료가 40분 뒤에 나온다', () => {
    expect(baseTime(kst(2026, 11, 19, 18, 39), 0, 40)).toEqual({ date: '20261119', time: '1700' });
    expect(baseTime(kst(2026, 11, 19, 18, 41), 0, 40)).toEqual({ date: '20261119', time: '1800' });
    expect(baseTime(kst(2026, 11, 19, 18, 41), 0, 40, 1)).toEqual({ date: '20261119', time: '1700' });
  });

  it('초단기예보는 30분 자료가 45분 뒤에 나온다', () => {
    expect(baseTime(kst(2026, 11, 19, 18, 14), 30, 45)).toEqual({ date: '20261119', time: '1630' });
    expect(baseTime(kst(2026, 11, 19, 18, 16), 30, 45)).toEqual({ date: '20261119', time: '1730' });
  });

  it('자정 직후에는 전날 자료를 쓴다', () => {
    expect(baseTime(kst(2026, 11, 20, 0, 10), 0, 40)).toEqual({ date: '20261119', time: '2300' });
  });

  it('강수 형태 코드를 바꾼다', () => {
    expect([0, 1, 2, 3, 5, 6, 7].map(precipitationOf)).toEqual(['none', 'rain', 'rain', 'snow', 'rain', 'rain', 'snow']);
  });
});

const now = kst(2026, 11, 19, 18, 50);

function kmaJson(items: object[], resultCode = '00') {
  return JSON.stringify({
    response: { header: { resultCode, resultMsg: 'NORMAL_SERVICE' }, body: { items: { item: items } } },
  });
}

/** 가짜 기상청. noDataFor에 든 발표 시각은 '자료 없음(03)'으로 답한다. */
function fakeKma(options: { noDataFor?: string[]; keyError?: boolean; fcstFails?: boolean } = {}) {
  const calls: string[] = [];
  const fetchFn: FetchLike = async (input) => {
    calls.push(input);
    const url = new URL(input);
    if (options.keyError) {
      return new Response(
        '<OpenAPI_ServiceResponse><cmmMsgHeader><returnAuthMsg>SERVICE_KEY_IS_NOT_REGISTERED_ERROR</returnAuthMsg></cmmMsgHeader></OpenAPI_ServiceResponse>',
        { status: 200 },
      );
    }
    const time = url.searchParams.get('base_time')!;
    if (options.noDataFor?.includes(time)) return new Response(kmaJson([], '03'));
    if (url.pathname.endsWith('getUltraSrtNcst')) {
      return new Response(
        kmaJson([
          { category: 'T1H', obsrValue: '8.7' },
          { category: 'PTY', obsrValue: '1' },
          { category: 'RN1', obsrValue: '1.5' },
          { category: 'REH', obsrValue: '90' },
        ]),
      );
    }
    if (options.fcstFails) return new Response('oops', { status: 500 });
    return new Response(
      kmaJson([
        { category: 'SKY', fcstDate: '20261119', fcstTime: '2000', fcstValue: '1' },
        { category: 'SKY', fcstDate: '20261119', fcstTime: '1900', fcstValue: '4' },
        { category: 'T1H', fcstDate: '20261119', fcstTime: '1900', fcstValue: '8' },
      ]),
    );
  };
  return { fetchFn, calls };
}

const env = (overrides: Partial<Env> = {}): Env => ({
  DB: createTestD1(),
  KAKAO_REST_KEY: 'test-key',
  KMA_SERVICE_KEY: 'abc+def/ghi==',
  ...overrides,
});

async function weather(e: Env, fetchFn: FetchLike, nowMs = now, path = '/weather?lat=37.5665&lng=126.978') {
  const response = await handleRequest(new Request(`https://x${path}`, { headers: { 'CF-Connecting-IP': '203.0.113.9' } }), e, {
    nowMs: () => nowMs,
    fetchFn,
  });
  return { status: response.status, body: (await response.json()) as any };
}

describe('/weather', () => {
  it('지금 기온·강수와 가장 가까운 하늘 상태를 준다', async () => {
    const kma = fakeKma();
    const { status, body } = await weather(env(), kma.fetchFn);
    expect(status).toBe(200);
    expect(body).toEqual({
      tempC: 8.7,
      precipitation: 'rain',
      sky: 'cloudy',
      rain1hMm: 1.5,
      humidity: 90,
      observedAt: '2026-11-19T18:00+09:00',
      dust: null,
      attribution: '날씨: 기상청',
    });
    const ncst = new URL(kma.calls.find((c) => c.includes('Ncst'))!);
    expect(ncst.searchParams.get('nx')).toBe('60');
    expect(ncst.searchParams.get('ny')).toBe('127');
    expect(ncst.searchParams.get('base_time')).toBe('1800');
    // Decoding 키는 한 번만 인코딩해서 보낸다.
    expect(kma.calls[0]).toContain('serviceKey=abc%2Bdef%2Fghi%3D%3D&');
  });

  it('같은 격자는 20분 동안 기상청을 다시 부르지 않는다', async () => {
    const e = env();
    const kma = fakeKma();
    await weather(e, kma.fetchFn);
    // 같은 격자 안의 조금 떨어진 곳
    await weather(e, kma.fetchFn, now + 60_000, '/weather?lat=37.567&lng=126.979');
    expect(kma.calls).toHaveLength(2);
    await weather(e, kma.fetchFn, now + 21 * 60_000);
    expect(kma.calls).toHaveLength(4);
  });

  it('발표 직후 자료가 없으면 한 시간 전 자료를 쓴다', async () => {
    const kma = fakeKma({ noDataFor: ['1800'] });
    const { status, body } = await weather(env(), kma.fetchFn);
    expect(status).toBe(200);
    expect(body.observedAt).toBe('2026-11-19T17:00+09:00');
  });

  it('하늘 상태를 못 받아도 기온·강수는 준다', async () => {
    const { status, body } = await weather(env(), fakeKma({ fcstFails: true }).fetchFn);
    expect(status).toBe(200);
    expect(body.sky).toBeNull();
    expect(body.tempC).toBe(8.7);
  });

  it('키 오류는 UPSTREAM_AUTH, 키가 없으면 SERVER_NOT_CONFIGURED', async () => {
    const bad = await weather(env(), fakeKma({ keyError: true }).fetchFn);
    expect(bad.status).toBe(502);
    expect(bad.body.error.code).toBe('UPSTREAM_AUTH');
    const missing = await weather(env({ KMA_SERVICE_KEY: '' }), fakeKma().fetchFn);
    expect(missing.body.error.code).toBe('SERVER_NOT_CONFIGURED');
  });

  it('기상청에 연결이 안 되면 UPSTREAM_UNREACHABLE', async () => {
    const { status, body } = await weather(env(), async () => {
      throw new TypeError('fetch failed');
    });
    expect(status).toBe(502);
    expect(body.error.code).toBe('UPSTREAM_UNREACHABLE');
  });

  it('기상청이 답하지 않으면 기다리지 않고 UPSTREAM_UNREACHABLE', async () => {
    const hang: FetchLike = (_input, init) =>
      new Promise((_resolve, reject) => {
        init?.signal?.addEventListener('abort', () => reject(init.signal!.reason));
      });
    const { KmaClient } = await import('../src/lib/kma');
    const client = new KmaClient('key', hang, undefined, 50);
    await expect(client.current({ nx: 60, ny: 127 }, now)).rejects.toMatchObject({
      code: 'UPSTREAM_UNREACHABLE',
      message: expect.stringContaining('답하지 않았습니다'),
    });
  });

  it('Encoding 키를 넣어도 두 번 인코딩하지 않는다', async () => {
    const kma = fakeKma();
    await weather(env({ KMA_SERVICE_KEY: 'abc%2Bdef' }), kma.fetchFn);
    expect(kma.calls[0]).toContain('serviceKey=abc%2Bdef&');
  });
});
