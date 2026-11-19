# 오늘 저녁 뭐 먹지 — Flutter 앱

현재 위치 주변 식당을 날씨와 방문 기록으로 추천하는 앱입니다.
계획은 [`docs/PLAN.md`](../docs/PLAN.md), 화면 설계는 [`docs/UI_PLAN.md`](../docs/UI_PLAN.md)에 있습니다.

지금은 **4단계(기록·달력)** 입니다.
서버 주소를 넣고 실행하면 GPS 위치와 실제 주변 식당(카카오)으로, 넣지 않으면 예시 데이터로 동작합니다.
네이버 지도 Client ID를 넣으면 네이버 지도로, 넣지 않으면 마커만 그린 그림 지도로 보입니다.
서버 모드에서는 식사 기록·사진·설정·숨긴 식당을 휴대폰 안 DB에 저장하고, 백업 파일로 내보내고 복원할 수 있습니다.
날씨는 아직 예시 데이터입니다.

## 실행

Flutter 3.50 (stable) 이상이 필요합니다.

```bash
flutter pub get
```

```bash
flutter run
```

서버(`../server`)를 배포했으면 주소를 넣어 실행합니다. 주소가 없으면 예시 데이터로 동작합니다.

```bash
flutter run --dart-define=API_BASE_URL=https://dinner-api.<계정>.workers.dev
```

네이버 지도까지 쓰려면 Client ID도 넣습니다 (Naver Cloud Platform → Maps → Application, Dynamic Map).

```bash
flutter run --dart-define=API_BASE_URL=https://dinner-api.<계정>.workers.dev --dart-define=NAVER_MAP_CLIENT_ID=<Client ID>
```

매번 입력하기 번거로우면 `dart_defines.example.json`을 `dart_defines.json`으로 복사해 값을 넣고 실행합니다. (`dart_defines.json`은 git에 올라가지 않습니다.)

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## 검사

```bash
flutter analyze
```

```bash
flutter test
```

## 폴더

| 위치 | 내용 |
|---|---|
| `lib/app/` | 앱 시작, 라우터, 하단 탭, 테마, 공통 위젯 |
| `lib/core/` | 거리·날짜·조사 같은 작은 함수 |
| `lib/domain/` | 모델, 분류 규칙, 추천 점수 계산 (화면과 무관한 순수 Dart) |
| `lib/data/` | 서버 클라이언트(`api/`), 저장소(서버 구현 + 가짜 구현), 예시 데이터, 상태(provider) |
| `lib/features/` | 화면: 주변, 식당 상세, 추천, 달력, 기록 입력, 설정, 온보딩 |
| `assets/config/` | 분류 규칙(`cuisine_mapping.json`), 날씨 규칙(`weather_rules.json`) |
| `test/` | 추천 계산·분류 규칙, 서버 응답 처리, 위치 처리, 화면 흐름 테스트 |

## 아직 가짜인 부분과 바꿀 곳

| 부분 | 지금 | 바꿀 곳 | 단계 |
|---|---|---|---|
| ~~주변 식당~~ | ✅ 서버 `/places` (`ApiPlaceRepository`) | — | 2 |
| ~~현재 위치~~ | ✅ GPS(`geolocator`) + 동 이름 `/region` + 위치 검색 `/search` | — | 2 |
| 앱 인증 | 서버 `APP_CHECK_MODE=off` | Firebase App Check 토큰을 `ApiClient(appCheckToken:)`에 연결 | 2~3 (Firebase 준비 후) |
| 지도 | ✅ `NAVER_MAP_CLIENT_ID`가 있으면 네이버 지도(`NaverMapView`), 없으면 그림 지도 | 실기기 확인 | 3 |
| ~~네이버 지도·전화·카카오 장소 열기~~ | ✅ `url_launcher` (`RestaurantLinks`). 네이버 지도 앱이 없으면 네이버 지도 웹 | — | 3 |
| ~~식사 기록·설정 저장~~ | ✅ 서버 모드: 기기 DB(drift, `lib/data/local/`). 예시 모드: 메모리 | — | 4 |
| ~~사진, 백업·복원~~ | ✅ 사진은 앱 폴더 `photos/`, 백업은 zip(JSON + 사진)을 공유 시트로 | — | 4 |
| 날씨 | 설정의 '예시 날씨'에서 선택 (디버그 빌드에서만 보임) | `WeatherRepository` 구현을 서버 `/weather` 호출로 교체 | 5 |
| ~~온보딩~~ | ✅ 서버 모드에서 처음 켤 때 자동 표시 | — | 4 |

추천 계산(`lib/domain/recommend/recommend_engine.dart`)은 가짜가 아니라 계획서 9장의 점수표 그대로입니다.

## 기기 DB (drift)

표 정의는 `lib/data/local/app_database.dart`, 자동 생성 코드는 `app_database.g.dart`입니다.
표를 바꾸면 `schemaVersion`을 올리고 옮기는 방법(migration)을 적은 뒤 다시 생성합니다.

```bash
dart run build_runner build
```

앱을 켤 때 DB 내용을 한 번 읽어 메모리에 올리고(`storedDataProvider`), 바뀔 때마다 바로 DB에 씁니다.
기록은 1년에 수백 건이라 전부 올려도 가볍습니다.

## 서버 모드와 예시 모드

| | 예시 모드 (`API_BASE_URL` 없음) | 서버 모드 |
|---|---|---|
| 위치 | 예시 위치 4곳 | 켜자마자 GPS로 찾음. 실패하면 안내 후 검색으로 직접 설정 |
| 주변 식당 | 예시 29곳 | 서버 `/places` (반경 안 실제 음식점) |
| 오류 | — | 위치 권한·인터넷·호출 제한을 구분해서 안내. 인터넷 오류만 2번 자동 재시도 |
| 기록·설정 | 예시 기록, 앱을 끄면 처음으로 | 기기 DB에 저장 |
| 첫 실행 안내 | 설정 › 개발용에서만 | 처음 켤 때 자동 |

## 참고

- Flutter 3.50부터 Material 위젯은 `package:material_ui/material_ui.dart`에서 가져옵니다.
  패키지를 추가할 때 `material_ui`를 지원하는지 먼저 확인하세요. (`table_calendar`는 지원하지 않아 달력을 직접 만들었습니다.)
- `geolocator`의 웹용 하위 패키지는 예전 `package:flutter/material.dart`를 쓰지만, 이 앱은 Android·iOS만 대상이라 영향이 없습니다.
- `flutter_naver_map` 1.4.4도 예전 material을 씁니다. 지도 본체는 문제없지만, 로고를 누르면 뜨는 정보 창은 `material_ui` 앱에서 동작하지 않아 로고 누르기를 껐습니다(`logoClickEnable: false`).
- Android는 네이버 지도 SDK 저장소(`repository.map.naver.com`)를 `android/build.gradle.kts`에 넣었습니다.
- 글꼴은 Pretendard입니다 (SIL Open Font License, `assets/fonts/Pretendard-LICENSE.txt`).
- 앱 ID는 Android·iOS 모두 `kr.naturetec.dinnerdecision` 입니다.
