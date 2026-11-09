# 오늘 저녁 뭐 먹지 (DinnerDecision) — 개발 계획서

> 버전 0.3 · 작성일 2026-11-09 · 상태: 결정 사항 반영 (서버: Cloudflare Workers)
> UI 상세 설계는 [`UI_PLAN.md`](./UI_PLAN.md) 참고

## 변경 이력
| 버전 | 내용 |
|---|---|
| 0.1 | 초안 (요구사항, 유사 앱 분석, 대안 비교) |
| 0.2 | 결정 사항 반영: Flutter, 네이버+카카오 혼합, Firebase Functions, 기기에만 저장, iOS는 집 맥북으로 빌드 |
| 0.3 | 중계 서버를 **Cloudflare Workers(무료)** 로 변경, Firebase는 **무료 요금제(Spark)** 로 App Check·Crashlytics만 사용 |

---

## 0. 확정된 결정 사항

| 항목 | 결정 |
|---|---|
| 앱 프레임워크 | **Flutter** (Android + iOS) |
| 식당 데이터 | **카카오 로컬 API** (반경 검색으로 1km 안 음식점 목록) |
| 지도 | **네이버 지도** (`flutter_naver_map`) — 지도 표시, 마커, 네이버 지도 앱 연결 |
| 중계 서버 | **Cloudflare Workers** (무료 요금제, TypeScript) + D1(SQLite) 캐시 |
| Firebase | **무료 요금제(Spark)** — App Check(앱 인증), Crashlytics(오류 수집)만 사용, 카드 등록 없음 |
| 기록 보관 | **1차: 기기에만 저장** (SQLite), 파일로 백업·복원 |
| iOS 빌드 | 평소에는 Windows/Android로 개발 → **iOS는 집 맥북으로 주기적으로 빌드·테스트** |

---

## 1. 개요

### 1.1 목적
현재 위치 1km 안의 음식점을 **한식·중식·일식·양식**으로 나눠 보여주고,
**날씨**와 **최근 방문 기록**을 함께 보고 **오늘의 추천 식당·메뉴를 이유와 함께** 제시하는 모바일 앱.

### 1.2 해결하려는 문제
- 매일 "뭐 먹지?" 고민 → 버튼 하나로 결정
- 늘 가던 곳만 감 → 최근 기록을 피해 **다양하게** 추천
- 날씨와 안 맞는 선택 → 비·추위·더위에 맞는 메뉴 추천

### 1.3 지원 환경
- Android 8.0 (API 26) 이상
- iOS 15 이상
- 화면: 휴대폰 세로 기준 (태블릿은 2차)

---

## 2. 유사 앱 분석 및 차별점

| 앱 | 참고할 점 | 부족한 점 |
|---|---|---|
| PickOne | 위치 기반 주변 식당, 거리·영업 중 필터, 방문 기록(별점·메모·사진) | 날씨 반영 없음, 기록이 추천에 반영되지 않음 |
| 뭐먹지? | 네이버 지도·카카오맵 연동, 제철 음식 추천 | 실시간 날씨가 아닌 계절 기준 |
| Selunch | 룰렛 UI, 추천 히스토리 | 위치 기반 아님 |
| 랜덤맛집 / 흥돌아 어디가까? | 원하지 않는 식당 제외 | 직접 일일이 제외해야 함, 지역 제한 |
| 오뭐먹? | 카드를 넘기는 게임형 UI | 기록·날씨 없음 |
| VibeEats (해외) | AI가 날씨·기분 반영 | 국내 데이터 없음 |

**차별점**
1. **날씨 + 방문 기록 + 주변 식당**을 한 번에 반영 (국내에서 이 조합을 갖춘 앱은 찾지 못함)
2. 최근 먹은 메뉴·식당을 **자동으로** 피함
3. **추천 이유를 문장으로** 보여줌
4. **달력**에 식사 기록이 쌓이고 언제든 다시 볼 수 있음

---

## 3. 요구사항

### 3.1 기능 요구사항

