# dinner-api — Cloudflare Workers 중계 서버

앱 대신 카카오 로컬 API를 부르고 결과를 캐시하는 서버입니다. 계획은 [`docs/PLAN.md`](../docs/PLAN.md) 4·6장.

- API 키는 서버(Workers Secrets)에만 둡니다. 앱에는 키가 없습니다.
- 사용자 좌표는 저장하지도, 로그에 남기지도 않습니다. 앱은 위경도를 약 100m 단위(소수점 3자리)로 줄여 보내고, Cloudflare의 요청 기록(invocation logs)도 꺼 두었습니다(`wrangler.toml`). `npx wrangler tail` 실시간 보기에는 요청 주소가 보이지만 저장되지는 않습니다.
- 무료 요금제 안에서 동작하도록 한 요청에 카카오 호출을 40번 이하로 제한합니다.

## API

| 주소 | 설명 |
|---|---|
| `GET /health` | 서버 상태 |
| `GET /places?lat=&lng=&radius=` | 반경(100~2100m) 안 음식점. 가까운 순. 앱은 줄인 좌표 오차를 감안해 설정 반경 +100m로 요청 |
| `GET /region?lat=&lng=` | 동 이름 (예: 성수동2가) |
| `GET /search?query=` | 위치 직접 설정용 주소·장소 검색 |
| `GET /weather?lat=&lng=` | 지금 날씨 (기상청 초단기실황 + 초단기예보) |

`/weather` 응답:

```json
{
  "tempC": 8.7, "precipitation": "rain", "sky": "cloudy",
  "rain1hMm": 1.5, "humidity": 90, "observedAt": "2026-11-19T18:00+09:00",
  "dust": "bad", "dustDetail": { "pm10": 85, "pm10Level": "bad", "pm25": 30, "pm25Level": "normal", "station": "중구", "measuredAt": "2026-11-19 18:00" },
  "attribution": "날씨: 기상청 · 미세먼지: 에어코리아(한국환경공단, 실시간 미확정 자료)"
}
```

- `precipitation`: `none` · `rain`(비, 비/눈, 빗방울) · `snow`(눈, 눈날림)
- `sky`: `clear`(맑음) · `partly`(구름많음) · `cloudy`(흐림), 예보를 못 받으면 `null`
- 위경도를 기상청 격자(5km)로 바꿔 격자 단위로 20분 저장합니다. 좌표는 저장하지 않습니다.
- 실황은 매시 정각 자료가 40분쯤, 예보는 매시 30분 자료가 45분쯤 나옵니다. 발표 직후라 자료가 없으면 한 시간 전 자료를 씁니다.
- `dust`: 미세먼지 등급 `good`(좋음)·`normal`(보통)·`bad`(나쁨)·`veryBad`(매우나쁨). PM10·PM2.5 중 나쁜 쪽, 1시간 등급 우선. 못 받으면 `null`이고 날씨는 그대로 줍니다.
- `dustDetail`: `{ pm10, pm10Level, pm25, pm25Level, station, measuredAt }` — 미세먼지(PM10)·초미세먼지(PM2.5) 농도(㎍/㎥)와 각각의 등급 (가까운 에어코리아 측정소의 실시간 값)
- 미세먼지 순서: 카카오 좌표 변환(위경도 → TM) → 에어코리아 근접 측정소(격자마다 30일 저장) → 측정소 실시간 측정값. 6초 안에 못 받으면 건너뜁니다.
- 에어코리아 키는 기상청과 같은 공공데이터포털 계정 키를 씁니다(`AIRKOREA_SERVICE_KEY`로 따로 줄 수도 있음). 대신 공공데이터포털에서 **한국환경공단_에어코리아_측정소정보**와 **한국환경공단_에어코리아_대기오염정보**를 각각 활용신청해야 합니다.

`/places` 응답:

```json
{
  "places": [
    {
      "id": "12345", "name": "성수 할매순대국", "category": "음식점 > 한식 > 순대",
      "phone": "02-000-0000", "address": "서울 성동구 성수동2가 1",
      "roadAddress": "서울 성동구 성수이로 1", "lat": 37.5446, "lng": 127.0559,
      "url": "http://place.map.kakao.com/12345", "distanceM": 120
    }
  ],
  "complete": true,
  "truncated": false,
  "attribution": "장소 정보: 카카오"
}
```

