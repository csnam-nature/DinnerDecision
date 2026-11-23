# 오늘 저녁 뭐 먹지 (DinnerDecision) — 개발 계획서

> 버전 1.0 · 작성일 2026-11-23 · 상태: 6단계(안정화·배포) 진행 중 — Crashlytics·App Check 코드 반영
> UI 상세 설계는 [`UI_PLAN.md`](./UI_PLAN.md) 참고
> 진행 기록·명령어 모음(복습·재현용)은 [`PROGRESS.md`](./PROGRESS.md), 출시 절차는 [`RELEASE.md`](./RELEASE.md)

## 변경 이력
| 버전 | 내용 |
|---|---|
| 0.1 | 초안 (요구사항, 유사 앱 분석, 대안 비교) |
| 0.2 | 결정 사항 반영: Flutter, 네이버+카카오 혼합, Firebase Functions, 기기에만 저장, iOS는 집 맥북으로 빌드 |
| 0.3 | 중계 서버를 **Cloudflare Workers(무료)** 로 변경, Firebase는 **무료 요금제(Spark)** 로 App Check·Crashlytics만 사용 |
| 0.4 | `app/`에 Flutter 뼈대 추가. Flutter 3.50 기준(`material_ui`), 달력은 직접 만든 위젯으로 변경, 앱 ID `kr.naturetec.dinnerdecision` 확정 |
| 1.0 | 6단계 시작: Firebase 프로젝트, Crashlytics·App Check 코드, 서버 App Check `monitor`. 세부 일정 11.5 |
| 0.9 | 5단계: 서버 `/weather`(기상청 격자 변환, 20분 캐시), 앱 날씨 연결, 날씨 없이도 추천, '구름많음' 하늘 상태, 미세먼지는 '모름'으로 두고 다음으로 미룸. 세부 일정 11.4 |
| 0.8 | 4단계 코드 반영: 기기 DB(drift), 사진, 백업·복원(zip), 첫 실행 안내. 설계 결정: 앱을 켤 때 DB를 한 번 읽어 메모리에 올리고 바뀔 때마다 바로 저장(화면 코드는 그대로), 식당 정보는 JSON 한 칸으로 저장, 지운 기록의 사진은 '되돌리기' 때문에 다음 실행 때 정리 |
| 0.7 | 3단계 실기기 확인 완료. 4단계 세부 일정 추가(11.3) |
| 0.6 | App Check(앱 인증)를 2단계 → **6단계**로 이동 (외부 배포 때 효과가 생기고 Play 배포·Apple 가입과 함께 하는 편이 효율적). 3단계 세부 일정 추가(11.2) |
| 0.5 | `server/`에 Workers 추가(`/places`, `/region`, `/search`, App Check 검증, 호출 제한, D1 캐시). 캐시 칸을 geohash 6자리 고정 → **geohash 5자리 + 4등분 반복**으로 변경(4.2). 앱에 GPS·서버 연결. 2단계 세부 일정 추가(11.1) |

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
- **개인정보:** 위치와 기록은 기기에만 저장. 앱은 서버로 위경도를 **약 100m 단위로 줄여** 보내고(정확한 거리는 기기에서 계산), 서버는 요청 좌표를 저장·기록하지 않음. Cloudflare의 요청 기록(invocation logs)도 끔. 캐시는 위치와 무관한 고정 칸 단위로 식당 정보만 저장, IP는 해시해서 1분 호출 횟수만 저장
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
- **대응: 영역 분할** (0.5에서 구현, `server/src/lib/placeSearch.ts`)
  1. 지도를 사용자 위치와 무관한 **고정 칸(geohash 5자리, 약 4km)** 으로 나누고, 반경 원에 걸치는 칸만 검색 (`rect` 파라미터)
  2. 한 칸의 결과(`total_count`)가 45개를 넘으면 그 칸만 4등분해서 다시 검색 (최대 6단계, 약 60m 칸)
  3. 결과를 합쳐 `id`로 중복 제거 → 반경 밖은 버림
  4. 칸별 결과를 D1에 24시간 저장. 칸이 고정이라 **같은 동네 사용자끼리 캐시를 나눠 씀**, 요청 좌표는 저장하지 않음
  5. **요청 1번당 외부 호출은 40번 이내** (Workers 무료 요금제 상한 50번). 가까운 칸부터 채우고, 남은 칸은 `complete:false`로 알려 다음 요청에서 이어서 채움 (앱이 최대 4번 자동 재요청)
  - 테스트 기준: 반경 안 약 140곳 → 1번 요청(31회 호출), 약 700곳 → 4번 요청(약 120회 호출), 이후 24시간은 호출 0회
