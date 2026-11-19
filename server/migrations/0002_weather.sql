-- 날씨 캐시 (PLAN.md 6장). 기상청 격자(5km) 단위로 저장하고 좌표는 저장하지 않는다.
CREATE TABLE weather_cells (
  grid       TEXT    NOT NULL PRIMARY KEY, -- 'nx,ny'
  data       TEXT    NOT NULL,             -- /weather 응답 JSON
  expires_at INTEGER NOT NULL
);
