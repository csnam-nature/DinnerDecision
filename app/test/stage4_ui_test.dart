import 'dart:io';

import 'package:dinner_decision/app/app.dart';
import 'package:dinner_decision/data/api/api_client.dart';
import 'package:dinner_decision/data/device_files.dart';
import 'package:dinner_decision/data/local/photo_store.dart';
import 'package:dinner_decision/data/local/stored_data.dart';
import 'package:dinner_decision/data/providers.dart';
import 'package:dinner_decision/data/repositories/location_repository.dart';
import 'package:dinner_decision/data/repositories/place_repository.dart';
import 'package:dinner_decision/domain/models/app_location.dart';
import 'package:dinner_decision/domain/models/cuisine.dart';
import 'package:dinner_decision/domain/models/restaurant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

class PickOnePhoto implements DeviceFiles {
  PickOnePhoto(this.path);

  final String path;

  @override
  Future<String?> pickPhoto(PhotoSource source) async => path;

  @override
  Future<void> share(String path, {required String subject}) async {}

  @override
  Future<List<int>?> pickBackup() async => null;

  @override
  Future<Directory> tempDir() async => Directory.systemTemp;
}

const farAway = Restaurant(
  id: 'far-1',
  name: '부산 돼지국밥',
  categoryRaw: '음식점 > 한식 > 국밥',
  cuisine: Cuisine.korean,
  subCategory: '국밥',
  tags: ['국밥'],
  roadAddress: '부산 부산진구 중앙대로 1',
  phone: '',
  lat: 35.15,
  lng: 129.05,
);