- `complete: false` — 식당이 아주 많은 동네라 이번 요청에서 다 못 찾았습니다. 다시 부르면 이어서 채웁니다 (앱이 자동으로 최대 4번 부름).
- `truncated: true` — 아주 좁은 칸에도 45곳이 넘어 일부가 빠졌을 수 있습니다.
- 분류(한식·중식…)는 서버가 아니라 앱의 `assets/config/cuisine_mapping.json`으로 정합니다.

오류는 `{"error": {"code": "...", "message": "..."}}` 형식입니다.

| code | 상태 | 뜻 |
|---|---|---|
| `BAD_REQUEST` | 400 | 값이 없거나 틀림 |
| `OUT_OF_SERVICE_AREA` | 400 | 국내 좌표가 아님 |
| `APP_CHECK_FAILED` | 401 | 앱 인증 실패 (`APP_CHECK_MODE=enforce`일 때) |
| `RATE_LIMITED` | 429 | 같은 IP에서 1분에 30번 넘게 부름 |
| `UPSTREAM_AUTH` | 502 | 카카오·기상청 키 문제 |
| `UPSTREAM_LIMIT` | 503 | 카카오·기상청 호출 한도 초과 |
| `UPSTREAM_ERROR` | 502 | 카카오·기상청 응답 오류 |
| `UPSTREAM_UNREACHABLE` | 502 | 카카오·기상청에 연결 자체가 안 됨 |

## 영역 분할 검색 (PLAN.md 4.2)

카카오 카테고리 검색은 한 조건에 최대 45곳만 줍니다. 그래서:

1. 지도를 고정된 칸(geohash 5자리, 약 4km)으로 나누고, 반경 원에 걸치는 칸만 검색합니다.
2. 한 칸에 45곳이 넘으면 4등분해서 다시 검색합니다 (최대 6단계, 약 60m 칸까지).
3. 칸 결과를 D1에 24시간 저장합니다. 칸이 사용자 위치와 무관하게 고정되어 있어 같은 동네 사용자끼리 캐시를 나눠 씁니다.
4. 가까운 칸부터 채우고, 호출 한도(40번)에 닿으면 남은 칸은 다음 요청에서 이어서 채웁니다.

테스트 기준으로 반경 안 식당이 약 140곳이면 한 번(31회 호출), 약 700곳이면 4번 요청(약 120회 호출)으로 다 채워지고, 그 뒤 24시간은 카카오를 부르지 않습니다.

## 개발

Node.js 22.13 이상이 필요합니다.

> 아래 `npm` 명령은 모두 **`server` 폴더 안에서** 실행합니다. 저장소 맨 위 폴더에는 `package.json`이 없어서 `ENOENT` 오류가 납니다.
>
> ```bash
> cd server
> ```

```bash
npm install
```

```bash
npm test
```

```bash
npm run typecheck
```

로컬 실행 (`.dev.vars.example`을 `.dev.vars`로 복사하고 카카오 키를 넣은 뒤):

```bash
npm run db:migrate:local
```

```bash
npm run dev
```

## 처음 배포하기 (0단계 준비물이 있어야 함)

1. Cloudflare 로그인

   ```bash
   npx wrangler login
   ```

2. D1 데이터베이스를 만들고, 나온 `database_id`를 `wrangler.toml`에 넣습니다.

   ```bash
   npx wrangler d1 create dinner-cache
   ```

3. 테이블 만들기

   ```bash
   npm run db:migrate:remote
   ```

