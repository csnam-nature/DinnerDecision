# 진행 기록과 명령어 모음 (복습·재현용)

> 작성일 2026-11-19 · 기준: `main` 5단계 머지 후 (`5f9f145`)
> 계획은 [`PLAN.md`](./PLAN.md), 화면 설계는 [`UI_PLAN.md`](./UI_PLAN.md),
> 서버 상세는 [`../server/README.md`](../server/README.md), 앱 상세는 [`../app/README.md`](../app/README.md)

이 문서는 지금까지 한 일을 **처음부터 다시 따라 할 수 있게** 순서대로 적은 것입니다.
명령은 Windows PowerShell 기준입니다. 키·비밀값은 이 문서에 적지 않습니다.

---

## 1. 진행 현황

| 단계 | 내용 | 상태 | PR |
|---|---|---|---|
| 0 | 준비: 카카오·네이버 지도·기상청 키, Cloudflare 계정 | ✅ (Firebase·Apple은 6단계로) | — |
| 1 | UI 뼈대: 테마, 하단 탭, 모든 화면(예시 데이터) | ✅ | csnam-nature/DinnerDecision#1 |
| 2 | 서버(Cloudflare Workers) + 주변 목록, GPS, 카카오 분류 보정 | ✅ | csnam-nature/DinnerDecision#2 |
| 3 | 네이버 지도, 식당 상세, 다른 앱 열기(네이버 지도·카카오·전화) | ✅ | csnam-nature/DinnerDecision#3 |
| 4 | 기기 DB(drift), 기록·설정 유지, 사진, 백업, 첫 실행 안내 | ✅ (백업 **복원**은 알려진 문제) | csnam-nature/DinnerDecision#3 |
| 5 | 기상청 날씨(`/weather`), 날씨 없이도 추천 | ✅ (미세먼지는 미룸) | csnam-nature/DinnerDecision#4 |
| 6 | 안정화·배포: App Check·Crashlytics, 개인정보처리방침, Play 내부 테스트, TestFlight | 다음 | — |

### 1.1 만든 것 한눈에

```
DinnerDecision/
├─ app/      Flutter 앱 (Android·iOS)
│  ├─ lib/data/api/          서버 클라이언트 (dio)
│  ├─ lib/data/repositories/ 식당·위치·날씨 (서버 구현 + 가짜 구현)
│  ├─ lib/data/local/        기기 DB(drift), 사진 폴더, 백업 zip
│  ├─ lib/domain/            분류 규칙, 추천 점수 (순수 Dart)
│  ├─ lib/features/          화면
│  └─ assets/config/         분류 규칙·날씨 규칙 JSON
├─ server/   Cloudflare Workers (TypeScript)
│  ├─ src/routes/            /places /region /search /weather
│  ├─ src/lib/               카카오, 기상청, 영역 분할 검색, App Check, 호출 제한
│  └─ migrations/            D1 표 (0001 식당 칸·호출 제한, 0002 날씨)
└─ docs/     계획서, 화면 설계, 이 문서
```

### 1.2 서버 API

| 주소 | 설명 | 외부 API |
|---|---|---|
| `GET /health` | 서버 상태 | — |
| `GET /places?lat=&lng=&radius=` | 반경(100~2000m) 안 음식점 | 카카오 로컬 카테고리 검색 |
| `GET /region?lat=&lng=` | 동 이름 | 카카오 좌표→행정구역 |
| `GET /search?query=` | 위치 직접 설정용 주소·장소 검색 | 카카오 주소·키워드 검색 |
| `GET /weather?lat=&lng=` | 지금 날씨 | 기상청 초단기실황·초단기예보 |

---

## 2. PC 준비 (처음 한 번)

| 도구 | 버전 | 용도 |
|---|---|---|
| Flutter | 3.50 (stable), Dart 3.14 | 앱 |
| Node.js | 22.13 이상 (LTS) | 서버 (wrangler, 테스트) |
| Android Studio | 최신 | Android SDK, 에뮬레이터 |
| Git | — | 저장소 |