void main() {
  List<Override> serverMode(
    LocalStore store,
    StoredData data, {
    LocationRepository location = const FakeLocationRepository(),
    PlaceRepository? places,
  }) => [
    appConfigProvider.overrideWithValue(loadTestConfig()),
    clockProvider.overrideWithValue(() => testToday),
    apiClientProvider.overrideWithValue(ApiClient(baseUrl: 'https://api.test')),
    placeRepositoryProvider.overrideWithValue(
      places ?? FakePlaceRepository(delay: Duration.zero),
    ),
    locationRepositoryProvider.overrideWithValue(location),
    localStoreProvider.overrideWithValue(store),
    storedDataProvider.overrideWith(() => StoredDataController(data)),
  ];

  Future<void> pumpApp(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const DinnerDecisionApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('처음 켜면 안내 화면이 나오고, 허용하면 주변 목록으로 간다', (tester) async {
    final store = MemoryStore();
    await pumpApp(tester, serverMode(store, const StoredData()));

    expect(find.text('위치 권한 허용하기'), findsOneWidget);
    await tester.tap(find.text('위치 권한 허용하기'));
    await tester.pumpAndSettle();

    expect(find.text('성수 할매순대국'), findsOneWidget);
    expect((await store.load()).onboardingDone, isTrue);
  });

  testWidgets('안내 화면에서 나중에를 누르면 위치 설정으로 간다', (tester) async {
    await pumpApp(tester, serverMode(MemoryStore(), const StoredData()));
    await tester.tap(find.text('나중에 (위치 직접 설정)'));
    await tester.pumpAndSettle();
    expect(find.text('위치 설정'), findsOneWidget);
    expect(find.text('현재 위치 사용'), findsOneWidget);
  });

  testWidgets('한 번 안내를 마쳤으면 바로 주변 목록이 나온다', (tester) async {
    await pumpApp(
      tester,
      serverMode(MemoryStore(), const StoredData(onboardingDone: true)),
    );
    expect(find.text('위치 권한 허용하기'), findsNothing);
    expect(find.text('성수 할매순대국'), findsOneWidget);
  });

  testWidgets('기록에 사진을 붙여 저장한다', (tester) async {
    final temp = Directory.systemTemp.createTempSync('dinner_photo');
    addTearDown(() => temp.deleteSync(recursive: true));
    final picked = File('${temp.path}/picked.jpg')..writeAsBytesSync([1, 2]);
    final photos = PhotoStore(Directory('${temp.path}/photos'));
    final store = MemoryStore();

    await pumpApp(tester, [
      ...serverMode(store, const StoredData(onboardingDone: true)),
      photoStoreProvider.overrideWithValue(photos),
      deviceFilesProvider.overrideWithValue(PickOnePhoto(picked.path)),
    ]);
    await tester.tap(find.text('성수 할매순대국'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘 여기서 먹었어요'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('사진 추가'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('사진 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 고르기'));
    // 사진 복사는 실제 파일 작업이라 진짜 시간이 조금 흘러야 끝난다.
    for (var i = 0; i < 20 && find.byTooltip('사진 빼기').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.byTooltip('사진 빼기'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    final saved = (await store.load()).logs.single;
    expect(saved.restaurantName, '성수 할매순대국');
    expect(saved.photoPath, isNotNull);
    expect(photos.file(saved.photoPath!).readAsBytesSync(), [1, 2]);
    // 기록할 때 식당 정보도 저장해 둔다.
    expect((await store.load()).restaurants.keys, contains(saved.restaurantId));
  });

  test('주변에 없는 식당도 저장해 둔 정보로 상세를 연다', () async {
    final container = ProviderContainer(
      overrides: [
        ...serverMode(
          MemoryStore(),
          const StoredData(
            onboardingDone: true,
            restaurants: {'far-1': farAway},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(placeByIdProvider('far-1'), (_, _) {});
    await container.read(locationStateProvider.notifier).locateMe();
    final place = await container.read(placeByIdProvider('far-1').future);
    expect(place?.restaurant.name, '부산 돼지국밥');
    expect(place!.distanceM, greaterThan(300000)); // 서울에서 부산
  });

  test('인터넷과 위치 권한이 없어도 기록한 식당의 상세는 열린다', () async {
    final container = ProviderContainer(
      overrides: [
        ...serverMode(
          MemoryStore(),
          const StoredData(
            onboardingDone: true,
            restaurants: {'far-1': farAway},
          ),
          places: _OfflinePlaces(),
          location: const FakeLocationRepository(
            failure: LocationFailure.denied,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(placeByIdProvider('far-1'), (_, _) {});
    await container.read(locationStateProvider.notifier).locateMe();
    final place = await container.read(placeByIdProvider('far-1').future);
    expect(place?.restaurant.name, '부산 돼지국밥');
    expect(place!.distanceM, isNull); // 위치를 모르면 거리는 비워 둔다
  });

  testWidgets('안내 화면에서 나중에를 누르면 GPS를 찾지 않는다', (tester) async {
    final locations = _CountingLocations();
    await pumpApp(tester, [
      ...serverMode(MemoryStore(), const StoredData(), location: locations),
    ]);
    await tester.tap(find.text('나중에 (위치 직접 설정)'));
    await tester.pumpAndSettle();
    expect(find.text('위치 설정'), findsOneWidget);
    expect(locations.calls, 0);
  });

  testWidgets('안내 화면에서 허용하면 GPS를 한 번만 찾는다', (tester) async {
    final locations = _CountingLocations();
    await pumpApp(tester, [
      ...serverMode(MemoryStore(), const StoredData(), location: locations),
    ]);
    await tester.tap(find.text('위치 권한 허용하기'));
    await tester.pumpAndSettle();
    expect(locations.calls, 1);
    expect(find.text('성수 할매순대국'), findsOneWidget);
  });
}

class _OfflinePlaces implements PlaceRepository {
  @override
  Future<List<Restaurant>> fetchNearby({
    required double lat,
    required double lng,
    required int radiusM,
  }) async => throw const ApiException(ApiException.network, '오프라인');

  @override
  Future<Restaurant?> findById(String id) async => null;
}

class _CountingLocations extends FakeLocationRepository {
  var calls = 0;

  @override
  Future<AppLocation> current() {
    calls++;
    return super.current();
  }
}