- 정확한 파라미터 범위(`rect` 최대 크기, `total_count` 상한)는 0단계에서 실제 키로 다시 확인

### 4.3 분류 규칙 (카카오 `category_name` 기준)
카카오는 `"음식점 > 한식 > 해장국"` 형태로 분류를 줌. 두 번째 단계로 4개 분류에 맞춤.

| 카카오 분류 | 앱 분류 |
|---|---|
| 한식, 분식, 간식(떡·한과 등) | **한식** |
| 중식 | **중식** |
| 일식 | **일식** |
| 양식, 패스트푸드, 치킨, 샐러드 | **양식** |
| 아시아음식, 술집, 카페·간식 기타 | **기타** (전체 탭에서만 보임) |

세 번째 단계(예: `해장국`, `냉면`, `초밥`)는 **세부 메뉴 태그**로 저장해 날씨 추천에 사용.

**실제 응답에서 확인한 점 (2026-11-19, 성수동 주변 89곳)**
- 세 번째 단계 이후에 세부 분류 대신 **가게 이름(프랜차이즈)** 이 오기도 함: `패스트푸드 > 롯데리아`, `한식 > 국밥 > 완산골명가`, `치킨 > 맛닭꼬`
  → 아는 세부 분류 목록(`categories`)에 있거나 쉼표가 들어간 이름(`육류,고기`)만 분류로 보고, 처음 나온 모르는 이름부터는 버림. 모르는 세부 분류는 한 단계 위 분류로 표시됨
- 두 번째 단계만 있는 곳이 많음 (`음식점 > 한식` 17곳) → 화면에는 `한식`만 표시
- `샐러드`가 두 번째 단계로 옴 → 양식. 베이커리·술집·아시아음식은 계획대로 기타
매핑표는 서버가 아니라 앱 안의 설정 파일로 두어 쉽게 고칠 수 있게 함.

---

## 5. 기술 스택

| 구분 | 기술 |
|---|---|
| 앱 | Flutter 3.50 (stable), Dart 3.14. Material 위젯은 `material_ui` 패키지에서 가져옴 (`package:flutter/material.dart`는 3.47부터 지원 종료 예고) |
| 상태 관리 | Riverpod |
| 화면 이동 | go_router (하단 탭 + 상세 화면) |
| 지도 | flutter_naver_map |
| 위치·권한 | geolocator, permission_handler |
| 로컬 DB | drift (SQLite) |
| 달력 | 직접 만든 월 달력 위젯 (`table_calendar`는 아직 `material_ui`로 옮겨오지 않아 함께 쓸 수 없음) |
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
│  GET /search   query → 주소·장소 검색 (위치 직접 설정)           │
│  GET /weather  lat,lng → 기온, 강수, 하늘 상태, (미세먼지)       │
│  - API 키는 Workers Secrets에 보관                              │
│  - App Check 토큰 검증 (Google 공개키로 JWT 확인)                │
│  - D1(SQLite) 캐시: 식당은 geohash 5자리 칸(+4등분) 단위 24시간,  │
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
│  │  ├─ index.ts                # Workers 진입점
│  │  ├─ app.ts                  # 라우팅, App Check, 호출 제한, 공통 오류 처리
│  │  ├─ routes/ places.ts, region.ts, search.ts, (weather.ts: 5단계)
│  │  └─ lib/ kakao.ts, placeSearch.ts, geohash.ts, geo.ts,
│  │          cellStore.ts, appCheck.ts, rateLimit.ts, (kma.ts, kmaGrid.ts: 5단계)
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
| 6. 안정화·배포 | 1.5주 | 오류·권한 처리, 실기기 테스트, 개인정보처리방침, 아이콘·스크린샷, **Firebase(Spark) App Check·Crashlytics 연결 후 서버 `APP_CHECK_MODE` monitor → enforce** | Play 내부 테스트 + TestFlight |