**Windows 개발자 모드 켜기** — 플러그인이 있는 Flutter 앱을 빌드하려면 필요합니다 (안 켜면 `Building with plugins requires symlink support`).

```bash
start ms-settings:developers
```

**저장소 받기**

```bash
git clone https://github.com/csnam-nature/DinnerDecision.git
```

```bash
cd DinnerDecision
```

이미 받아 두었으면 최신으로:

```bash
git checkout main
```

```bash
git pull
```

---

## 3. 키·계정 준비 (0단계)

| 무엇 | 어디서 | 메모 |
|---|---|---|
| 카카오 REST API 키 | 카카오 디벨로퍼스 → 내 애플리케이션 → 앱 키 → **REST API 키** | 같은 앱의 **[앱] → [제품 설정] → [카카오맵] → 사용 설정 ON** 필수. 꺼져 있으면 모든 호출이 거절됨 |
| 네이버 지도 Client ID | Naver Cloud Platform → Services → Application Services → **Maps** → Application 등록 → **Dynamic Map** 체크 | Android 패키지·iOS 번들 ID: `kr.naturetec.dinnerdecision` |
| 기상청 키 | 공공데이터포털(data.go.kr) → **기상청_단기예보 ((구)_동네예보) 조회서비스** 활용신청 | 마이페이지 → 개발계정 → **일반 인증키(Decoding)**. 신청 직후 1~2시간은 동작 안 할 수 있음 |
| Cloudflare 계정 | dash.cloudflare.com | Workers 무료 요금제, D1 |

키는 **채팅·코드·이 문서에 붙이지 않습니다.** 서버 키는 `wrangler secret put`으로, 로컬 시험용은 `server\.dev.vars`(git에 안 올라감)에 넣습니다.

---

## 4. 서버 (Cloudflare Workers)

> ⚠️ 아래 `npm`·`npx wrangler` 명령은 모두 **`server` 폴더 안에서** 실행합니다.
> 다른 폴더에서 실행하면 `ENOENT ... package.json` 또는 `Required Worker name missing` 오류가 납니다.

```bash
cd server
```

### 4.1 처음 배포

패키지 설치:

```bash
npm install
```

Cloudflare 로그인 (브라우저가 열림):

```bash
npx wrangler login
```

D1 데이터베이스 만들기 → 출력된 `database_id`를 `wrangler.toml`의 `database_id`에 붙여 넣기:

```bash
npx wrangler d1 create dinner-cache
```

표 만들기 (`0001_init.sql`, `0002_weather.sql`이 ✅로 나와야 함). **새 migration이 생길 때마다 다시 실행**합니다:

```bash
npm run db:migrate:remote
```

비밀값 넣기 (값은 프롬프트에 붙여 넣음, 화면에 안 보이는 것이 정상):

```bash
npx wrangler secret put KAKAO_REST_KEY
```

```bash
npx wrangler secret put RATE_LIMIT_SALT
```

`RATE_LIMIT_SALT`는 아무 긴 문자열이면 됩니다. 만들기:

```bash
[guid]::NewGuid().ToString("N")
```

```bash
npx wrangler secret put KMA_SERVICE_KEY
```

들어간 비밀값 확인 (이름만 보임):

```bash
npx wrangler secret list
```

배포 (주소: `https://dinner-api.<계정>.workers.dev`):

```bash
npm run deploy
```

> 비밀값은 넣는 즉시 적용되어 다시 배포할 필요가 없습니다. 코드를 바꿨을 때만 `npm run deploy`.

### 4.2 배포 확인 (브라우저)

- `https://dinner-api.<계정>.workers.dev/health` → `{"ok":true,...}`
- `.../region?lat=37.5446&lng=127.0559` → `{"name":"성수동2가",...}`
- `.../weather?lat=37.5665&lng=126.978` → `{"tempC":...,"precipitation":...}`