| ID | 기능 | 설명 | 단계 |
|---|---|---|---|
| F-01 | 현재 위치 | GPS 좌표, 권한 요청, 거부 시 위치 직접 설정 | 1차 |
| F-02 | 주변 음식점 목록 | 카카오 로컬로 **반경 1km** 음식점, 거리순 | 1차 |
| F-03 | 메뉴 분류 | 전체 / **한식 / 중식 / 일식 / 양식** 필터 | 1차 |
| F-04 | 식당 상세 | 식당 이름을 누르면 상세: 주소, 전화, 세부 분류, 거리, 지도, 내 방문 기록 | 1차 |
| F-05 | 외부 앱 연결 | 상세에서 **네이버 지도 앱**으로 열기·길찾기, 카카오 장소 페이지 보기 | 1차 |
| F-06 | 지도 보기 | 목록 ↔ 네이버 지도 전환, 분류별 색상 마커 | 1차 |
| F-07 | 식사 기록 | 날짜, 식당, 메뉴, 분류, 별점, 메모, 사진(선택) | 1차 |
| F-08 | 기록 달력 | 월간 달력에 방문 표시, 날짜별 기록 보기·수정·삭제 | 1차 |
| F-09 | 오늘의 추천 | 날씨·기록 반영 추천 1~3개 + **추천 이유** | 1차 |
| F-10 | 다른 추천 | 이번에 넘긴 식당은 빼고 다시 추천 | 1차 |
| F-11 | 추천 → 기록 | "여기로 결정" → 오늘 기록으로 저장 | 1차 |
| F-12 | 백업·복원 | 기록을 파일(JSON)로 내보내기·가져오기 | 1차 |
| F-13 | 제외·못 먹는 음식 | 안 갈 식당 숨기기, 못 먹는 음식 설정 | 1차 |
| F-14 | 통계 | 월별 분류 비율, 자주 간 식당 TOP 5 | 2차 |
| F-15 | 클라우드 동기화 | Firebase Auth 로그인 + Firestore 동기화 | 2차 |

### 3.2 비기능 요구사항
- **성능:** 주변 목록 3초 안에 표시 (캐시가 있으면 1초 안)
- **오프라인:** 기록·달력은 인터넷 없이 사용 가능
- **개인정보:** 위치와 기록은 기기에만 저장. 서버는 좌표를 저장하지 않음 (캐시 키는 약 1km 칸 단위로 뭉갠 값만 사용)
- **보안:** 카카오 REST 키·기상청 키는 Workers Secrets에만 보관. Workers가 Firebase App Check 토큰을 검증해 우리 앱의 요청만 받음. IP별 호출 제한
- **약관:** 카카오·네이버 출처 표시, 데이터 혼합 사용 가능 여부 확인 (11장 위험 요소)

---

## 4. 식당 데이터 설계 (네이버 + 카카오 혼합)

### 4.1 역할 분담

| 역할 | 사용 API | 비고 |
|---|---|---|
| 1km 안 음식점 목록 | 카카오 로컬 **카테고리 검색** (`FD6` 음식점, `x`, `y`, `radius=1000`) | 서버를 거쳐 호출 |
| 현재 위치 동 이름 | 카카오 로컬 **좌표→행정구역** (`coord2regioncode`) | 서버를 거쳐 호출 |
| 지도 표시·마커 | **네이버 지도 SDK** (`flutter_naver_map`) | 앱에서 직접 (Client ID만 앱에 넣음) |
| 상세 → 외부 앱 | 네이버 지도 URL 스킴 `nmap://place?lat=..&lng=..&name=..&appname=..` (앱이 없으면 네이버 지도 웹) / 카카오 `place_url` | 앱에서 직접 |

> 네이버 검색 API(지역)는 한 번에 5개만, 좌표 검색이 안 돼서 목록용으로 쓰지 않음.
> 2차에서 "네이버 블로그 리뷰 수" 같은 보조 정보가 필요하면 추가 검토.

