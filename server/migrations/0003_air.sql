-- 미세먼지 측정소 캐시 (5단계 보강). 기상청 격자(5km)마다 가장 가까운 에어코리아 측정소.
-- 측정소는 거의 바뀌지 않아 30일 저장한다. 좌표는 저장하지 않는다.
CREATE TABLE air_stations (
  grid       TEXT    NOT NULL PRIMARY KEY, -- 'nx,ny'
  station    TEXT    NOT NULL,
  expires_at INTEGER NOT NULL
);