주변 식당 분류 분포 보기 (분류 규칙 보정에 사용):

```bash
(Invoke-RestMethod "https://dinner-api.<계정>.workers.dev/places?lat=37.5446&lng=127.0559&radius=1000").places | Group-Object category | Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize
```

### 4.3 서버 로그 보기

켜 둔 채로 앱이나 브라우저에서 요청하면 요청마다 줄이 찍힙니다. 카카오·기상청이 거절한 이유(`kakaoError`, `kmaError`, `kmaUnreachable`)도 여기서 보입니다.

```bash
npx wrangler tail
```

### 4.4 내 PC에서 서버 돌리기 (한국 인터넷에서 시험)

`.dev.vars.example`을 `.dev.vars`로 복사하고 `KAKAO_REST_KEY`, `KMA_SERVICE_KEY`, `RATE_LIMIT_SALT`를 채운 뒤:

```bash
npm run db:migrate:local
```

```bash
npm run dev
```

브라우저: `http://localhost:8787/weather?lat=37.5665&lng=126.978`

> `localhost`는 `.dev.vars`의 키를, 배포 서버는 `wrangler secret`의 키를 씁니다. 한쪽만 되면 키가 어디에 들어갔는지 확인하세요.

### 4.5 서버 검사

```bash
npm test
```

```bash
npm run typecheck
```

### 4.6 서버 설정값 (`wrangler.toml` `[vars]`)

| 이름 | 지금 값 | 설명 |
|---|---|---|
| `APP_CHECK_MODE` | `off` | 6단계에서 `monitor` → `enforce` |
| `KAKAO_CALL_BUDGET` | `40` | 요청 한 번의 카카오 호출 상한 |
| `RATE_LIMIT_PER_MINUTE` | `30` | IP 하나의 1분당 요청 수 |

---

## 5. 앱 (Flutter)

> 아래 `flutter` 명령은 모두 **`app` 폴더 안에서** 실행합니다.

```bash
cd app
```

### 5.1 실행 설정 파일

`dart_defines.example.json`을 `dart_defines.json`으로 복사하고 값을 넣습니다 (git에 안 올라감):

```json
{
  "API_BASE_URL": "https://dinner-api.<계정>.workers.dev",
  "NAVER_MAP_CLIENT_ID": "<네이버 지도 Client ID>"
}
```

- `API_BASE_URL`이 없으면 **예시 데이터 모드**(예시 식당·예시 날씨, 저장 안 함)
- `NAVER_MAP_CLIENT_ID`가 없으면 네이버 지도 대신 그림 지도

### 5.2 실행

패키지 받기:

```bash
flutter pub get
```

연결된 기기 확인 (휴대폰은 개발자 옵션 → USB 디버깅):

```bash
flutter devices
```

실행 (서버 모드):

```bash
flutter run --dart-define-from-file=dart_defines.json
```

기기가 여러 개면 `-d <기기 ID>`를 붙입니다. 예시 데이터 모드로만 볼 때:

```bash
flutter run
```

패키지가 바뀌었거나 빌드가 이상할 때:

```bash
flutter clean
```

### 5.3 검사

```bash
flutter analyze
```

```bash
flutter test
```

### 5.4 기기 DB 표를 바꿨을 때

`lib/data/local/app_database.dart`를 고치고 `schemaVersion`을 올린 뒤 생성 코드를 다시 만듭니다:

```bash
dart run build_runner build
```

### 5.5 개발용 기능 (디버그 빌드에서만)

- 설정 › 개발용 › **예시 날씨**: 비·폭염·한파·미세먼지 등으로 바꿔 추천을 시험. 기본은 '실제 날씨'
- 설정 › 개발용 › **온보딩 다시 보기**
- 첫 실행 안내를 다시 보려면: 휴대폰 설정 → 애플리케이션 → 오늘 저녁 뭐 먹지 → 저장공간 → **데이터 삭제**

---

## 6. 실기기 확인 체크리스트

