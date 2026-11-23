# 출시 준비와 Play 내부 테스트 (6-4 ~ 6-5)

> 작성일 2026-11-23 · 계획: [`PLAN.md`](./PLAN.md) 11.5 · 진행 기록: [`PROGRESS.md`](./PROGRESS.md)

명령은 Windows PowerShell 기준입니다. 키·비밀번호는 이 문서와 저장소에 넣지 않습니다.

---

## 1. 이번에 준비한 것

| 항목 | 위치 | 상태 |
|---|---|---|
| 앱 아이콘 (Android 모양 맞춤 아이콘 포함, iOS 전 크기) | 원본 `app/assets/icon/`, 생성 결과 `android/.../res/mipmap-*`, `ios/.../AppIcon.appiconset` | ✅ |

> 아이콘을 바꿀 때: `app/assets/icon/`의 그림을 바꾸고 `app` 폴더에서 `dart run flutter_launcher_icons`.
> ⚠️ 이 도구가 `ios/Runner.xcodeproj/project.pbxproj`의 `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`를 `AppIcon`으로 잘못 바꿉니다(값은 `YES`여야 함). 실행한 뒤 이 파일은 되돌리세요: `git checkout -- ios/Runner.xcodeproj/project.pbxproj`
| 출시용 서명 설정 | `app/android/app/build.gradle.kts` (`key.properties`가 있으면 그 키로 서명) | ✅ 설정 · ⏳ 키 만들기 |
| 개인정보처리방침 | 서버 `GET /privacy` (`server/src/privacy.ts`), 앱 설정 › 정보 › 개인정보처리방침 | ✅ 운영자 naturetec, 문의 이메일 반영 · ⏳ 배포 |
| 스토어 그래픽 이미지 (1024×500), 스토어 아이콘 (512×512) | `docs/store/` | ✅ |
| 스토어 문안, 데이터 보안 양식 답안 | 이 문서 4·5장 | ✅ 초안 |
| 출시 빌드 설정 파일 | `app/dart_defines.release.example.json` | ✅ |

---

## 2. 출시용 서명 키 만들기 (처음 한 번)

