# Cloudflare · Firebase 역할 정리와 직접 설정한 항목

> 작성일 2026-11-24 · 근거: [`PLAN.md`](./PLAN.md), [`PROGRESS.md`](./PROGRESS.md), [`RELEASE.md`](./RELEASE.md), `server/README.md`, `server/wrangler.toml`, `app/lib/app/firebase_setup.dart`
>
> 질문에 적힌 `claudeflare`는 **Cloudflare**, `fireball`은 **Firebase**로 보고 정리했습니다.
> 키·비밀번호의 실제 값은 저장소에 없고, 이 문서에도 이름과 용도만 적습니다.

---

## 1부. Cloudflare와 Firebase의 역할과 기능

### 전체 구조

```
Flutter 앱 ──(HTTPS + App Check 토큰)──▶ Cloudflare Workers (dinner-api) ──▶ 카카오 로컬 API / 기상청 API
   │                                         └─ D1(SQLite) 캐시
   └─▶ Firebase (Spark 무료): App Check, Crashlytics
```

### Cloudflare (`server/`): 중계 서버

Workers에 TypeScript로 올린 `dinner-api`입니다. 앱이 카카오·기상청 API를 직접 부르지 않고 이 서버를 거칩니다. 무료 요금제로 운영합니다.

| 역할 | 내용 |
|---|---|
| API 키 보관 | 카카오 REST 키, 기상청 키, 호출 제한용 salt를 Workers Secrets에만 둡니다. 앱에는 키가 없습니다. |
| 외부 API 중계 | 카카오 로컬 API와 기상청 API를 대신 호출합니다. |
| 캐시(D1) | 식당 목록은 geohash 5자리 칸 단위로 24시간, 날씨는 기상청 격자 단위로 20분 저장합니다. 칸이 고정이라 같은 동네 사용자끼리 캐시를 나눠 씁니다. |
| 영역 분할 검색 | 카카오는 한 조건에 최대 45곳만 주므로, 45곳이 넘는 칸은 4등분해 최대 6단계까지 다시 검색합니다. 요청 한 번에 카카오 호출은 40번 이하입니다. 남은 칸은 `complete:false`로 알리고 다음 요청에서 이어서 채웁니다. |
| App Check 검증 | 앱이 보낸 `X-Firebase-AppCheck` JWT를 Google 공개키로 검증합니다. `APP_CHECK_MODE`는 `off` → `monitor` → `enforce` 순서로 올리며 현재 `monitor`입니다. |
| 호출 제한 | IP를 해시해서 1분에 30번까지만 허용합니다. |
| 개인정보 보호 | 요청 좌표를 저장하거나 로그에 남기지 않습니다. 앱이 좌표를 약 100m 단위로 줄여 보내고 invocation logs도 꺼 두었습니다. |
| 정기 정리 | 매일 새벽 4시(한국)에 cron으로 지난 캐시를 지웁니다. |

**엔드포인트**

| 주소 | 설명 |
|---|---|
| `GET /health` | 서버 상태 |
| `GET /places` | 반경 안 음식점 |
| `GET /region` | 동 이름 |
| `GET /search` | 위치 직접 설정용 주소·장소 검색 |
| `GET /weather` | 현재 날씨 |
| `GET /privacy` | 개인정보처리방침 공개 페이지 |

### Firebase (`app/`): 앱 인증과 오류 수집

Spark 무료 요금제에서 **App Check와 Crashlytics 두 가지만** 씁니다. 코드는 `app/lib/app/firebase_setup.dart`에 있습니다.

| 기능 | 역할 |
|---|---|
| **App Check** | 진짜 우리 앱의 요청인지 증명하는 토큰을 발급합니다. 앱이 이 토큰을 서버 요청 헤더에 넣고, Workers가 검증합니다. 출시 빌드는 Play Integrity(Android)와 App Attest(iOS)를, 디버그 빌드는 디버그 토큰을 씁니다. |
| **Crashlytics** | 처리하지 못한 오류, 시작 실패, 백업 오류를 수집합니다. 오류 내용과 위치(코드), 기기 모델·OS 버전만 보내고 위치·기록·사진은 보내지 않습니다. 기록 내용이 섞일 수 있는 오류는 `SanitizedError`로 종류와 코드 위치만 보냅니다. 디버그 빌드는 설정의 시험 버튼으로 보낸 오류만 기록합니다. |
| 장애 대비 | Firebase 초기화에 실패하면 `FirebaseServices.disabled`로 Firebase 없이 계속 동작합니다. |

Firebase Auth와 Firestore를 쓰는 클라우드 동기화(F-15)는 2차 계획이며 아직 구현되지 않았습니다.

### 둘의 연결