| 단계 | 확인할 것 | 결과 |
|---|---|---|
| 2 | 위치 권한 → 동 이름 → 주변 식당 목록, 분류 필터 | ✅ |
| 3 | 지도 아이콘 → 네이버 지도·색 마커·내 위치·반경 원, 마커 누르면 미리보기 | ✅ |
| 3 | 식당 상세: 네이버 지도·길찾기·전화·카카오 장소 열기 | ✅ |
| 4 | 첫 실행 안내, 기록 후 앱을 완전히 껐다 켜도 기록·설정·숨긴 식당 유지 | ✅ |
| 4 | 사진 찍기·앨범, 달력에 사진 | ✅ |
| 4 | 백업 만들기(공유 시트) | ✅ |
| 4 | 백업 복원 | ❌ 알려진 문제 (8장) |
| 5 | 화면 위쪽 실제 날씨, 추운 날·비 오는 날 추천 이유 | ✅ |

---

## 7. 문제 해결 기록

실제로 겪은 문제와 해결 방법입니다. 같은 증상이 다시 나오면 여기부터 보세요.

| 증상 | 원인 | 해결 |
|---|---|---|
| `npm error ENOENT ... package.json` | 저장소 맨 위 폴더에서 실행 | `server` 폴더에서 실행 |
| `Required Worker name missing` | `app` 폴더에서 `npx wrangler` 실행 | `server` 폴더에서 실행 |
| `/region`이 `INTERNAL`(500) | 원격 D1에 표가 없음 | `npm run db:migrate:remote` |
| `SERVER_NOT_CONFIGURED` (기상청 키) | 배포 서버에 `KMA_SERVICE_KEY` 없음 (`localhost`는 `.dev.vars`를 씀) | `npx wrangler secret list`로 확인 후 `secret put` |
| 식당 목록·동 이름이 안 나옴 (`UPSTREAM_AUTH`) | 카카오 **카카오맵 사용 설정** 꺼짐 | 카카오 디벨로퍼스 → [앱] → [제품 설정] → [카카오맵] → ON |
| 앱에서 날씨 `TIMEOUT` | 기상청이 답하지 않아 서버가 계속 기다림 (키 활성화 직후로 추정) | 서버에 기상청 8초 제한 추가, `wrangler tail`로 `kma` 로그 확인 |
| `Building with plugins requires symlink support` | Windows 개발자 모드 꺼짐 | `start ms-settings:developers` → 개발자 모드 켜기 |
| Android 빌드 `Could not close incremental caches` | 프로젝트(D:)와 Pub 캐시(C:)가 다른 드라이브 → Kotlin 증분 컴파일 실패 | `android/gradle.properties`에 `kotlin.incremental=false` (반영됨). 근본 해결: `setx PUB_CACHE D:\PubCache` |
| 앱이 첫 화면에서 멈춤 / "앱을 준비하지 못했어요" `ClassNotFoundException: Landroid/content/Context;` | `path_provider_android` 2.3.x(JNI) + `jni` 1.2.0 조합 오류 | `pubspec.yaml` `dependency_overrides`로 `path_provider_android: 2.2.23` 고정 (반영됨) |
| 백업 복원 `PlatformException(unknown_path, Failed to retrieve path.)` | 삼성 파일 선택 창의 **'다운로드' 메뉴**로 고르면 삼성 미디어 제공자가 접근 거부 (`SecurityException ... has no access to content://media/...`) | 파일 선택 창 ☰ → **'내 휴대폰(내장 메모리) › Download'** 에서 고르기. 앱이 안내 창을 띄움. (`file_selector`로 바꿨을 때는 이 오류로 앱이 꺼져서 `file_picker` 유지) |
| 에뮬레이터에서 "국내 좌표만 지원합니다" | 에뮬레이터 기본 위치가 미국 | 에뮬레이터 ⋯ → Location → 한국 위치 → Set Location |
| `OnBackInvokedCallback is not enabled` 경고 | 뒤로 가기 애니메이션 설정 안내 | 무시해도 됨 |
| `source value 8 is obsolete` 경고 | 플러그인 내부 Java 설정 | 무시해도 됨 |

