import { ApiError } from '../http';
import type { FetchLike } from './kakao';
import type { KmaGrid } from './kmaGrid';

/**
 * 기상청 단기예보 조회서비스 (공공데이터포털)
 * https://www.data.go.kr/data/15084084/openapi.do
 *
 * - 초단기실황(getUltraSrtNcst): 지금 기온·강수 형태·1시간 강수량. 매시 정각 자료가 40분쯤 나온다.
 * - 초단기예보(getUltraSrtFcst): 앞으로 6시간의 하늘 상태. 매시 30분 자료가 45분쯤 나온다.
 */
export const KMA_DEFAULT_BASE = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';

/** 기상청이 답하지 않을 때 기다리는 시간. 앱은 15초에 포기하므로 그보다 짧게. */
export const KMA_TIMEOUT_MS = 8000;
const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

export type Precipitation = 'none' | 'rain' | 'snow';
export type Sky = 'clear' | 'partly' | 'cloudy';

export interface CurrentWeather {
  tempC: number;
  precipitation: Precipitation;
  /** 초단기예보를 못 받으면 null. */
  sky: Sky | null;
  /** 1시간 강수량(mm). 비가 안 오면 0. */
  rain1hMm: number;
  humidity: number | null;
  /** 관측 기준 시각. 예: 2026-11-19T18:00+09:00 */
  observedAt: string;
}

interface KmaItem {
  category: string;
  obsrValue?: string;
  fcstDate?: string;
  fcstTime?: string;
  fcstValue?: string;
}

interface KmaBody {
  response?: {
    header?: { resultCode?: string; resultMsg?: string };
    body?: { items?: { item?: KmaItem[] } };
  };
}

/** 한국 시간 기준 날짜(YYYYMMDD)와 시각(HHMM). */
export function kstParts(ms: number): { date: string; hour: number; minute: number } {
  const d = new Date(ms + KST_OFFSET_MS);
  const date = `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, '0')}${String(d.getUTCDate()).padStart(2, '0')}`;
  return { date, hour: d.getUTCHours(), minute: d.getUTCMinutes() };
}

/**
 * 지금 받을 수 있는 가장 최근 발표 시각. [delayMin]분 지나야 자료가 나온다고 보고,
 * [stepBack]만큼 더 이전 발표를 고를 수 있다 (자료가 늦게 나왔을 때 한 번 더 시도용).
 */
export function baseTime(nowMs: number, minuteOfBase: 0 | 30, delayMin: number, stepBack = 0): { date: string; time: string } {
  // 발표 시각 = 매시 minuteOfBase분. 그 뒤 delayMin분이 지나야 쓸 수 있다.
  const hourMs = 60 * 60 * 1000;
  let t = nowMs - (minuteOfBase + delayMin) * 60 * 1000;
  t -= stepBack * hourMs;
  const { date, hour } = kstParts(t);
  return { date, time: `${String(hour).padStart(2, '0')}${minuteOfBase === 0 ? '00' : '30'}` };
}

export class KmaClient {
  constructor(
    private readonly serviceKey: string,
    private readonly fetchFn: FetchLike = (input, init) => fetch(input, init),
    private readonly base: string = KMA_DEFAULT_BASE,
    private readonly timeoutMs: number = KMA_TIMEOUT_MS,
  ) {
    if (!serviceKey) throw new ApiError(500, 'SERVER_NOT_CONFIGURED', '기상청 키가 설정되지 않았습니다');
  }

  async current(grid: KmaGrid, nowMs: number): Promise<CurrentWeather> {
    const [ncst, fcst] = await Promise.all([
      this.withFallback((back) => this.ncst(grid, nowMs, back)),
      // 하늘 상태는 없어도 날씨는 보여줄 수 있다.
      this.withFallback((back) => this.fcst(grid, nowMs, back)).catch(() => null),
    ]);
    return { ...ncst, sky: fcst };
  }

  /** 발표 직후라 자료가 아직 없으면(NO_DATA) 한 시간 전 자료로 한 번 더. */
  private async withFallback<T>(run: (stepBack: number) => Promise<T>): Promise<T> {
    try {
      return await run(0);
    } catch (error) {
      if (error instanceof ApiError && error.code === 'UPSTREAM_NO_DATA') return run(1);
      throw error;
    }
  }

  private async ncst(grid: KmaGrid, nowMs: number, stepBack: number): Promise<Omit<CurrentWeather, 'sky'>> {
    const base = baseTime(nowMs, 0, 40, stepBack);
    const items = await this.get('getUltraSrtNcst', grid, base);
    const value = (category: string) => {
      const raw = items.find((i) => i.category === category)?.obsrValue;
      const n = raw === undefined ? Number.NaN : Number(raw);
      return Number.isFinite(n) ? n : null;
    };
    const temp = value('T1H');
    if (temp === null) throw new ApiError(502, 'UPSTREAM_ERROR', '기상청 응답에 기온이 없습니다');
    return {
      tempC: temp,
      precipitation: precipitationOf(value('PTY') ?? 0),
      rain1hMm: Math.max(0, value('RN1') ?? 0),
      humidity: value('REH'),
      observedAt: `${base.date.slice(0, 4)}-${base.date.slice(4, 6)}-${base.date.slice(6, 8)}T${base.time.slice(0, 2)}:00+09:00`,
    };
  }