- 앱은 Firebase에서 App Check 토큰을 받아 Cloudflare 서버에 보냅니다. 서버는 `FIREBASE_PROJECT_NUMBER`(`wrangler.toml`)로 토큰의 발급자와 대상 프로젝트를 확인합니다.
- 현재 서버는 `monitor` 모드라 토큰이 틀려도 통과시키고 로그만 남깁니다. 실기기에서 `appCheck: ok`를 확인한 상태입니다.
- Play 내부 테스트로 설치한 앱에서도 모두 ok가 나오면 `enforce`로 올려 앱이 아닌 요청을 막는 것이 6단계 계획입니다.

---

## 2부. 직접 설정한 항목과 그 기능·이유

저장 위치는 용도에 따라 나뉩니다. 서버 비밀값은 `wrangler secret put`으로 Cloudflare에 넣거나 로컬에서는 `server/.dev.vars`(git 제외)에 넣고, 앱용 값은 `dart_defines.json`으로 넣습니다. 완료 여부는 문서에 적힌 상태 기준입니다.

### 1. 계정 가입

| 계정 | 하는 일 | 이유 | 상태 |
|---|---|---|---|
| 카카오 디벨로퍼스 | 앱 생성, 제품 설정에서 **카카오맵 사용 설정 ON** | 주변 식당 검색(로컬 API)에 필요합니다. 사용 설정이 꺼져 있으면 모든 호출이 거절되어 서버가 `UPSTREAM_AUTH`(502)를 돌려줍니다. | ✅ |
| Naver Cloud Platform | Maps → Application 등록, Dynamic Map 체크, 패키지명·번들 ID 등록 | 앱 화면에 지도를 띄웁니다. | ✅ |
| 공공데이터포털(data.go.kr) | 기상청_단기예보 조회서비스 활용신청 | 날씨(기온, 강수, 하늘 상태)를 가져옵니다. | ✅ (날씨 확인됨) |
| Cloudflare | 계정 가입, Workers·D1 사용, `wrangler login` | 중계 서버와 캐시 DB를 올립니다. | ✅ |
| Firebase | 프로젝트 `dinnerdecision-ca59c`(Spark 무료, 애널리틱스 끔), Android·iOS 앱 등록, `flutterfire configure` | App Check와 Crashlytics에 필요합니다. | ✅ |
| Google Play Console | 개발자 계정(개인은 1회 25달러), 앱 만들기 | 내부 테스트와 출시에 필요합니다. | 🔄 진행 중 |
| Apple Developer Program | 가입(연 99달러) | TestFlight와 iOS 출시에 필요합니다. | ⏳ |

### 2. API 키와 비밀값

| 이름 | 어디서 발급 | 저장 위치 | 기능과 이유 |
|---|---|---|---|
| `KAKAO_REST_KEY` | 카카오 앱 키의 **REST API 키** | Workers Secret | 식당·동 이름·주소 검색 호출용입니다. 앱에 넣으면 APK에서 꺼낼 수 있어 서버에만 둡니다. |
| `KMA_SERVICE_KEY` | 공공데이터포털 마이페이지의 **일반 인증키(Decoding)** | Workers Secret | 기상청 호출용입니다. 활용신청 직후 1~2시간은 동작하지 않을 수 있습니다. |
| `RATE_LIMIT_SALT` | 직접 만든 **아무 긴 문자열** | Workers Secret | IP 해시에 섞는 값입니다(3번 참고). |
| `NAVER_MAP_CLIENT_ID` | 네이버 Maps Application | 앱 `dart_defines.json` | 지도 표시용입니다. 클라이언트 키라 앱에 들어가도 되고, 등록한 패키지명(`kr.naturetec.dinnerdecision`)에서만 동작합니다. |
| `API_BASE_URL` | 배포 후 나온 `https://dinner-api.<계정>.workers.dev` | 앱 `dart_defines.json` | 앱이 접속할 서버 주소입니다. 비워서 빌드하면 예시 데이터로 동작합니다. |
| `APP_CHECK_DEBUG_TOKEN` | Firebase 콘솔 App Check → 디버그 토큰 관리에서 등록 | 개발용 `dart_defines.json`만 | 개발 중 기기가 App Check를 통과하는 열쇠입니다. **출시 빌드에는 넣지 않습니다.** |
| `database_id` | `wrangler d1 create dinner-cache` 결과 | `wrangler.toml` | 캐시 DB를 연결합니다. 비밀값은 아닙니다. |

`wrangler.toml`의 `FIREBASE_PROJECT_NUMBER`는 서버가 App Check 토큰의 발급자와 대상 프로젝트를 확인할 때 쓰는 값이며, Firebase 콘솔에서 확인하고 비밀값이 아닙니다.

