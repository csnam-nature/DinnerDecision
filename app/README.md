# 오늘 저녁 뭐 먹지 — Flutter 앱

현재 위치 주변 식당을 날씨와 방문 기록으로 추천하는 앱입니다.
계획은 [`docs/PLAN.md`](../docs/PLAN.md), 화면 설계는 [`docs/UI_PLAN.md`](../docs/UI_PLAN.md)에 있습니다.

지금은 **2단계(서버 + 주변 목록)** 입니다.
서버 주소를 넣고 실행하면 GPS 위치와 실제 주변 식당(카카오)으로, 넣지 않으면 예시 데이터로 동작합니다.
날씨·기록은 아직 예시 데이터입니다.

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
| 지도 | 마커만 그리는 그림 | `AppMapView` 안쪽을 `flutter_naver_map`으로 교체 | 3 |
| 네이버 지도·전화·카카오 장소 열기 | 안내 문구만 표시 | `url_launcher` 연결 | 3 |
| 식사 기록·설정 저장 | 메모리 (앱을 끄면 사라짐) | `MealLogController`, `SettingsController`를 drift DB로 교체 | 4 |
| 사진, 백업·복원 | 안내 문구만 표시 | `image_picker`, 파일 내보내기 | 4 |
| 날씨 | 설정의 '예시 날씨'에서 선택 (디버그 빌드에서만 보임) | `WeatherRepository` 구현을 서버 `/weather` 호출로 교체 | 5 |
| 온보딩 | 설정 › 개발용에서만 열림 | 첫 실행 여부 저장 후 자동 표시 | 4 |

추천 계산(`lib/domain/recommend/recommend_engine.dart`)은 가짜가 아니라 계획서 9장의 점수표 그대로입니다.

## 서버 모드와 예시 모드

| | 예시 모드 (`API_BASE_URL` 없음) | 서버 모드 |
|---|---|---|
| 위치 | 예시 위치 4곳 | 켜자마자 GPS로 찾음. 실패하면 안내 후 검색으로 직접 설정 |
| 주변 식당 | 예시 29곳 | 서버 `/places` (반경 안 실제 음식점) |
| 오류 | — | 위치 권한·인터넷·호출 제한을 구분해서 안내. 인터넷 오류만 2번 자동 재시도 |

## 참고

- Flutter 3.50부터 Material 위젯은 `package:material_ui/material_ui.dart`에서 가져옵니다.
  패키지를 추가할 때 `material_ui`를 지원하는지 먼저 확인하세요. (`table_calendar`는 지원하지 않아 달력을 직접 만들었습니다.)
- `geolocator`의 웹용 하위 패키지는 예전 `package:flutter/material.dart`를 쓰지만, 이 앱은 Android·iOS만 대상이라 영향이 없습니다.
- 글꼴은 Pretendard입니다 (SIL Open Font License, `assets/fonts/Pretendard-LICENSE.txt`).
- 앱 ID는 Android·iOS 모두 `kr.naturetec.dinnerdecision` 입니다.
