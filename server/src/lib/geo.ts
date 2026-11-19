/** 위경도 사각형. */
export interface Bounds {
  minLat: number;
  minLng: number;
  maxLat: number;
  maxLng: number;
}

const EARTH_RADIUS_M = 6_371_000;
const toRad = (deg: number) => (deg * Math.PI) / 180;

/** 두 좌표 사이 직선 거리(m). 앱의 core/geo.dart 와 같은 식. */
export function distanceMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(a)));
}

/** 중심에서 반경 radiusM 원을 감싸는 사각형. */
export function boundsAround(lat: number, lng: number, radiusM: number): Bounds {
  const dLat = (radiusM / EARTH_RADIUS_M) * (180 / Math.PI);
  const dLng = dLat / Math.cos(toRad(lat));
  return { minLat: lat - dLat, maxLat: lat + dLat, minLng: lng - dLng, maxLng: lng + dLng };
}

/** 사각형 안에서 점과 가장 가까운 곳까지의 거리(m). 점이 안에 있으면 0. */
export function distanceToBounds(lat: number, lng: number, b: Bounds): number {
  const nearLat = Math.min(Math.max(lat, b.minLat), b.maxLat);
  const nearLng = Math.min(Math.max(lng, b.minLng), b.maxLng);
  return distanceMeters(lat, lng, nearLat, nearLng);
}

/** 사각형을 4등분. 순서: 0=남서, 1=남동, 2=북서, 3=북동. */
export function quarter(b: Bounds): [Bounds, Bounds, Bounds, Bounds] {
  const midLat = (b.minLat + b.maxLat) / 2;
  const midLng = (b.minLng + b.maxLng) / 2;
  return [
    { minLat: b.minLat, maxLat: midLat, minLng: b.minLng, maxLng: midLng },
    { minLat: b.minLat, maxLat: midLat, minLng: midLng, maxLng: b.maxLng },
    { minLat: midLat, maxLat: b.maxLat, minLng: b.minLng, maxLng: midLng },
    { minLat: midLat, maxLat: b.maxLat, minLng: midLng, maxLng: b.maxLng },
  ];
}

/** 경로('', '0', '03' …)를 따라 4등분한 사각형. */
export function boundsAtPath(root: Bounds, path: string): Bounds {
  let b = root;
  for (const ch of path) {
    const index = Number(ch);
    if (!(index >= 0 && index <= 3)) throw new Error(`잘못된 칸 경로: ${path}`);
    b = quarter(b)[index]!;
  }
  return b;
}