> ⚠️ **이 키를 잃어버리면 앱을 업데이트할 수 없습니다.** 저장소 밖(예: `D:\keys\`)에 두고, 키 파일과 비밀번호를 **따로 안전한 곳에 백업**하세요.
> Play 앱 서명을 쓰므로 이 키는 "업로드 키"입니다. 잃어버리면 Play Console에서 재설정을 요청할 수 있지만 시간이 걸립니다.

키 폴더 만들기:

```bash
mkdir D:\keys
```

키 만들기 (`keytool`은 Android Studio에 들어 있는 JDK에 있습니다. 비밀번호와 이름 등을 물어봅니다):

```bash
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore D:\keys\dinnerdecision-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`app\android\key.properties.example`을 `app\android\key.properties`로 복사하고 비밀번호를 채웁니다 (git에 올라가지 않음):

```properties
storeFile=D:/keys/dinnerdecision-upload.jks
storePassword=키 비밀번호
keyAlias=upload
keyPassword=키 비밀번호
```

업로드 키의 SHA-256 확인 (Firebase에 등록할 값):

```bash
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore D:\keys\dinnerdecision-upload.jks -alias upload
```

---

## 3. 출시 빌드 (AAB)

`app\dart_defines.release.example.json`을 `app\dart_defines.release.json`으로 복사하고 값을 넣습니다.
**출시 빌드에는 `APP_CHECK_DEBUG_TOKEN`을 넣지 않습니다** (디버그 토큰은 개발 기기용 열쇠입니다).

`app` 폴더에서:

```bash
flutter clean
```

```bash
flutter build appbundle --release --dart-define-from-file=dart_defines.release.json
```

결과: `app\build\app\outputs\bundle\release\app-release.aab`

버전을 올릴 때는 `app/pubspec.yaml`의 `version: 1.0.0+1`에서 `+` 뒤 숫자(빌드 번호)를 **매번 1씩** 올립니다. Play는 같은 빌드 번호를 다시 받지 않습니다.

---

## 4. Play 스토어 등록 정보 (초안)

| 항목 | 값 |
|---|---|
| 앱 이름 | 오늘 저녁 뭐 먹지 |
| 기본 언어 | 한국어 (ko-KR) |
| 앱/게임 | 앱 · 무료 |
| 카테고리 | 식음료 |
| 광고 포함 | 아니요 |
| 개인정보처리방침 URL | `https://dinner-api.<계정>.workers.dev/privacy` |
| 앱 아이콘 | `docs/store/icon_512.png` |
| 그래픽 이미지 | `docs/store/feature_graphic.png` |

**짧은 설명 (80자 이내, 현재 49자)**

```
날씨와 내가 먹은 기록을 보고 골라 주는 오늘 저녁. 주변 1km 맛집 추천과 식사 달력
```

**자세한 설명**

```
"오늘 저녁 뭐 먹지?" 매일 하는 고민을 버튼 하나로 끝내세요.

■ 주변 1km 맛집을 한눈에
지금 있는 곳 주변 음식점을 한식·중식·일식·양식으로 나눠 가까운 순으로 보여줘요. 지도로도 볼 수 있어요.

■ 날씨와 기록을 보고 추천
비 오는 날엔 따뜻한 국물, 더운 날엔 시원한 메뉴. 최근에 간 식당과 연달아 먹은 메뉴는 피해서 오늘의 저녁을 골라 드려요. 왜 추천했는지 이유도 함께 알려줘요.

■ 식사 달력
먹은 곳과 메뉴, 별점, 사진을 남기면 달력에 차곡차곡 쌓여요.

■ 개인정보는 휴대폰에
회원가입이 없고, 식사 기록과 사진은 휴대폰에만 저장돼요. 백업 파일로 직접 보관할 수 있어요.

장소 정보: 카카오 · 지도: 네이버 지도 · 날씨: 기상청
```

**스크린샷 (휴대폰, 최소 2장, 권장 4~6장)** — 실기기에서 찍습니다. 개인 기록·실제 집 근처 위치가 보이지 않게, 설정 › 위치 설정에서 번화가(예: 강남역)를 골라 찍기를 권합니다.

1. 주변 목록 (분류 칩, 날씨 한 줄)
2. 주변 지도 (색 마커)
3. 추천 결과 (큰 카드 + 이유 문장)
4. 식당 상세
5. 식사 달력

PC에서 찍기:

```bash
adb exec-out screencap -p > screenshot1.png
```

---

## 5. 데이터 보안 양식 답안 (Play Console › 앱 콘텐츠 › 데이터 보안)

앱의 실제 동작 기준입니다. 동작을 바꾸면 이 표와 `server/src/privacy.ts`를 같이 고칩니다.

**공통 질문**

| 질문 | 답 |
|---|---|
| 사용자 데이터를 수집하거나 공유하나요? | 예 (수집) |
| 전송 중 데이터가 암호화되나요? | 예 (HTTPS) |
| 사용자가 데이터 삭제를 요청할 수 있나요? | 서버에 이용자를 알아볼 수 있는 데이터를 저장하지 않음. 앱 데이터는 앱에서 직접 삭제 |

**수집 항목** (공유는 모두 "아니요": Cloudflare·카카오·기상청·Google은 운영자를 대신해 처리하는 서비스 제공업체)

| 데이터 유형 | 수집 | 일시적 처리 | 필수/선택 | 목적 | 근거 |
|---|---|---|---|---|---|
| 위치 › **정확한 위치** | 예 | 예 | 선택 (거부해도 위치 검색으로 사용 가능) | 앱 기능 | 약 100m 단위로 줄여 보내지만, Google 기준(3km² 이상이어야 '대략적')으로는 정확한 위치에 해당 |
| 앱 활동 › 앱 내 검색 기록 | 예 | 예 | 선택 | 앱 기능 | 위치 직접 설정의 주소·장소 검색어 |
| 앱 정보 및 성능 › 비정상 종료 로그 | 예 | 아니요 | 필수 | 분석 | Crashlytics |
| 앱 정보 및 성능 › 진단 | 예 | 아니요 | 필수 | 분석 | Crashlytics (기기 모델, OS 버전) |
| 기기 또는 기타 ID | 예 | 아니요 | 필수 | 분석, 사기 방지·보안 | Firebase 설치 ID (Crashlytics), App Check |

**수집하지 않음:** 사진·동영상(휴대폰에만 저장), 식사 기록(휴대폰에만), 이름·이메일·전화번호 등 개인 식별 정보, 연락처, 금융 정보.

**기타 앱 콘텐츠 항목**

| 항목 | 답 |
|---|---|
| 광고 | 광고 없음 |
| 앱 액세스 권한 | 모든 기능을 로그인 없이 사용 가능 |
| 콘텐츠 등급 설문 | 폭력·성적 내용·도박 등 없음 → 전체이용가 예상 |
| 타겟층 | 만 18세 이상 (아동 대상 아님) |
| 위치 권한 | 앱 사용 중 위치만 사용 (백그라운드 위치 없음 → 별도 신고서 불필요) |

---

## 6. Play 내부 테스트 (6-5)

1. Google Play Console 개발자 계정 (1회 25달러, 신원 확인에 며칠)
2. **앱 만들기** → 위 4장 등록 정보, 5장 데이터 보안, 앱 콘텐츠 항목 작성
3. **테스트 › 내부 테스트** → 새 버전 만들기 → `app-release.aab` 업로드 → 테스터(이메일) 추가 → 출시
4. **앱 무결성** › Play 앱 서명 › **앱 서명 키 인증서 SHA-256**을 복사해 Firebase 프로젝트 설정 › Android 앱 › 디지털 지문에 추가 (업로드 키 SHA-256도 추가)
5. **앱 무결성** › Play Integrity API › Google Cloud 프로젝트 연결 → Firebase 프로젝트(`dinnerdecision-ca59c`) 선택
6. 테스터 휴대폰에서 Play로 설치 → `npx wrangler tail`에 `"appCheck":"ok"` 확인 → 서버 `APP_CHECK_MODE = "enforce"`로 바꾸고 배포

---

## 7. 출시 전에 확인할 것

| 항목 | 내용 |
|---|---|
| 개인정보처리방침 | ✅ 운영자·문의 이메일 반영. 앱 동작을 바꾸면 `server/src/privacy.ts`도 같이 고치고 배포 |
| 위치정보법 | 이용자의 위치로 서비스를 제공하는 경우 **위치기반서비스사업 신고** 대상인지 확인 필요 (방송통신위원회, 한국인터넷진흥원 위치정보지원센터 안내). 공개 출시 전에 확인 |
| 약관 | 카카오 장소 데이터를 네이버 지도 위에 표시해도 되는지 (PLAN.md 12장) |
| 출처 표시 | 앱 목록 하단 "장소 정보: 카카오", 설정 화면 데이터 출처 (카카오·네이버 지도·기상청) |
