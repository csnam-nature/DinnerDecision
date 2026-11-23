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

interface FakeOptions {
  noDataFor?: string[];
  keyError?: boolean;
  fcstFails?: boolean;
  /** 에어코리아: 'error'면 오류, 'hang'이면 응답 없음, 'noGrade'면 점검 중(등급 없음) */
  air?: 'ok' | 'error' | 'hang' | 'noGrade';
}

/**
 * 가짜 기상청·카카오 좌표 변환·에어코리아. noDataFor에 든 발표 시각은 '자료 없음(03)'으로 답한다.
 * calls에는 기상청 호출만, airCalls에는 카카오·에어코리아 호출이 쌓인다.
 */
function fakeKma(options: FakeOptions = {}) {
  const calls: string[] = [];
  const airCalls: string[] = [];
  const fetchFn: FetchLike = async (input, init) => {
    const url = new URL(input);
    if (url.hostname === 'dapi.kakao.com' || url.pathname.includes('B552584')) {
      airCalls.push(input);
      return fakeAir(url, init, options.air ?? 'ok');
    }
    calls.push(input);
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
  return { fetchFn, calls, airCalls };
}

function airJson(items: object[], resultCode = '00') {
  return JSON.stringify({ response: { header: { resultCode, resultMsg: 'NORMAL_CODE' }, body: { items } } });
}

async function fakeAir(url: URL, init: RequestInit | undefined, mode: NonNullable<FakeOptions['air']>) {
  if (url.hostname === 'dapi.kakao.com') {
    expect(url.searchParams.get('output_coord')).toBe('TM');
    return Response.json({ documents: [{ x: 198056.1234, y: 451984.5678 }] });
  }
  if (mode === 'hang') {
    return new Promise<Response>((_resolve, reject) => {
      init?.signal?.addEventListener('abort', () => reject(init.signal!.reason));
    });
  }
  if (mode === 'error') return new Response('<OpenAPI_ServiceResponse>SERVICE_KEY_IS_NOT_REGISTERED_ERROR</OpenAPI_ServiceResponse>');
  if (url.pathname.endsWith('getNearbyMsrstnList')) {
    expect(url.searchParams.get('tmX')).toBe('198056.123');
    return new Response(airJson([{ stationName: '중구', addr: '서울 중구 덕수궁길 15', tm: 0.8 }, { stationName: '종로구', tm: 2.1 }]));
  }
  // 실시간 측정값: PM10 1시간 등급 3(나쁨), PM2.5 2(보통) → 나쁜 쪽인 '나쁨'
  return new Response(
    airJson([
      mode === 'noGrade'
        ? { dataTime: '2026-11-19 18:00', pm10Value: '-', pm25Value: '-', pm10Grade: null, pm25Grade: null }
        : {
            dataTime: '2026-11-19 18:00',
            pm10Value: '85',
            pm25Value: '30',
            pm10Grade: '2',
            pm25Grade: '2',
            pm10Grade1h: '3',
            pm25Grade1h: '2',
          },
    ]),
  );
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
      dust: 'bad',
      dustDetail: { pm10: 85, pm25: 30, station: '중구', measuredAt: '2026-11-19 18:00' },
      attribution: '날씨: 기상청 · 미세먼지: 에어코리아(한국환경공단, 실시간 미확정 자료)',
    });
    const ncst = new URL(kma.calls.find((c) => c.includes('Ncst'))!);
    expect(ncst.searchParams.get('nx')).toBe('60');
    expect(ncst.searchParams.get('ny')).toBe('127');
    expect(ncst.searchParams.get('base_time')).toBe('1800');
    // Decoding 키는 한 번만 인코딩해서 보낸다.
    expect(kma.calls[0]).toContain('serviceKey=abc%2Bdef%2Fghi%3D%3D&');
  });

  it('미세먼지를 못 받아도 날씨는 주고 dust는 null', async () => {
    for (const air of ['error', 'noGrade'] as const) {
      const { status, body } = await weather(env(), fakeKma({ air }).fetchFn);
      expect(status, air).toBe(200);
      expect(body.tempC).toBe(8.7);
      expect(body.dust).toBeNull();
      expect(body.dustDetail).toBeNull();
      expect(body.attribution).toBe('날씨: 기상청');
    }
  });

  it('에어코리아가 답하지 않아도 6초 안에 날씨를 준다', async () => {
    const started = Date.now();
    const { status, body } = await weather(env(), fakeKma({ air: 'hang' }).fetchFn);
    expect(status).toBe(200);
    expect(body.dust).toBeNull();
    expect(Date.now() - started).toBeLessThan(7000);
  }, 10_000);

  it('측정소는 격자마다 한 번만 찾는다', async () => {
    const e = env();
    const kma = fakeKma();
    await weather(e, kma.fetchFn);
    await weather(e, kma.fetchFn, now + 21 * 60_000); // 날씨는 다시 받지만
    const kakao = kma.airCalls.filter((c) => c.includes('transcoord'));
    const stations = kma.airCalls.filter((c) => c.includes('getNearbyMsrstnList'));
    const readings = kma.airCalls.filter((c) => c.includes('RltmMesureDnsty'));
    expect(kakao).toHaveLength(1); // 측정소는 저장해 둔 것을 쓴다
    expect(stations).toHaveLength(1);
    expect(readings).toHaveLength(2); // 측정값은 매번 새로
    expect(new URL(readings[0]!).searchParams.get('stationName')).toBe('중구');
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

describe('미세먼지 등급', () => {
  it('PM10·PM2.5 중 나쁜 쪽, 1시간 등급을 먼저 쓴다', async () => {
    const { gradeLevel, worseLevel } = await import('../src/lib/airkorea');
    expect(['1', '2', '3', '4', '', null, undefined, '-'].map((g) => gradeLevel(g as string | null))).toEqual([
      'good',
      'normal',
      'bad',
      'veryBad',
      null,
      null,
      null,
      null,
    ]);
    expect(worseLevel({ pm10Grade: '1', pm25Grade: '4' })).toBe('veryBad');
    expect(worseLevel({ pm10Grade: '3', pm10Grade1h: '1', pm25Grade: '1' })).toBe('good');
    expect(worseLevel({ pm10Grade: null, pm25Grade: '2' })).toBe('normal');
    expect(worseLevel({})).toBeNull();
  });
});
