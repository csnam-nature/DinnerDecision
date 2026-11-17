# 오늘 저녁 뭐 먹지 — Flutter 앱

현재 위치 주변 식당을 날씨와 방문 기록으로 추천하는 앱입니다.
계획은 [`docs/PLAN.md`](../docs/PLAN.md), 화면 설계는 [`docs/UI_PLAN.md`](../docs/UI_PLAN.md)에 있습니다.

지금은 **1단계(UI 뼈대)** 입니다. 모든 화면을 오갈 수 있고, 식당·날씨·기록은 예시 데이터로 동작합니다.

## 실행

Flutter 3.50 (stable) 이상이 필요합니다.

```bash
flutter pub get
```

```bash
flutter run
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
| `lib/data/` | 저장소 인터페이스와 가짜 구현, 예시 데이터, 상태(provider) |
| `lib/features/` | 화면: 주변, 식당 상세, 추천, 달력, 기록 입력, 설정, 온보딩 |
| `assets/config/` | 분류 규칙(`cuisine_mapping.json`), 날씨 규칙(`weather_rules.json`) |
| `test/` | 추천 계산·분류 규칙 테스트, 화면 흐름 테스트 |

## 아직 가짜인 부분과 바꿀 곳

| 부분 | 지금 | 바꿀 곳 | 단계 |
|---|---|---|---|
| 주변 식당 | 예시 식당 29곳 | `PlaceRepository` 구현을 서버 `/places` 호출로 교체 | 2 |
| 현재 위치 | 예시 위치 4곳 중 선택 | `LocationController`에 GPS 연결 | 2~3 |
| 지도 | 마커만 그리는 그림 | `AppMapView` 안쪽을 `flutter_naver_map`으로 교체 | 3 |
| 네이버 지도·전화·카카오 장소 열기 | 안내 문구만 표시 | `url_launcher` 연결 | 3 |
| 식사 기록·설정 저장 | 메모리 (앱을 끄면 사라짐) | `MealLogController`, `SettingsController`를 drift DB로 교체 | 4 |
| 사진, 백업·복원 | 안내 문구만 표시 | `image_picker`, 파일 내보내기 | 4 |
| 날씨 | 설정의 '예시 날씨'에서 선택 (디버그 빌드에서만 보임) | `WeatherRepository` 구현을 서버 `/weather` 호출로 교체 | 5 |
| 온보딩 | 설정 › 개발용에서만 열림 | 첫 실행 여부 저장 후 자동 표시 | 4 |

추천 계산(`lib/domain/recommend/recommend_engine.dart`)은 가짜가 아니라 계획서 9장의 점수표 그대로입니다.

## 참고

- Flutter 3.50부터 Material 위젯은 `package:material_ui/material_ui.dart`에서 가져옵니다.
  패키지를 추가할 때 `material_ui`를 지원하는지 먼저 확인하세요. (`table_calendar`는 지원하지 않아 달력을 직접 만들었습니다.)
- 글꼴은 Pretendard입니다 (SIL Open Font License, `assets/fonts/Pretendard-LICENSE.txt`).
- 앱 ID는 Android·iOS 모두 `kr.naturetec.dinnerdecision` 입니다.
