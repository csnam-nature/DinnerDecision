-- 주변 식당 캐시 (PLAN.md 6장)
-- 좌표를 저장하지 않는다. 지구를 geohash 6자리 칸(약 1km × 0.6km)으로 나누고,
-- 칸 안을 필요하면 4등분해서 그 결과만 저장한다.
--   tile : geohash 6자리 (예: wydm9q)
--   path : 4등분한 경로. 칸 자체는 '', 그 아래는 '0', '03', '031' … (0=남서, 1=남동, 2=북서, 3=북동)
--   kind : 'leaf' = data에 식당 목록(JSON), 'split' = 결과가 45개를 넘어 아래 칸으로 나눔
CREATE TABLE place_cells (
  tile       TEXT    NOT NULL,
  path       TEXT    NOT NULL,
  kind       TEXT    NOT NULL CHECK (kind IN ('leaf', 'split')),
  data       TEXT,
  truncated  INTEGER NOT NULL DEFAULT 0,
  expires_at INTEGER NOT NULL,
  PRIMARY KEY (tile, path)
);
CREATE INDEX place_cells_expires ON place_cells (expires_at);

-- 호출 제한. key는 IP를 그대로 쓰지 않고 해시한 값.
CREATE TABLE rate_limits (
  key        TEXT    NOT NULL,
  window     INTEGER NOT NULL,
  count      INTEGER NOT NULL,
  PRIMARY KEY (key, window)
);