### 4.2 카카오 카테고리 검색 제약과 대응
- 한 번의 검색 조건으로 받을 수 있는 결과: **페이지당 15개, 최대 45개** (3페이지)
- 번화가는 1km 안 음식점이 수백 개 → 45개로 부족
- **대응: 영역 분할**
  1. 1km 원을 감싸는 사각형을 **2×2 → 필요하면 3×3** 칸으로 나눔 (`rect` 파라미터)
  2. 한 칸의 결과가 45개를 넘으면(`is_end=false`) 그 칸만 다시 4등분 (최대 깊이 제한)
  3. 결과를 합쳐 `id`로 중복 제거 → 1km 밖은 버림
  4. 서버 캐시로 같은 지역은 다시 검색하지 않음
  5. **요청 1번당 외부 호출은 40번 이내**로 제한 (Workers 무료 요금제 상한 50번). 칸을 더 나눠야 하면 부족한 칸은 다음 요청에서 이어서 채움
- 정확한 파라미터 범위는 개발 0단계에서 공식 문서로 다시 확인

### 4.3 분류 규칙 (카카오 `category_name` 기준)
카카오는 `"음식점 > 한식 > 해장국"` 형태로 분류를 줌. 두 번째 단계로 4개 분류에 맞춤.

| 카카오 분류 | 앱 분류 |
|---|---|
| 한식, 분식, 간식(떡·한과 등) | **한식** |
| 중식 | **중식** |
| 일식 | **일식** |
| 양식, 패스트푸드, 치킨, 뷔페(양식) | **양식** |
| 아시아음식, 술집, 카페·간식 기타 | **기타** (전체 탭에서만 보임) |

세 번째 단계(예: `해장국`, `냉면`, `초밥`)는 **세부 메뉴 태그**로 저장해 날씨 추천에 사용.
매핑표는 서버가 아니라 앱 안의 설정 파일로 두어 쉽게 고칠 수 있게 함.

---

## 5. 기술 스택

| 구분 | 기술 |
|---|---|
| 앱 | Flutter 3.x (stable), Dart 3 |
| 상태 관리 | Riverpod |
| 화면 이동 | go_router (하단 탭 + 상세 화면) |
| 지도 | flutter_naver_map |
| 위치·권한 | geolocator, permission_handler |
| 로컬 DB | drift (SQLite) |
| 달력 | table_calendar |
| 사진 | image_picker (앱 폴더에 압축 저장) |
| 외부 앱 | url_launcher |
| 서버 통신 | dio + Firebase App Check |
| 서버 | **Cloudflare Workers** (TypeScript, 무료 요금제), 배포 도구 Wrangler |
| 서버 캐시 | **Cloudflare D1** (SQLite) + Workers Cache API |
| 서버 비밀값 | Workers Secrets (카카오 REST 키, 기상청 서비스 키) |
| 앱 인증 | Firebase App Check (Play Integrity / App Attest) → Workers에서 토큰 검증 |
| 날씨 | 기상청 단기예보 조회서비스 (공공데이터포털) — 초단기실황·초단기예보 |
| 미세먼지 (선택) | 에어코리아 대기오염정보 |
| 오류 수집 | Firebase Crashlytics |
| 빌드·배포 | Android: 로컬 빌드 → Play 내부 테스트 / iOS: 집 맥북 Xcode → TestFlight |

> Dart는 C#과 비슷함: 클래스, `async/await`, 제네릭, null 안전성(`String?`), 확장 메서드.

---

## 6. 시스템 구조

```
┌──────────────────── 모바일 앱 (Flutter) ────────────────────┐
│ 화면: 주변(목록/지도) · 추천 · 달력 · 설정 · 식당 상세 · 기록 입력 │
│ ─────────────────────────────────────────────────────────── │
│ LocationService     GPS, 권한                                 │
│ PlaceRepository     서버 호출, 거리 계산, 분류, 기기 캐시        │
│ WeatherRepository   서버 호출, 30분 캐시                        │
│ RecommendEngine     점수 계산 + 추천 이유 문장 생성 (기기 안에서) │
│ MealLogRepository   기록 CRUD, 백업·복원                         │
│ ─────────────────────────────────────────────────────────── │
│ SQLite: meal_logs, restaurants(캐시), recommendation_logs, settings │
│ 네이버 지도 SDK (Client ID)                                    │
└───────────────┬─────────────────────────────────────────────┘
                │ HTTPS + App Check 토큰
┌───────────────▼─────────────────────────────────────────────┐
│ Cloudflare Workers  (dinner-api, 무료 요금제)                  │
│  GET /places   lat,lng,radius → 1km 음식점 목록 (영역 분할 검색) │
│  GET /region   lat,lng → 동 이름                               │
│  GET /weather  lat,lng → 기온, 강수, 하늘 상태, (미세먼지)       │
│  - API 키는 Workers Secrets에 보관                              │
│  - App Check 토큰 검증 (Google 공개키로 JWT 확인)                │
│  - D1(SQLite) 캐시: 식당은 geohash 6자리 칸 단위 24시간,          │
│                     날씨는 기상청 격자 단위 30분                 │
│  - IP별 호출 제한, 요청 좌표는 로그·DB에 남기지 않음               │
└──────┬──────────────────────────┬───────────────────────────┘
       ▼                          ▼
  카카오 로컬 API              기상청 단기예보 API

┌──────────── Firebase (Spark 무료 요금제) ────────────┐
│ App Check   앱이 진짜인지 확인 → 토큰 발급 (앱에서 사용) │
│ Crashlytics 앱 오류 수집                              │
└─────────────────────────────────────────────────────┘
```