4. 비밀값 넣기 (카카오 디벨로퍼스 → 내 애플리케이션 → 앱 키 → **REST API 키**)

   먼저 같은 앱의 왼쪽 메뉴 **[앱] → [제품 설정] → [카카오맵]** 에서 **사용 설정을 ON** 해야 합니다.
   꺼져 있으면 카카오가 모든 호출을 거절하고 서버는 `UPSTREAM_AUTH`(502)를 돌려줍니다.

   ```bash
   npx wrangler secret put KAKAO_REST_KEY
   ```

   ```bash
   npx wrangler secret put RATE_LIMIT_SALT
   ```

   기상청 키는 공공데이터포털 → 기상청_단기예보 조회서비스 → **일반 인증키(Decoding)** 입니다.

   ```bash
   npx wrangler secret put KMA_SERVICE_KEY
   ```

5. 배포. 주소는 `https://dinner-api.<계정>.workers.dev` 입니다.

   ```bash
   npm run deploy
   ```

6. 앱을 이 주소로 실행합니다.

   ```bash
   flutter run --dart-define=API_BASE_URL=https://dinner-api.<계정>.workers.dev
   ```

## 문제 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| `npm` 실행 시 `ENOENT ... package.json` | 저장소 맨 위 폴더에서 실행 | `server` 폴더에서 실행 |
| `/region` 등이 `INTERNAL`(500) | 원격 D1에 테이블 없음 | `npm run db:migrate:remote` |
| `SERVER_NOT_CONFIGURED` | `KAKAO_REST_KEY` secret 없음 | `npx wrangler secret put KAKAO_REST_KEY` |
| `UPSTREAM_AUTH` | 카카오맵 사용 설정 꺼짐 또는 REST API 키가 아님 | 위 4번 확인. `npx wrangler tail`에 카카오 오류 내용이 찍힘 |
| `/weather`가 `UPSTREAM_AUTH` | 기상청 키 미승인·오타 | 활용신청 직후 1~2시간은 키가 동작하지 않을 수 있음. `wrangler tail`에 `kmaError` 확인 |
| `/weather`가 `UPSTREAM_UNREACHABLE` | Workers에서 공공데이터포털에 연결 안 됨 | PLAN.md 12장 대응(다른 경로로 분리) 검토 |
| 배포 후 `/weather`가 `INTERNAL` | 새 표(`weather_cells`)가 없음 | `npm run db:migrate:remote` |

## 설정값 (`wrangler.toml`의 `[vars]`)

| 이름 | 기본 | 설명 |
|---|---|---|
| `APP_CHECK_MODE` | `off` | `off` → `monitor`(로그만) → `enforce`(막음) 순서로 올립니다 |
| `FIREBASE_PROJECT_NUMBER` | | Firebase 프로젝트 번호. App Check 검사에 필요 |
| `FIREBASE_APP_IDS` | | 허용할 앱 ID (쉼표 구분). 비우면 같은 프로젝트 앱 모두 |
| `KAKAO_CALL_BUDGET` | `40` | 요청 한 번의 카카오 호출 상한 (최대 45) |
| `RATE_LIMIT_PER_MINUTE` | `30` | IP 하나의 1분당 요청 수 |

D1에 남는 것: 칸 이름(geohash)과 그 칸의 식당 목록, 기상청 격자 번호와 그 격자의 날씨, 해시한 IP의 1분 호출 횟수. 매일 새벽 4시(한국)에 지난 기록을 지웁니다.

## 폴더

| 위치 | 내용 |
|---|---|
| `src/index.ts` | Workers 진입점 (default export만 둠) |
| `src/app.ts` | 라우팅, App Check, 호출 제한, 오류 처리 |
| `src/routes/` | `/places`, `/region`, `/search`, `/weather` |
| `src/lib/kma.ts`, `kmaGrid.ts` | 기상청 API, 위경도 → 기상청 격자 |
| `src/lib/airkorea.ts` | 에어코리아 근접 측정소·실시간 미세먼지 |
| `src/lib/placeSearch.ts` | 영역 분할 검색 |
| `src/lib/kakao.ts` | 카카오 로컬 API |
| `src/lib/cellStore.ts` | D1 칸 캐시 |
| `src/lib/appCheck.ts` | Firebase App Check 토큰 검증 |
| `src/lib/rateLimit.ts` | IP별 호출 제한 |
| `migrations/` | D1 테이블 |
| `test/` | 가짜 카카오 + node:sqlite로 만든 D1 대역으로 테스트 |