### 11.1 2단계 세부 일정 (서버 + 주변 목록, 2주)

| 주차 | 작업 | 상태 |
|---|---|---|
| 1주차 | Workers 프로젝트(`server/`), 카카오 클라이언트, 영역 분할 검색, D1 칸 캐시·만료 정리(cron) | ✅ 코드·테스트 완료 |
| 1주차 | `/region`(동 이름), `/search`(위치 직접 설정), IP별 호출 제한, App Check 토큰 검증(off/monitor/enforce) | ✅ 코드·테스트 완료 |
| 1주차 | 앱: 서버 클라이언트(dio), `ApiPlaceRepository`, 서버 주소 없으면 예시 데이터로 동작 | ✅ 코드·테스트 완료 |
| 2주차 | 앱: GPS(geolocator)·권한 처리, 위치 검색 화면, 오류 안내(위치·인터넷·호출 제한) | ✅ 코드·테스트 완료 |
| 2주차 | **0단계 준비물로 실제 연결**: 카카오 REST 키(카카오맵 사용 설정 ON), Cloudflare 계정·D1 생성, 첫 배포 | ✅ 2026-11-19 배포, Android 실기기(SM-G981N)에서 GPS·동 이름·주변 목록 확인 |
| 2주차 | 실제 카카오 분류로 `cuisine_mapping.json` 보정 (가게 이름 거르기, 샐러드·라멘·우동·회 등 태그) | ✅ 실제 분류 42개를 테스트로 고정 |
| 2주차 | CPU 10ms·호출 수 실측 | ⏳ Cloudflare 대시보드 확인 |
| — | Firebase(Spark)·App Check | ➡️ 6단계로 이동 (서버 검증 코드는 완성, `APP_CHECK_MODE=off`) |
| 2주차 | 집 맥북 iOS 빌드 (위치 권한 문구 확인) | ⏳ |

2단계 완료 기준(F-01~03): 실제 위치에서 1km 안 음식점이 3초 안에 분류별로 보임. → ✅ 2026-11-19 Android 실기기 확인

### 11.2 3단계 세부 일정 (지도·상세, 1.5주)

| 순서 | 작업 | 필요한 것 |
|---|---|---|
| 1 | 외부 앱 연결(F-05): 네이버 지도 앱 장소·도보 길찾기(앱 없으면 네이버 지도 웹), 카카오 장소 페이지, 전화 걸기 (`url_launcher`) | ✅ 코드·테스트 완료 |
| 2 | 네이버 지도 연결(F-06): `AppMapView` 안쪽을 `flutter_naver_map`으로. 분류별 색 마커, 내 위치, 반경 원, 마커 누르면 미리보기. Client ID가 없으면 그림 지도로 동작 | ✅ 완료 |
| 3 | 식당 상세(F-04) 다듬기: 전화번호 없는 곳은 숨김, 주소 눌러 복사, 카카오 주소 없는 곳은 카카오 버튼 숨김 | ✅ 코드·테스트 완료 |
| 4 | 실기기 확인: 지도 표시·마커·외부 앱 연결 | ✅ 2026-11-19 Android 실기기 확인 |
| 5 | 약관 확인: 카카오 장소 데이터를 네이버 지도 위에 표시해도 되는지 (12장 첫 번째 위험) | ⏳ 사용자 확인 (6단계 배포 전까지) |

참고: `flutter_naver_map` 1.4.4는 예전 `package:flutter/material.dart`를 씀. 지도 본체는 문제없으나 **로고를 누르면 뜨는 정보 창**은 `material_ui` 앱에서 동작하지 않을 수 있어 로고 누르기를 끄고(`logoClickEnable: false`), 네이버 지도 출처는 설정 화면에 표시.

### 11.3 4단계 세부 일정 (기록·달력, 2주)

