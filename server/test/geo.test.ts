import { describe, expect, it } from 'vitest';
import { boundsAround, boundsAtPath, distanceMeters, distanceToBounds, quarter } from '../src/lib/geo';
import { encodeGeohash, geohashBounds, geohashesCovering } from '../src/lib/geohash';

describe('geo', () => {
  it('거리 계산이 앱과 같은 결과를 낸다', () => {
    // 성수동2가 → 강남역 약 5.8km
    const d = distanceMeters(37.5446, 127.0559, 37.4979, 127.0276);
    expect(d).toBeGreaterThan(5700);
    expect(d).toBeLessThan(5800);
  });

  it('반경을 감싸는 사각형의 변까지 거리가 반경과 같다', () => {
    const b = boundsAround(37.5, 127, 1000);
    expect(distanceMeters(37.5, 127, b.maxLat, 127)).toBeCloseTo(1000, 0);
    expect(distanceMeters(37.5, 127, 37.5, b.maxLng)).toBeCloseTo(1000, -1);
  });

  it('4등분과 경로가 일치한다', () => {
    const root = { minLat: 0, maxLat: 4, minLng: 0, maxLng: 4 };
    expect(boundsAtPath(root, '3')).toEqual(quarter(root)[3]);
    expect(boundsAtPath(root, '30')).toEqual({ minLat: 2, maxLat: 3, minLng: 2, maxLng: 3 });
    expect(distanceToBounds(1, 1, root)).toBe(0);
  });
});

describe('geohash', () => {
  it('알려진 값으로 인코딩한다', () => {
    expect(encodeGeohash(57.64911, 10.40744, 11)).toBe('u4pruydqqvj');
    expect(encodeGeohash(42.605, -5.603, 5)).toBe('ezs42');
  });

  it('칸 안의 점은 그 칸으로 인코딩된다', () => {
    const hash = encodeGeohash(37.5446, 127.0559, 5);
    const b = geohashBounds(hash);
    expect(37.5446).toBeGreaterThanOrEqual(b.minLat);
    expect(37.5446).toBeLessThan(b.maxLat);
    expect(encodeGeohash((b.minLat + b.maxLat) / 2, (b.minLng + b.maxLng) / 2, 5)).toBe(hash);
  });

  it('사각형을 빠짐없이 덮는다', () => {
    const area = boundsAround(37.5446, 127.0559, 1000);
    const hashes = geohashesCovering(area, 6);
    for (const [lat, lng] of [
      [area.minLat, area.minLng],
      [area.maxLat - 1e-9, area.maxLng - 1e-9],
      [37.5446, 127.0559],
    ] as const) {
      expect(hashes).toContain(encodeGeohash(lat, lng, 6));
    }
  });
});