**추천 계산은 기기 안에서** 함. 방문 기록이 기기에만 있으므로 서버에 보낼 필요가 없음.

### 6.1 비용 (예상 0원)

| 서비스 | 요금제 | 무료 한도 (2026년 기준, 시작 전 공식 문서 재확인) | 예상 사용량 |
|---|---|---|---|
| Cloudflare Workers | 무료 | 하루 요청 10만 회, 요청당 CPU 10ms, 요청당 외부 호출 50번 | 사용자 100명 × 하루 10회 = 1,000회 (약 1%) |
| Cloudflare D1 | 무료 | 하루 읽기·쓰기 수백만 행 수준 | 매우 적음 |
| Firebase App Check · Crashlytics | Spark (무료) | 무료 | — |
| 도메인 | 선택 | `*.workers.dev` 주소를 무료로 제공 | 나중에 회사 도메인 연결 가능 |

- 무료 한도를 넘으면 **요청이 실패할 뿐 요금이 청구되지 않음** (카드 등록 없음)
- 사용자가 늘어 한도가 부족해지면 Workers 유료 요금제(월 5달러)로 전환
- CPU 10ms에는 외부 API 응답을 **기다리는 시간은 포함되지 않음** → 중계 작업에는 충분할 것으로 예상, 0단계에서 실측

### 6.2 이 구성을 고른 이유
- 1차 범위의 서버는 키 보관 + 캐시 + 중계만 하므로 가벼운 Workers로 충분
- 비용 0원, 요금 폭증 위험 없음, 콜드 스타트 거의 없음
- 앱은 서버 주소만 설정값으로 가지고 있어 나중에 Firebase Functions나 사내 서버로 옮기기 쉬움
- 2차의 로그인·동기화는 Firebase Auth + Firestore를 추가 (같은 Firebase 프로젝트 사용)

---

## 7. 프로젝트 구조

```
DinnerDecision/
├─ app/                          # Flutter 앱
│  ├─ lib/
│  │  ├─ main.dart
│  │  ├─ app/                    # 라우터, 테마, 공통 위젯
│  │  ├─ core/                   # 거리 계산, 시간, 오류 처리, 설정 파일
│  │  ├─ data/
│  │  │  ├─ db/                  # drift 테이블, DAO
│  │  │  ├─ api/                 # 서버 API 클라이언트
│  │  │  └─ repositories/
│  │  ├─ domain/
│  │  │  ├─ models/              # Restaurant, MealLog, Weather, Recommendation
│  │  │  └─ recommend/           # 점수 규칙, 이유 문장 생성
│  │  └─ features/
│  │     ├─ nearby/              # 주변 목록·지도
│  │     ├─ restaurant_detail/
│  │     ├─ recommend/
│  │     ├─ calendar/
│  │     ├─ meal_log_edit/
│  │     └─ settings/
│  ├─ assets/config/cuisine_mapping.json, weather_rules.json
│  └─ test/
├─ server/                       # Cloudflare Workers (TypeScript)
│  ├─ src/
│  │  ├─ index.ts                # 라우팅, 공통 오류 처리
│  │  ├─ routes/ places.ts, region.ts, weather.ts
│  │  └─ lib/ kakao.ts, kma.ts, kmaGrid.ts, geohash.ts,
│  │          cache.ts, appCheck.ts, rateLimit.ts
│  ├─ migrations/0001_init.sql   # D1 캐시 테이블
│  ├─ test/
│  └─ wrangler.toml              # Workers·D1 설정 (비밀값은 넣지 않음)
└─ docs/ PLAN.md, UI_PLAN.md
```