| 순서 | 작업 | 기능 |
|---|---|---|
| 1 | 기기 DB(drift, SQLite): 식사 기록·설정·숨긴 식당 테이블과 버전 관리(마이그레이션) | F-07 · ✅ |
| 2 | 지금 메모리에만 있는 기록·설정·숨긴 식당을 DB에 저장 → 앱을 꺼도 남음. 첫 실행이면 온보딩 자동 표시 | F-07, F-13 · ✅ |
| 3 | 기록 입력·수정·삭제 완성, 사진 첨부(긴 변 1600px·화질 80%로 줄여 앱 폴더에 저장) | F-07 · ✅ |
| 4 | 달력을 DB 기록과 연결, 지난 식당 상세는 기록에 저장해 둔 정보로 보여주기 | F-08 · ✅ |
| 5 | 백업·복원: 기록을 파일(JSON + 사진 zip)로 내보내기(공유 시트) · 가져오기 | F-12 · ✅ |
| 6 | 실기기 확인: 앱 재시작 후 기록 유지, 사진, 백업 파일로 복원 | ⏳ 사용자 확인 · 복원은 알려진 문제(아래) |

**알려진 문제: 백업 복원 (나중에 다시 확인)**
- 백업 파일 만들기는 성공. 만든 파일(기록 2건, 사진 1장)은 앱의 복원 코드와 테스트로 정상 복원됨
- 삼성 휴대폰에서 파일 선택 창의 '다운로드' 메뉴로 고르면 시스템 미디어 저장소가 접근을 거부함(SecurityException) → '내 휴대폰 › Download' 경로로 고르도록 안내 추가
- 그 경로로 골라 압축 풀기까지는 됐으나 복원이 끝나지 않음. 원인 미확인 (다음 확인 때 오류 창 내용·`adb logcat` 필요)
- 대안: '내 파일'에서 백업 파일을 공유 → 이 앱으로 바로 복원 (파일 선택 창을 거치지 않음, Android 코드 추가 필요)

예시 데이터 모드(서버 주소 없음)에서는 지금처럼 예시 기록을 보여주고, 서버 모드에서는 빈 기록에서 시작한다.

### 11.4 5단계 세부 일정 (날씨·추천, 2주)

| 순서 | 작업 | 상태 |
|---|---|---|
| 1 | 서버 `/weather`: 위경도 → 기상청 격자, 초단기실황(기온·강수·1시간 강수량·습도) + 초단기예보(하늘 상태), 발표 직후 자료 없으면 한 시간 전 자료, 격자별 20분 D1 캐시 | ✅ 코드·테스트 |
| 2 | 앱 날씨 연결: `ApiWeatherRepository`(15분 캐시), 못 받으면 '날씨 정보 없음'으로 두고 날씨 점수 없이 추천 | ✅ 코드·테스트 |
| 3 | 하늘 상태 '구름많음' 추가(걷기 좋은 날에 포함), 미세먼지는 모르면 표시하지 않음 | ✅ |
| 4 | 기상청 키 등록·배포, 실제 날씨에서 추천·이유 문장 확인 | ✅ 2026-11-19 실기기 확인 (서울 맑음 0℃) |
| 5 | (선택) 미세먼지: 에어코리아 측정소 조회 → `dust` | ⏳ 다음으로 미룸 (TM 좌표 변환·측정소 조회가 필요해 별도 작업) |
| 6 | (선택) 추천 기록(recommendation_logs): 넘긴·고른 식당 저장 | ⏳ 2차로 미룸 (지금은 한 번 추천하는 동안만 넘긴 식당을 뺌) |

### 11.5 6단계 세부 일정 (안정화·배포, 1.5주)