### 3. 해시 관련: 두 가지가 다릅니다

**① `RATE_LIMIT_SALT` (서버 비밀값)**
- 호출 제한을 위해 IP별로 호출 횟수를 세야 하는데, IP를 그대로 DB에 저장하면 개인정보가 됩니다.
- 그래서 IP에 salt를 섞어 해시한 값으로만 1분 호출 횟수를 저장합니다.
- salt가 없거나 짧으면 가능한 IP 범위가 좁아서 해시를 역으로 추정할 수 있기 때문에 긴 문자열을 쓰도록 했습니다.

**② 서명 키의 SHA-256 지문 (Firebase에 등록)**
- Android 앱 서명 인증서의 지문입니다. Firebase가 "이 서명을 가진 앱만 진짜"라고 판단하는 기준입니다.
- 등록 대상은 세 가지입니다.
  - 개발용 디버그 키 (6-1, 완료)
  - 직접 만든 업로드 키 (`keytool -list -v`로 확인)
  - Play Console 앱 무결성 화면의 **앱 서명 키 인증서**와 **업로드 키 인증서** (6-5, 진행 중)
- Play에서 설치한 앱은 Google이 다시 서명하기 때문에 업로드 키와 Play 앱 서명 키를 모두 등록해야 합니다. 하나라도 빠지면 App Check가 `failed`로 나옵니다.

### 4. 비밀번호와 서명 키

| 항목 | 내용 | 이유 |
|---|---|---|
| 업로드 키 (`dinnerdecision-upload.jks`) | `keytool`로 생성, 저장소 밖(`D:\keys\`)에 보관 | Play에 올리는 앱(AAB)에 서명합니다. **잃으면 업데이트가 막혀서** 파일과 비밀번호를 따로 백업해야 합니다. |
| `key.properties` (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`) | `key.properties.example`을 복사해 작성 (git 제외) | 빌드 때 위 키로 자동 서명합니다. 비밀번호는 영문·숫자를 권장하며 `#`, `!`, `\`는 다르게 읽힙니다. |
| Play 앱 서명 동의 | 첫 버전 올릴 때 동의 | Google이 최종 서명 키를 관리하고, 내 키는 업로드 키가 됩니다. |

이 프로젝트에는 사용자 회원가입·로그인 기능이 없습니다. 위의 "회원가입"은 개발자 계정 가입이고, 비밀번호는 서명 키 비밀번호입니다. 식사 기록은 휴대폰에만 저장합니다(로그인과 Firestore 동기화는 2차 계획).

### 5. 연결 설정

| 설정 | 기능 |
|---|---|
| Firebase App Check 활성화 (Play Integrity, App Attest) | 우리 앱의 요청인지 증명합니다. 서버를 `monitor`에서 `enforce`로 올리면 앱이 아닌 요청을 막습니다. |
| Play Console 앱 무결성에서 Cloud 프로젝트 연결 (`dinnerdecision-ca59c`) | Play Integrity가 Firebase 프로젝트로 인증하도록 연결합니다. 반영에 몇 분~몇 시간 걸립니다. |
| `npm run db:migrate:remote` | 원격 D1에 캐시 테이블을 만듭니다. 빠지면 `/region` 등이 `INTERNAL`(500)로 실패합니다. |
| 개인정보처리방침 URL 등록 | `https://dinner-api.<계정>.workers.dev/privacy`를 Play 스토어 등록에 입력합니다. 서버가 제공합니다. |
| 데이터 보안 양식 (Play Console) | `RELEASE.md` 5장 표대로 답합니다. 실제 동작과 달라지면 안 됩니다. |

### 6. 남은 항목

- Play 내부 테스트 업로드와 앱 무결성 SHA-256 등록
- 서버 `APP_CHECK_MODE`를 `monitor`에서 `enforce`로 올리기
- Apple Developer 가입, 맥북에서 `flutterfire configure`를 다시 실행해 iOS 설정 파일 만들기, TestFlight
- 카카오·네이버 약관 확인 (카카오 데이터를 네이버 지도 위에 표시해도 되는지)
- 위치기반서비스사업 신고 대상 여부 확인
- 개인 계정이면 정식 출시 전에 비공개 테스트 12명 이상이 14일 연속 참여해야 함

### 보안 메모

`app/android/app/google-services.json`과 `firebase_options.dart`는 저장소에 올라가 있지만 Firebase 클라이언트 설정은 비밀값이 아니라서 문서상 의도된 구성입니다. 카카오·기상청 키, `RATE_LIMIT_SALT`, `key.properties`, `.jks` 파일이 커밋되지 않도록 `.gitignore`로 제외돼 있는지 한 번 확인하세요.