---

## 8. 데이터 모델 (기기 SQLite)

```text
restaurants (식당 캐시)
 ├ id              TEXT PK      카카오 장소 id
 ├ name            TEXT
 ├ category_raw    TEXT         "음식점 > 한식 > 해장국"
 ├ cuisine         TEXT         KOREAN | CHINESE | JAPANESE | WESTERN | ETC
 ├ tags            TEXT         세부 메뉴 태그 (JSON 배열, 예: ["해장국","국물"])
 ├ address, road_address, phone
 ├ lat, lng        REAL
 ├ kakao_url       TEXT
 ├ is_excluded     BOOL         안 갈 식당
 └ updated_at

meal_logs (식사 기록)
 ├ id              INTEGER PK
 ├ date            DATE         달력 기준
 ├ meal_type       TEXT         DINNER(기본) | LUNCH | ETC
 ├ restaurant_id   TEXT NULL    집밥·배달이면 비어 있음
 ├ restaurant_name TEXT         식당 정보가 바뀌어도 남도록 복사
 ├ cuisine, menu
 ├ rating          INTEGER 1~5
 ├ memo, photo_path
 ├ weather_text    TEXT         "비 · 9℃"
 ├ from_recommend  BOOL
 └ created_at, updated_at

recommendation_logs (추천 기록)
 ├ id, created_at, restaurant_id, score, reasons(JSON)
 └ result          SHOWN | SKIPPED | ACCEPTED

settings
 ├ radius_m (1000), avoid_restaurant_days (7), avoid_cuisine_streak (2)
 ├ disliked_tags (JSON), default_meal_type
 └ theme (system | light | dark)
```

백업 파일: 위 테이블을 JSON 하나로 묶고 사진은 zip으로 함께 내보냄 → 공유 시트로 저장(드라이브, 카톡 나에게 보내기 등).

---

## 9. 추천 알고리즘

### 9.1 흐름
1. 1km 안 후보 식당 (제외 식당, 못 먹는 음식 태그 제외, 분류가 `기타`인 곳은 설정에 따라)
2. 현재 날씨 (기온, 강수 형태, 하늘, 선택: 미세먼지)
3. 최근 14일 기록
4. 후보별 점수 계산 → **상위 10개 중 가중 랜덤으로 3개** (1개는 크게, 2개는 작게 표시)
5. 점수에 영향을 준 요인 → **이유 문장** (최대 4줄)

### 9.2 점수표 (합계 100점, 테스트하며 조정)

| 요인 | 배점 | 규칙 |
|---|---|---|
| 식당 다양성 | 0~30 | 최근 7일 안에 간 식당은 **후보에서 제외**, 8~14일은 감점, 처음 가는 곳 +가산 |
| 분류 다양성 | 0~20 | 최근 2번 연속 같은 분류면 그 분류 크게 감점 |
| 메뉴 다양성 | 0~10 | 어제·그제 먹은 세부 메뉴 태그와 같으면 감점 |
| 날씨 적합도 | 0~25 | 날씨 규칙표 (9.3) |
| 거리 | 0~10 | 가까울수록 가산. 비·눈이 오면 거리 배점 2배 |
| 만족도 | 0~5 | 예전에 별점 4점 이상 준 곳 (14일 지난 경우) |

후보가 너무 적으면(예: 5개 미만) 제외 조건을 7일 → 3일로 줄이고 화면에 알려줌.

### 9.3 날씨 규칙 (`weather_rules.json`)