### 7.1 휴대폰 로그 뽑기

앱이 꺼지거나 멈췄을 때:

```bash
adb logcat -d -b crash > crash.txt
```

```bash
adb logcat -d | Select-String "ANR in|FATAL|Fatal signal|AndroidRuntime|E/flutter" | Out-File log.txt
```

파일 선택·권한 문제일 때:

```bash
adb logcat -d | Select-String "FileSelector|file_picker|FilePickerUtils|SecurityException" | Out-File picker_log.txt
```

앱 실행 창에서는 시작 단계별 로그(`[시작] 규칙 파일 / 네이버 지도 / 앱 폴더 / 기기 DB`)로 어디서 멈췄는지 알 수 있습니다.

---

## 8. 알려진 문제와 미룬 일

| 항목 | 상태 | 다음에 할 일 |
|---|---|---|
| 백업 **복원** | 파일 고르기(내 휴대폰 › Download)·압축 풀기까지 됐으나 복원이 끝나지 않음. 같은 파일은 테스트에서 정상 복원 | 복원 시 오류 창 내용(복사 버튼)과 `adb logcat` 확인. 대안: '내 파일'에서 공유 → 앱으로 바로 복원 |
| 미세먼지 | 서버가 `dust: null`, 앱은 표시 안 함 | 에어코리아 측정소 조회(TM 좌표 변환) |
| 추천 기록(recommendation_logs) | 한 번 추천하는 동안만 넘긴 식당을 뺌 | 2차 |
| App Check | 서버 검증 코드 완성, `APP_CHECK_MODE=off` | 6단계: Firebase 프로젝트 → 앱 연결 → monitor → enforce |
| 약관 | 카카오 장소 데이터를 네이버 지도 위에 표시해도 되는지 | 6단계 배포 전 확인 |
| Cloudflare CPU 실측 | 대시보드 Workers → dinner-api → Metrics의 CPU Time | 무료 한도 10ms 대비 확인, 넘으면 `KAKAO_CALL_BUDGET` 낮추기 |
| iOS | 설정(권한 문구 등)만 반영 | 집 맥북에서 빌드 |

---

## 9. Git·PR 작업 흐름

작업 브랜치: `claude/gracious-brown-jh5jr2` (단계마다 PR → `main`에 머지)

PR 브랜치를 PC로 받아 확인할 때:

```bash
git fetch origin
```

```bash
git checkout claude/gracious-brown-jh5jr2
```

```bash
git pull
```

머지된 뒤 `main`으로 돌아올 때:

```bash
git checkout main
```

```bash
git pull
```

- PR마다 저장소의 Codex 자동 리뷰가 지적을 남깁니다. 머지 전에 확인해서 고쳤습니다 (PR #3 2건, PR #4 1건).
- `dart_defines.json`, `server/.dev.vars`는 git에 올라가지 않습니다. PC를 바꾸면 다시 만들어야 합니다.

---

## 10. 다음: 6단계 (안정화·배포)

| 순서 | 작업 | 사용자 준비물 |
|---|---|---|
| 1 | Firebase(Spark) 프로젝트 → `flutterfire configure` → App Check(디버그 토큰 → Play Integrity) → 서버 `APP_CHECK_MODE` monitor → enforce | Firebase 계정 |
| 2 | Crashlytics(오류 수집) | 같은 Firebase 프로젝트 |
| 3 | 개인정보처리방침, 앱 아이콘, 스크린샷, 릴리스 서명 키 | — |
| 4 | Play 내부 테스트 | Google Play 개발자 계정 (1회 25달러) |
| 5 | 집 맥북 iOS 빌드 → TestFlight | Apple Developer Program (연 99달러) |
| 6 | 백업 복원 문제, 약관 확인 | — |
