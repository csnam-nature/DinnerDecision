import type { Bounds } from './geo';
import { ApiError } from '../http';

/**
 * 카카오 로컬 API (https://developers.kakao.com/docs/latest/ko/local/dev-guide)
 * 키는 서버에만 두고 앱에는 필요한 값만 넘긴다.
 */
const BASE = 'https://dapi.kakao.com/v2/local';

/** 카테고리 검색 한 페이지 최대 개수와 받을 수 있는 최대 페이지. */
export const KAKAO_PAGE_SIZE = 15;
export const KAKAO_MAX_RESULTS = 45;

/** 앱으로 보내는 식당 한 곳. 카카오 응답에서 필요한 것만 남긴다. */
export interface Place {
  id: string;
  name: string;
  /** 예: "음식점 > 한식 > 해장국". 분류는 앱이 cuisine_mapping.json 으로 한다. */
  category: string;
  phone: string;
  address: string;
  roadAddress: string;
  lat: number;
  lng: number;
  url: string;
}

interface KakaoPlaceDocument {
  id: string;
  place_name: string;
  category_name: string;
  phone: string;
  address_name: string;
  road_address_name: string;
  x: string;
  y: string;
  place_url: string;
}

interface KakaoMeta {
  total_count: number;
  pageable_count: number;
  is_end: boolean;
}

export interface CategoryPage {
  places: Place[];
  /** 이 조건으로 검색된 전체 개수. 45를 넘으면 칸을 더 나눠야 한다. */
  totalCount: number;
  isEnd: boolean;
}

export interface RegionInfo {
  /** 동 이름. 예: 성수동2가 */
  name: string;
  /** 예: 서울 성동구 성수동2가 */
  detail: string;
  /** 행정동 이름. 예: 성수2가1동 */
  adminName: string;
}

/** 위치 직접 설정에서 고를 수 있는 검색 결과. */
export interface LocationHit {
  name: string;
  detail: string;
  lat: number;
  lng: number;
}

export type FetchLike = (input: string, init?: RequestInit) => Promise<Response>;

export class KakaoClient {
  constructor(
    private readonly restKey: string,
    private readonly fetchFn: FetchLike = (input, init) => fetch(input, init),
  ) {
    if (!restKey) throw new ApiError(500, 'SERVER_NOT_CONFIGURED', '카카오 키가 설정되지 않았습니다');
  }

  /** 사각형 안의 음식점(FD6) 한 페이지. */
  async searchRestaurants(rect: Bounds, page: number): Promise<CategoryPage> {
    const params = new URLSearchParams({
      category_group_code: 'FD6',
      rect: [rect.minLng, rect.minLat, rect.maxLng, rect.maxLat].map((v) => v.toFixed(7)).join(','),
      page: String(page),
      size: String(KAKAO_PAGE_SIZE),
    });
    const body = await this.get<{ meta: KakaoMeta; documents: KakaoPlaceDocument[] }>(
      `${BASE}/search/category.json?${params}`,
    );
    return {
      places: body.documents.map(toPlace),
      totalCount: body.meta.total_count,
      isEnd: body.meta.is_end,
    };
  }

  /** 좌표 → 동 이름. */
  async region(lat: number, lng: number): Promise<RegionInfo | null> {
    const params = new URLSearchParams({ x: String(lng), y: String(lat) });
    const body = await this.get<{
      documents: Array<{
        region_type: 'B' | 'H';
        region_1depth_name: string;
        region_2depth_name: string;
        region_3depth_name: string;
      }>;
    }>(`${BASE}/geo/coord2regioncode.json?${params}`);
    const legal = body.documents.find((d) => d.region_type === 'B');
    const admin = body.documents.find((d) => d.region_type === 'H');
    const main = legal ?? admin;
    if (!main) return null;
    const name = main.region_3depth_name || main.region_2depth_name;
    return {
      name,
      detail: [main.region_1depth_name, main.region_2depth_name, main.region_3depth_name]
        .filter((s) => s)
        .join(' '),
      adminName: admin?.region_3depth_name ?? name,
    };
  }

  /**
   * 위치 검색. 주소 검색과 키워드 검색을 함께 해서 주소 결과를 먼저 준다.
   * 예: "성수이로 1" → 주소, "강남역" → 장소
   */
  async searchLocation(query: string, limit: number): Promise<LocationHit[]> {
    const params = new URLSearchParams({ query, size: '10' });
    const [addresses, keywords] = await Promise.all([
      this.get<{
        documents: Array<{ address_name: string; x: string; y: string; road_address: { address_name: string } | null }>;
      }>(`${BASE}/search/address.json?${params}`),
      this.get<{ documents: Array<{ place_name: string; road_address_name: string; address_name: string; x: string; y: string }> }>(
        `${BASE}/search/keyword.json?${params}`,
      ),
    ]);
    const hits: LocationHit[] = [
      ...addresses.documents.slice(0, 3).map((d) => ({
        name: d.address_name,
        detail: d.road_address?.address_name ?? '',
        lat: Number(d.y),
        lng: Number(d.x),
      })),
      ...keywords.documents.map((d) => ({
        name: d.place_name,
        detail: d.road_address_name || d.address_name,
        lat: Number(d.y),
        lng: Number(d.x),
      })),
    ];
    return hits.slice(0, limit);
  }

  private async get<T>(url: string): Promise<T> {
    const response = await this.fetchFn(url, {
      headers: { Authorization: `KakaoAK ${this.restKey}` },
    });
    if (response.status === 401 || response.status === 403) {
      throw new ApiError(502, 'UPSTREAM_AUTH', '카카오 키를 확인해야 합니다');
    }
    if (response.status === 429) {
      throw new ApiError(503, 'UPSTREAM_LIMIT', '카카오 호출 한도를 넘었습니다');
    }
    if (!response.ok) {
      throw new ApiError(502, 'UPSTREAM_ERROR', `카카오 응답 오류 (${response.status})`);
    }
    return (await response.json()) as T;
  }
}

function toPlace(d: KakaoPlaceDocument): Place {
  return {
    id: d.id,
    name: d.place_name,
    category: d.category_name,
    phone: d.phone,
    address: d.address_name,
    roadAddress: d.road_address_name,
    lat: Number(d.y),
    lng: Number(d.x),
    url: d.place_url,
  };
}