  /** 가장 가까운 예보 시각의 하늘 상태. */
  private async fcst(grid: KmaGrid, nowMs: number, stepBack: number): Promise<Sky | null> {
    const base = baseTime(nowMs, 30, 45, stepBack);
    const items = (await this.get('getUltraSrtFcst', grid, base)).filter((i) => i.category === 'SKY');
    items.sort((a, b) => `${a.fcstDate}${a.fcstTime}`.localeCompare(`${b.fcstDate}${b.fcstTime}`));
    const code = Number(items[0]?.fcstValue);
    return code === 1 ? 'clear' : code === 3 ? 'partly' : code === 4 ? 'cloudy' : null;
  }

  private async get(operation: string, grid: KmaGrid, base: { date: string; time: string }): Promise<KmaItem[]> {
    const key = encodeDataGoKrKey(this.serviceKey);
    const query = new URLSearchParams({
      pageNo: '1',
      numOfRows: '100',
      dataType: 'JSON',
      base_date: base.date,
      base_time: base.time,
      nx: String(grid.nx),
      ny: String(grid.ny),
    });
    const started = Date.now();
    let response: Response;
    let text: string;
    try {
      response = await this.fetchFn(`${this.base}/${operation}?serviceKey=${key}&${query}`, {
        signal: AbortSignal.timeout(this.timeoutMs),
      });
      text = await response.text();
    } catch (error) {
      // Workers에서 공공데이터포털에 연결이 안 되거나 답이 없는 경우 (PLAN.md 12장).
      // 원인을 알 수 있게 걸린 시간과 오류를 남긴다. 키는 남기지 않는다.
      const timedOut = error instanceof Error && (error.name === 'TimeoutError' || error.name === 'AbortError');
      console.warn(
        JSON.stringify({ kmaUnreachable: String(error), operation, ms: Date.now() - started, timedOut }),
      );
      throw new ApiError(
        502,
        'UPSTREAM_UNREACHABLE',
        timedOut ? `기상청이 ${this.timeoutMs / 1000}초 동안 답하지 않았습니다` : '기상청에 연결하지 못했습니다',
      );
    }
    console.log(JSON.stringify({ kma: operation, status: response.status, ms: Date.now() - started }));
    // 키 오류 등은 JSON이 아니라 XML(OpenAPI_ServiceResponse)로 온다.
    if (text.includes('SERVICE_KEY_IS_NOT_REGISTERED') || text.includes('SERVICE ACCESS DENIED')) {
      console.warn(JSON.stringify({ kmaStatus: response.status, kmaError: text.slice(0, 300) }));
      throw new ApiError(502, 'UPSTREAM_AUTH', '기상청 키를 확인해야 합니다');
    }
    if (text.includes('LIMITED_NUMBER_OF_SERVICE_REQUESTS')) {
      throw new ApiError(503, 'UPSTREAM_LIMIT', '기상청 호출 한도를 넘었습니다');
    }
    let body: KmaBody;
    try {
      body = JSON.parse(text) as KmaBody;
    } catch {
      console.warn(JSON.stringify({ kmaStatus: response.status, kmaError: text.slice(0, 300) }));
      throw new ApiError(502, 'UPSTREAM_ERROR', `기상청 응답 오류 (${response.status})`);
    }
    const code = body.response?.header?.resultCode;
    if (code === '03') throw new ApiError(502, 'UPSTREAM_NO_DATA', '기상청 자료가 아직 없습니다');
    if (code !== '00') {
      console.warn(JSON.stringify({ kmaResult: code, kmaMessage: body.response?.header?.resultMsg }));
      throw new ApiError(502, 'UPSTREAM_ERROR', `기상청 응답 오류 (${code ?? response.status})`);
    }
    return body.response?.body?.items?.item ?? [];
  }
}

/**
 * 공공데이터포털 키를 주소에 넣을 형태로. '일반 인증키(Decoding)'를 넣는 것이 원칙이지만,
 * Encoding 키(이미 %가 들어 있는 값)를 넣어도 두 번 인코딩되지 않게 한다.
 */
export function encodeDataGoKrKey(key: string): string {
  return key.includes('%') ? key : encodeURIComponent(key);
}

/** 강수 형태(PTY): 0 없음, 1 비, 2 비/눈, 3 눈, 5 빗방울, 6 빗방울눈날림, 7 눈날림 */
export function precipitationOf(pty: number): Precipitation {
  if (pty === 3 || pty === 7) return 'snow';
  if (pty === 1 || pty === 2 || pty === 5 || pty === 6) return 'rain';
  return 'none';
}
