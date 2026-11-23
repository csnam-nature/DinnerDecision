import { ApiError } from '../http';
import type { FetchLike } from './kakao';
import { encodeDataGoKrKey } from './kma';

/**
 * 한국환경공단 에어코리아 (공공데이터포털)
 * - 측정소정보 MsrstnInfoInqireSvc/getNearbyMsrstnList: TM 좌표 → 가까운 측정소 (가까운 순)
 * - 대기오염정보 ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty: 측정소별 실시간 PM10·PM2.5
 * 두 서비스 모두 공공데이터포털에서 각각 활용신청해야 한다 (키는 계정 키 하나).
 */
export const AIRKOREA_BASE = 'https://apis.data.go.kr/B552584';
export const AIRKOREA_TIMEOUT_MS = 5000;

export type DustLevel = 'good' | 'normal' | 'bad' | 'veryBad';

export interface DustReading {
  /** 미세먼지·초미세먼지 중 나쁜 쪽. */
  level: DustLevel;
  /** 미세먼지(PM10) 농도 ㎍/㎥와 등급 */
  pm10: number | null;
  pm10Level: DustLevel | null;
  /** 초미세먼지(PM2.5) 농도 ㎍/㎥와 등급 */
  pm25: number | null;
  pm25Level: DustLevel | null;
  station: string;
  /** 예: "2026-11-23 18:00" (한국 시간) */
  measuredAt: string;
}

interface AirKoreaBody<T> {
  response?: {
    header?: { resultCode?: string; resultMsg?: string };
    // 문서·버전에 따라 items가 배열이거나 { item: [...] } 로 온다.
    body?: { items?: T[] | { item?: T[] } };
  };
}

interface StationItem {
  stationName?: string;
  addr?: string;
  tm?: number | string;
}

interface ReadingItem {
  dataTime?: string;
  pm10Value?: string;
  pm25Value?: string;
  pm10Grade?: string | null;
  pm25Grade?: string | null;
  pm10Grade1h?: string | null;
  pm25Grade1h?: string | null;
}

/** 등급 1 좋음, 2 보통, 3 나쁨, 4 매우나쁨. 그 밖의 값(점검 중 등)은 null. */
export function gradeLevel(grade: string | null | undefined): DustLevel | null {
  switch (String(grade ?? '').trim()) {
    case '1':
      return 'good';
    case '2':
      return 'normal';
    case '3':
      return 'bad';
    case '4':
      return 'veryBad';
    default:
      return null;
  }
}

const ORDER: DustLevel[] = ['good', 'normal', 'bad', 'veryBad'];

/** 1시간 등급이 있으면 그것을, 없으면 24시간 등급을 쓴다. */
export const pm10Level = (item: ReadingItem) => gradeLevel(item.pm10Grade1h) ?? gradeLevel(item.pm10Grade);
export const pm25Level = (item: ReadingItem) => gradeLevel(item.pm25Grade1h) ?? gradeLevel(item.pm25Grade);

/** PM10과 PM2.5 중 나쁜 쪽. */
export function worseLevel(item: ReadingItem): DustLevel | null {
  const levels = [pm10Level(item), pm25Level(item)].filter((l): l is DustLevel => l !== null);
  if (levels.length === 0) return null;
  return levels.reduce((a, b) => (ORDER.indexOf(a) >= ORDER.indexOf(b) ? a : b));
}

const numberOrNull = (v: string | undefined) => {
  const n = Number(v);
  return v !== undefined && v.trim() !== '' && Number.isFinite(n) ? n : null;
};

export class AirKoreaClient {
  constructor(
    private readonly serviceKey: string,
    private readonly fetchFn: FetchLike = (input, init) => fetch(input, init),
    private readonly timeoutMs: number = AIRKOREA_TIMEOUT_MS,
  ) {}

  /** 가장 가까운 측정소 이름. */
  async nearestStation(tm: { x: number; y: number }): Promise<string | null> {
    const items = await this.get<StationItem>('MsrstnInfoInqireSvc/getNearbyMsrstnList', {
      tmX: tm.x.toFixed(3),
      tmY: tm.y.toFixed(3),
      ver: '1.1',
    });
    return items.find((i) => i.stationName)?.stationName ?? null;
  }

  async reading(station: string): Promise<DustReading | null> {
    const items = await this.get<ReadingItem>('ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty', {
      stationName: station,
      dataTerm: 'DAILY',
      numOfRows: '1',
      pageNo: '1',
      ver: '1.3',
    });
    const item = items[0];
    if (!item) return null;
    const level = worseLevel(item);
    if (!level) return null; // 점검·통신장애로 값이 없는 시간
    return {
      level,
      pm10: numberOrNull(item.pm10Value),
      pm10Level: pm10Level(item),
      pm25: numberOrNull(item.pm25Value),
      pm25Level: pm25Level(item),
      station,
      measuredAt: item.dataTime ?? '',
    };
  }

  private async get<T>(operation: string, params: Record<string, string>): Promise<T[]> {
    if (!this.serviceKey) throw new ApiError(500, 'SERVER_NOT_CONFIGURED', '에어코리아 키가 설정되지 않았습니다');
    const query = new URLSearchParams({ returnType: 'json', ...params });
    const started = Date.now();
    let response: Response;
    let text: string;
    try {
      response = await this.fetchFn(
        `${AIRKOREA_BASE}/${operation}?serviceKey=${encodeDataGoKrKey(this.serviceKey)}&${query}`,
        { signal: AbortSignal.timeout(this.timeoutMs) },
      );
      text = await response.text();
    } catch (error) {
      console.warn(JSON.stringify({ airkoreaUnreachable: String(error), operation, ms: Date.now() - started }));
      throw new ApiError(502, 'UPSTREAM_UNREACHABLE', '에어코리아에 연결하지 못했습니다');
    }
    console.log(JSON.stringify({ airkorea: operation, status: response.status, ms: Date.now() - started }));
    if (text.includes('SERVICE_KEY_IS_NOT_REGISTERED') || text.includes('SERVICE ACCESS DENIED')) {
      console.warn(JSON.stringify({ airkoreaError: text.slice(0, 300) }));
      throw new ApiError(502, 'UPSTREAM_AUTH', '에어코리아 키를 확인해야 합니다 (활용신청 필요)');
    }
    let body: AirKoreaBody<T>;
    try {
      body = JSON.parse(text) as AirKoreaBody<T>;
    } catch {
      console.warn(JSON.stringify({ airkoreaStatus: response.status, airkoreaError: text.slice(0, 300) }));
      throw new ApiError(502, 'UPSTREAM_ERROR', `에어코리아 응답 오류 (${response.status})`);
    }
    const code = body.response?.header?.resultCode;
    if (code !== '00') {
      console.warn(JSON.stringify({ airkoreaResult: code, airkoreaMessage: body.response?.header?.resultMsg }));
      throw new ApiError(502, 'UPSTREAM_ERROR', `에어코리아 응답 오류 (${code ?? response.status})`);
    }
    const items = body.response?.body?.items;
    return Array.isArray(items) ? items : (items?.item ?? []);
  }
}
