import 'package:dinner_decision/app/app.dart';
import 'package:dinner_decision/data/api/api_client.dart';
import 'package:dinner_decision/data/providers.dart';
import 'package:dinner_decision/data/repositories/location_repository.dart';
import 'package:dinner_decision/data/repositories/place_repository.dart';
import 'package:dinner_decision/data/sample/sample_data.dart';
import 'package:dinner_decision/domain/models/app_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// 서버를 쓰는 모드처럼 동작하게 한다. 실제 호출은 가짜 저장소가 받는다.
List<Override> serverMode({required LocationRepository location}) => [
  appConfigProvider.overrideWithValue(loadTestConfig()),
  clockProvider.overrideWithValue(() => testToday),
  apiClientProvider.overrideWithValue(ApiClient(baseUrl: 'https://api.test')),
  placeRepositoryProvider.overrideWithValue(
    FakePlaceRepository(delay: Duration.zero),
  ),
  locationRepositoryProvider.overrideWithValue(location),
];

class _SearchableLocations extends FakeLocationRepository {
  const _SearchableLocations({super.failure});

  @override
  Future<List<AppLocation>> search(String query) async => [
    const AppLocation(
      name: '강남역 2호선',
      detail: '서울 강남구 강남대로 396',
      lat: 37.4979,
      lng: 127.0276,
      source: LocationSource.search,
    ),
  ];
}

/// current()가 몇 번 불렸는지 세고, 정해 두면 예상 밖 오류를 낸다.
class _CountingLocations extends FakeLocationRepository {
  _CountingLocations({this.crash = false});

  final bool crash;
  var calls = 0;

  @override
  Future<AppLocation> current() async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (crash) throw StateError('플랫폼 오류');
    return sampleLocations.first;
  }
}

void main() {
  group('LocationController', () {
    test('찾는 중에 또 부르면 새로 찾지 않고 같은 결과를 기다린다', () async {
      final repo = _CountingLocations();
      final container = ProviderContainer(
        overrides: serverMode(location: repo),
      );
      addTearDown(container.dispose);
      container.listen(locationStateProvider, (_, _) {});
      final controller = container.read(locationStateProvider.notifier);
      // 첫 실행 안내에서 '허용'을 누르면 시작할 때 찾기와 버튼의 찾기가 겹친다.
      await Future.wait([controller.locateMe(), controller.locateMe()]);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repo.calls, 1);
      expect(container.read(locationProvider), sampleLocations.first);
    });

    test('예상하지 못한 오류가 나도 찾는 중에 멈추지 않는다', () async {
      final container = ProviderContainer(
        overrides: serverMode(location: _CountingLocations(crash: true)),
      );
      addTearDown(container.dispose);
      container.listen(locationStateProvider, (_, _) {});
      final failure = await container
          .read(locationStateProvider.notifier)
          .locateMe();
      expect(failure, isNotNull);
      final state = container.read(locationStateProvider);
      expect(state.locating, isFalse);
      expect(state.failure, isNotNull);
    });

    test('서버 모드에서는 시작하자마자 GPS로 위치를 찾는다', () async {
      final container = ProviderContainer(
        overrides: serverMode(location: const FakeLocationRepository()),
      );
      addTearDown(container.dispose);
      // 화면처럼 지켜보는 쪽이 있어야 위치가 바뀔 때 목록이 다시 계산된다.
      container.listen(nearbyPlacesProvider, (_, _) {});

      expect(container.read(locationStateProvider).locating, isTrue);
      final places = await container.read(nearbyPlacesProvider.future);
      expect(container.read(locationProvider), sampleLocations.first);
      expect(places, isNotEmpty);
    });

    test('GPS가 실패하면 주변 목록이 위치 오류가 된다', () async {
      final container = ProviderContainer(
        overrides: serverMode(
          location: const FakeLocationRepository(
            failure: LocationFailure.deniedForever,
          ),
        ),
      );
      addTearDown(container.dispose);
      container.listen(nearbyPlacesProvider, (_, _) {});

      await expectLater(
        container.read(nearbyPlacesProvider.future),
        throwsA(
          isA<LocationException>().having(
            (e) => e.failure,
            'failure',
            LocationFailure.deniedForever,
          ),
        ),
      );
      expect(
        container.read(locationStateProvider).failure,
        LocationFailure.deniedForever,
      );
    });

    test('위치를 직접 고르면 실패 표시가 사라지고 목록을 불러온다', () async {
      final container = ProviderContainer(
        overrides: serverMode(
          location: const FakeLocationRepository(
            failure: LocationFailure.denied,
          ),
        ),
      );
      addTearDown(container.dispose);
      container.listen(nearbyPlacesProvider, (_, _) {});
      await container.read(locationStateProvider.notifier).locateMe();

      container.read(locationStateProvider.notifier).select(sampleLocations[2]);
      expect(container.read(locationStateProvider).failure, isNull);
      expect(await container.read(nearbyPlacesProvider.future), isNotEmpty);
    });
  });

  group('화면', () {
    Future<void> pump(WidgetTester tester, LocationRepository location) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: serverMode(location: location),
          child: const DinnerDecisionApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('위치 권한이 없으면 안내하고, 검색으로 위치를 고를 수 있다', (tester) async {
      await pump(
        tester,
        const _SearchableLocations(failure: LocationFailure.denied),
      );

      expect(find.text('현재 위치를 알 수 없어요'), findsOneWidget);
      expect(find.text('위치 설정'), findsWidgets);
      expect(find.textContaining('장소 정보: 카카오'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, '위치 설정'));
      await tester.pumpAndSettle();
      expect(find.text('위치 권한을 허용하지 않았어요'), findsOneWidget);
      // 서버 모드에서는 예시 위치를 보여주지 않는다.
      expect(find.text('예시 위치'), findsNothing);

      await tester.enterText(find.byType(TextField), '강남역');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('강남역 2호선'));
      await tester.pumpAndSettle();

      expect(find.text('강남역 2호선'), findsOneWidget); // 주변 화면 제목
      expect(find.text('현재 위치를 알 수 없어요'), findsNothing);
      expect(find.text('성수 할매순대국'), findsOneWidget);
      // 목록 맨 아래에 카카오 출처를 표시한다.
      await tester.scrollUntilVisible(
        find.textContaining('장소 정보: 카카오'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('장소 정보: 카카오'), findsOneWidget);
    });

    testWidgets('검색어가 한 글자면 안내한다', (tester) async {
      await pump(tester, const _SearchableLocations());
      await tester.tap(find.text('성수동2가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '강');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('두 글자 이상 입력해 주세요'), findsOneWidget);
    });
  });
}