| 조건 | 점수 오르는 태그 | 이유 문장 예 |
|---|---|---|
| 비·눈 | 국밥, 찌개, 칼국수, 짬뽕, 라멘, 전 | "☔ 비가 와서 따뜻한 국물 요리를 골랐어요" |
| 5℃ 이하 | 탕, 전골, 샤브샤브, 마라탕 | "🥶 2℃로 추워서 뜨끈한 전골을 추천해요" |
| 28℃ 이상 | 냉면, 소바, 초밥, 물회, 샐러드 | "🥵 31℃라 시원한 냉면이 좋겠어요" |
| 맑음 15~25℃ | 처음 가는 곳·조금 먼 곳 가산 | "🌤 걷기 좋은 날씨라 조금 먼 새 맛집이에요" |
| 미세먼지 나쁨 | 가까운 곳 가산 | "😷 미세먼지가 나빠서 가까운 곳이에요" |

### 9.4 이유 문장 만들기
- 각 규칙이 점수와 함께 **이유 코드**를 남김 (`WEATHER_RAIN`, `CUISINE_ROTATE`, `NEW_PLACE`, `NEAR` …)
- 점수 기여가 큰 순서로 최대 4개를 문장 틀에 값을 넣어 표시
- 1차는 규칙 기반 문장만 사용 (오프라인·무료·결과가 예측 가능)

---

## 10. 개발 환경과 iOS 빌드 계획

| 작업 | 장소 | 도구 |
|---|---|---|
| 앱 개발·Android 테스트 | 회사 Windows PC | VS Code 또는 Android Studio, Android 실기기 |
| 서버 개발 | 회사 Windows PC | Node.js LTS, Wrangler CLI (`wrangler dev`로 로컬 실행, 로컬 D1) |
| iOS 빌드·테스트 | **집 맥북** | Xcode, CocoaPods, iPhone 실기기 |

**iOS 진행 방식**
- 0단계에서 집 맥북으로 **iOS 첫 빌드를 한 번 성공**시켜 둠 (네이버 지도 SDK, 권한 설정 확인)
- 이후 **단계가 끝날 때마다** 맥북에서 빌드·실기기 확인 (최소 2주에 1번)
- iOS 전용 설정은 미리 넣어 둠: `Info.plist` 위치 권한 문구, `LSApplicationQueriesSchemes`에 `nmap`, `kakaomap`
- TestFlight 배포에는 **Apple Developer Program 가입(연 99달러)** 필요
- 맥북 사용이 어려워지면 **Codemagic** 같은 클라우드 빌드로 대체 가능
- 확인할 것: 맥북의 macOS 버전이 최신 Xcode를 지원하는지

---

## 11. 개발 일정 (1인 기준, 약 11주)

| 단계 | 기간 | 내용 | 완료 기준 |
|---|---|---|---|
| 0. 준비 | 1주 | 키 발급(카카오, Naver Cloud 지도, 공공데이터포털), Cloudflare 계정·Workers 첫 배포, **Workers에서 카카오·기상청 호출 테스트**, Firebase 프로젝트(Spark)·App Check·Crashlytics, Flutter 프로젝트 생성, **집 맥북 iOS 첫 빌드** | 두 플랫폼에서 빈 앱 + 네이버 지도 표시, Workers에서 외부 API 응답 확인 |
| 1. UI 뼈대 | 1주 | 테마, 하단 탭, 공통 컴포넌트, 화면 틀(가짜 데이터) | 모든 화면 이동 가능 |
| 2. 서버 + 주변 목록 | 2주 | Workers `/places` 영역 분할 검색·D1 캐시·App Check 검증·호출 제한, `/region`, 앱 목록·분류 필터·거리 | F-01~03 |
| 3. 지도·상세 | 1.5주 | 지도 마커, 상세 화면, 네이버 지도 앱 연결 | F-04~06 |
| 4. 기록·달력 | 2주 | drift DB, 기록 입력·수정·삭제, 달력, 백업·복원, 제외 설정 | F-07, 08, 12, 13 |
| 5. 날씨·추천 | 2주 | `/weather`(격자 변환), 점수 엔진, 이유 문장, 다른 추천, 결정→기록 | F-09~11 |
| 6. 안정화·배포 | 1.5주 | 오류·권한 처리, 실기기 테스트, 개인정보처리방침, 아이콘·스크린샷 | Play 내부 테스트 + TestFlight |

**마일스톤**
- M1 (2주차): 화면 이동이 되는 UI 데모
- M2 (4주차): 실제 주변 식당 목록
- M3 (6주차): 지도·상세 완성
- M4 (8주차): 기록·달력 완성
- M5 (10주차): 추천 완성
- M6 (11주차): 베타 배포