| 순서 | 작업 | 누가 | 상태 |
|---|---|---|---|
| 6-1 | Firebase 프로젝트(Spark, 애널리틱스 끔), `flutterfire configure`, 디버그 키 SHA-256 등록 | 사용자 | ✅ 프로젝트 `dinnerdecision-ca59c`, Android·iOS 앱 등록, 설정 파일 커밋 (iOS plist는 6-7에서) |
| 6-2 | Crashlytics: 처리하지 못한 오류·시작 실패·백업 오류 보고, 디버그 빌드는 시험 오류만 | 코드 | ✅ 실기기에서 시험 오류 확인 |
| 6-3 | App Check: 디버그 토큰 / Play Integrity / App Attest, 토큰을 서버 요청 헤더에, 서버 `APP_CHECK_MODE=monitor` | 코드 | ✅ 실기기에서 `appCheck: ok` 확인 |
| 6-3a | 개인정보: 요청 주소에 정확한 좌표가 Cloudflare 로그로 남던 문제 → 앱이 좌표를 약 100m 단위로 줄여 보냄(반경 +100m로 받고 기기에서 정확히 거름), 서버 요청 기록(invocation logs) 끔 | 코드 | ✅ 실기기 확인 |
| 6-4 | 출시 준비: 아이콘, 서명 설정, 개인정보처리방침(`/privacy`), 스토어 문안·그래픽, 데이터 보안 양식 답안 ([`RELEASE.md`](./RELEASE.md)) | 함께 | ✅ 준비 완료 · ⏳ 서명 키 만들기, 방침 운영자·연락처, 스크린샷 |
| 6-5 | Play 내부 테스트, Play 앱 서명 SHA-256 등록 → 서버 `enforce` | 사용자 → 코드 | ⏳ (Play 개발자 계정 필요) |
| 6-6 | 백업 복원 문제, 약관 확인, CPU 실측 | 함께 | ⏳ |
| 6-7 | iOS 빌드(맥북에서 `flutterfire configure` 다시 실행해 plist 생성) → TestFlight | 사용자 | ⏳ |

**마일스톤**
- M1 (2주차): 화면 이동이 되는 UI 데모 ✅
- M2 (4주차): 실제 주변 식당 목록 ✅
- M3 (6주차): 지도·상세 완성 ✅
- M4 (8주차): 기록·달력 완성 ✅ (백업 복원은 알려진 문제)
- M5 (10주차): 추천 완성 ✅
- M6 (11주차): 베타 배포

---

## 12. 위험 요소와 대응

| 위험 | 대응 |
|---|---|
| **카카오 데이터를 네이버 지도 위에 표시하는 것이 약관상 허용되는지** | 0단계에서 카카오·네이버 약관 확인. 문제가 되면 지도도 카카오맵으로 바꿀 수 있게 지도 부분을 분리 |
| 카카오 검색 45개 제한 | 영역 분할 검색 + 캐시 |
| 카카오 일일 호출 한도 | 서버 캐시(칸 단위 24시간), 사용자별 호출 제한 |
| `flutter_naver_map`이 비공식 패키지 | 버전 고정, 지도 위젯을 감싸서 교체 가능하게 |
| 패키지가 Flutter 3.50의 `material_ui`를 아직 지원하지 않을 수 있음 (`table_calendar`에서 실제로 겪음) | 패키지를 넣기 전에 `material_ui` 지원 여부 확인. `flutter_naver_map`은 3단계 시작 전에 먼저 붙여 봄. 안 되면 직접 만들거나 다른 패키지 사용 |
| `flutter_naver_map` 1.4.4가 예전 material 사용 | 지도 본체는 문제없음. 로고를 눌렀을 때 뜨는 정보 창만 맞지 않아 로고 누르기를 끔 (3단계에서 확인) |
| 패키지 업데이트로 Android에서만 생기는 오류 (실제 사례: `path_provider_android` 2.3.x + `jni` 1.2.0 → 앱 폴더를 못 찾아 시작 실패) | `pubspec.yaml`의 `dependency_overrides`로 검증된 버전 고정. 시작 실패 시 오류 화면과 단계별 로그(`[시작]`)로 원인 확인 |
| **위치정보법**: 이용자 위치로 서비스를 제공하면 위치기반서비스사업 신고 대상일 수 있음 | 공개 출시 전에 방송통신위원회·KISA 위치정보지원센터 안내로 신고 대상 여부 확인 (RELEASE.md 7장) |
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
- [x] 카카오 디벨로퍼스 앱 생성 → REST API 키 (서버용), **[제품 설정] → [카카오맵] 사용 설정 ON**
- [x] Naver Cloud Platform → Maps (Mobile Dynamic Map) Client ID, 앱 패키지명·번들 ID 등록
- [ ] 공공데이터포털 → 기상청 단기예보 조회서비스 활용 신청 (선택: 에어코리아)
- [x] Cloudflare 계정 → Workers, D1 생성, Wrangler 로그인
- [ ] Firebase 프로젝트 (**Spark 무료 요금제**), App Check (Play Integrity / App Attest), Crashlytics
- [x] 앱 패키지명: `kr.naturetec.dinnerdecision` (Android·iOS 같음). 네이버 지도·Firebase에 이 이름으로 등록
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
