import type { Bounds } from './geo';

const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/** 좌표 → geohash. 캐시 칸 이름으로만 쓰고, 좌표 자체는 저장하지 않는다. */
export function encodeGeohash(lat: number, lng: number, precision: number): string {
  let latRange: [number, number] = [-90, 90];
  let lngRange: [number, number] = [-180, 180];
  let hash = '';
  let bits = 0;
  let value = 0;
  let evenBit = true; // 짝수 번째 비트는 경도
  while (hash.length < precision) {
    const range = evenBit ? lngRange : latRange;
    const coord = evenBit ? lng : lat;
    const mid = (range[0] + range[1]) / 2;
    value <<= 1;
    if (coord >= mid) {
      value |= 1;
      range[0] = mid;
    } else {
      range[1] = mid;
    }
    evenBit = !evenBit;
    if (++bits === 5) {
      hash += BASE32[value];
      bits = 0;
      value = 0;
    }
  }
  return hash;
}

/** geohash 칸의 사각형. */
export function geohashBounds(hash: string): Bounds {
  const latRange: [number, number] = [-90, 90];
  const lngRange: [number, number] = [-180, 180];
  let evenBit = true;
  for (const ch of hash) {
    const idx = BASE32.indexOf(ch);
    if (idx < 0) throw new Error(`잘못된 geohash: ${hash}`);
    for (let bit = 4; bit >= 0; bit--) {
      const range = evenBit ? lngRange : latRange;
      const mid = (range[0] + range[1]) / 2;
      if ((idx >> bit) & 1) range[0] = mid;
      else range[1] = mid;
      evenBit = !evenBit;
    }
  }
  return { minLat: latRange[0], maxLat: latRange[1], minLng: lngRange[0], maxLng: lngRange[1] };
}

/** 사각형과 겹치는 geohash 칸 전부. */
export function geohashesCovering(b: Bounds, precision: number): string[] {
  const bits = precision * 5;
  const cellLat = 180 / 2 ** Math.floor(bits / 2);
  const cellLng = 360 / 2 ** Math.ceil(bits / 2);
  const hashes: string[] = [];
  const firstLat = Math.floor((b.minLat + 90) / cellLat) * cellLat - 90;
  const firstLng = Math.floor((b.minLng + 180) / cellLng) * cellLng - 180;
  for (let lat = firstLat; lat < b.maxLat; lat += cellLat) {
    for (let lng = firstLng; lng < b.maxLng; lng += cellLng) {
      hashes.push(encodeGeohash(lat + cellLat / 2, lng + cellLng / 2, precision));
    }
  }
  return [...new Set(hashes)];
}