---

## 12. 위험 요소와 대응

| 위험 | 대응 |
|---|---|
| **카카오 데이터를 네이버 지도 위에 표시하는 것이 약관상 허용되는지** | 0단계에서 카카오·네이버 약관 확인. 문제가 되면 지도도 카카오맵으로 바꿀 수 있게 지도 부분을 분리 |
| 카카오 검색 45개 제한 | 영역 분할 검색 + 캐시 |
| 카카오 일일 호출 한도 | 서버 캐시(칸 단위 24시간), 사용자별 호출 제한 |
| `flutter_naver_map`이 비공식 패키지 | 버전 고정, 지도 위젯을 감싸서 교체 가능하게 |
| 날씨 API 장애 | 날씨 없이 다양성·거리로만 추천, "날씨 정보 없음" 표시 |
| Workers 무료 한도 (CPU 10ms, 요청당 외부 호출 50번) | 0단계에서 실측, 칸 분할 상한 40번, 부족하면 월 5달러 유료 요금제 |
| Workers(해외 거점 포함)에서 국내 공공 API 호출이 막히거나 느릴 가능성 | 0단계에서 확인. 문제가 되면 해당 API만 다른 경로(사내 Synology 컨테이너 등)로 분리 |
| 악성·과다 호출 | App Check 토큰 검증, IP별 호출 제한. 무료 요금제라 요금 폭증은 없음 (대신 한도 초과 시 서비스 중단 → 모니터링) |
| iOS 빌드를 집에서만 할 수 있음 | 단계마다 정기적으로 빌드, iOS 설정을 미리 반영, 필요하면 Codemagic |
| 위치정보·개인정보 | 좌표 미저장, 개인정보처리방침, 권한 사용 이유 문구 |

---

## 13. 2차 이후 기능
- 클라우드 동기화(Firebase Auth + Firestore, 무료 범위에서 시작), 여러 기기 사용
- 통계 화면 (월별 분류 비율, 자주 간 곳)
- 같이 먹을 사람과 투표로 결정
- 가격대 필터, 영업 중만 보기
- LLM으로 자연스러운 추천 문장
- 홈 화면 위젯 "오늘의 추천"
- 점심/저녁 따로 추천

---

## 14. 0단계 준비물 체크리스트
- [ ] 카카오 디벨로퍼스 앱 생성 → REST API 키 (서버용)
- [ ] Naver Cloud Platform → Maps (Mobile Dynamic Map) Client ID, 앱 패키지명·번들 ID 등록
- [ ] 공공데이터포털 → 기상청 단기예보 조회서비스 활용 신청 (선택: 에어코리아)
- [ ] Cloudflare 계정 → Workers, D1 생성, Wrangler 로그인
- [ ] Firebase 프로젝트 (**Spark 무료 요금제**), App Check (Play Integrity / App Attest), Crashlytics
- [ ] 앱 패키지명 결정 (예: `kr.naturetec.dinnerdecision`)
- [ ] 집 맥북: Xcode, CocoaPods, Flutter 설치, iPhone 개발자 모드
- [ ] Apple Developer Program 가입 (TestFlight 단계 전까지)
- [ ] 카카오·네이버 약관 확인 (12장 첫 번째 위험)

---

## 참고 자료
- 카카오 로컬 API: https://developers.kakao.com/docs/latest/ko/local/dev-guide
- flutter_naver_map: https://pub.dev/packages/flutter_naver_map
- 네이버 지도 URL 스킴: https://guide.ncloud-docs.com/docs/maps-url-scheme
- 기상청 단기예보 조회서비스: https://www.data.go.kr/data/15084084/openapi.do
- Cloudflare Workers 한도: https://developers.cloudflare.com/workers/platform/limits/
- Cloudflare Workers 요금: https://developers.cloudflare.com/workers/platform/pricing/
- Cloudflare D1: https://developers.cloudflare.com/d1/
- Firebase App Check (자체 서버에서 토큰 검증): https://firebase.google.com/docs/app-check/custom-resource-backend
- Firebase 요금: https://firebase.google.com/pricing
