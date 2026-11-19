import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../core/geo.dart';
import '../domain/models/app_location.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/meal_log.dart';
import '../domain/models/restaurant.dart';
import '../domain/models/weather.dart';
import '../domain/recommend/recommend_engine.dart';
import 'api/api_client.dart';
import 'app_config.dart';
import 'device_files.dart';
import 'external_launcher.dart';
import 'local/backup_service.dart';
import 'local/photo_store.dart';
import 'local/stored_data.dart';
import 'repositories/location_repository.dart';
import 'repositories/place_repository.dart';
import 'repositories/weather_repository.dart';
import 'sample/sample_data.dart';

/// 지금 시각. 테스트에서 날짜를 고정하려고 따로 둔다.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// main()에서 읽은 규칙 파일. ProviderScope에서 값을 넣어 준다.
final appConfigProvider = Provider<AppConfig>(
  (ref) =>
      throw UnimplementedError('ProviderScope에서 appConfigProvider 값을 넣어야 합니다'),
);

/// 서버 클라이언트. 서버 주소(API_BASE_URL) 없이 빌드하면 null이고, 예시 데이터로 동작한다.
final apiClientProvider = Provider<ApiClient?>(
  (ref) => apiBaseUrl.isEmpty ? null : ApiClient(baseUrl: apiBaseUrl),
);

/// 예시 데이터로 동작하는지. 화면의 '예시 데이터' 안내에 쓴다.
final usesSampleDataProvider = Provider<bool>(
  (ref) => ref.watch(apiClientProvider) == null,
);

/// 다른 앱·웹 열기 (네이버 지도, 카카오 장소, 전화).
final externalLauncherProvider = Provider<ExternalLauncher>(
  (ref) => const UrlLauncherExternal(),
);

final restaurantLinksProvider = Provider<RestaurantLinks>(
  (ref) => RestaurantLinks(ref.watch(externalLauncherProvider)),
);

final recommendEngineProvider = Provider<RecommendEngine>(
  (ref) => RecommendEngine(rules: ref.watch(appConfigProvider).weatherRules),
);

// ── 기기 저장 ────────────────────────────────────────

/// 기기 저장소. main()에서 서버 모드면 기기 DB(drift)로 바꿔 넣는다.
/// 기본값(예시 데이터 모드·테스트)은 저장하지 않는 메모리 저장소.
final localStoreProvider = Provider<LocalStore>((ref) => MemoryStore());

/// 앱을 켤 때 기기에서 읽은 값. 백업에서 복원하면 통째로 바뀌고,
/// 기록·설정·숨긴 식당 controller들이 이 값으로 다시 시작한다.
class StoredDataController extends Notifier<StoredData> {
  StoredDataController([this._initial]);

  final StoredData? _initial;

  @override
  StoredData build() =>
      _initial ??
      StoredData(
        logs: sampleMealLogs(ref.read(clockProvider)()),
        onboardingDone: true,
      );

  void replace(StoredData data) => state = data;
}

final storedDataProvider = NotifierProvider<StoredDataController, StoredData>(
  StoredDataController.new,
);

/// 기록 사진 폴더. main()에서 앱 폴더로 정해 넣는다. null이면 사진 기능을 숨긴다.
final photoStoreProvider = Provider<PhotoStore?>((ref) => null);

/// 사진 고르기·파일 공유·파일 고르기.
final deviceFilesProvider = Provider<DeviceFiles>(
  (ref) => const PlatformDeviceFiles(),
);

final backupServiceProvider = Provider<BackupService>(BackupService.new);

/// 저장은 기다리지 않는다. 화면은 메모리 값으로 바로 바뀌고, 실패하면 로그만 남긴다.
void _persist(Future<void> write, String what) {
  unawaited(write.catchError((Object e) => debugPrint('기기 저장 실패($what): $e')));
}

// ── 설정 ──────────────────────────────────────────────

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      ref.watch(storedDataProvider.select((d) => d.settings));

  void update(AppSettings Function(AppSettings current) change) {
    state = change(state);
    _persist(ref.read(localStoreProvider).saveSettings(state), '설정');
  }

  void toggleDislike(String tag) {
    final tags = {...state.dislikedTags};
    if (!tags.remove(tag)) tags.add(tag);
    update((s) => s.copyWith(dislikedTags: tags));
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// 기록하거나 숨길 때 저장해 둔 식당 정보. 지금 주변에 없는 식당의 상세에 쓴다.
class KnownRestaurantsController extends Notifier<Map<String, Restaurant>> {
  @override
  Map<String, Restaurant> build() =>
      ref.watch(storedDataProvider.select((d) => d.restaurants));

  void remember(Restaurant r) => state = {...state, r.id: r};
}

final knownRestaurantsProvider =
    NotifierProvider<KnownRestaurantsController, Map<String, Restaurant>>(
      KnownRestaurantsController.new,
    );

/// 사용자가 숨긴 식당. id → 식당.
class ExcludedController extends Notifier<Map<String, Restaurant>> {
  @override
  Map<String, Restaurant> build() =>
      ref.watch(storedDataProvider.select((d) => d.excluded));

  void hide(Restaurant restaurant) {
    state = {...state, restaurant.id: restaurant};
    ref.read(knownRestaurantsProvider.notifier).remember(restaurant);
    _persist(
      ref.read(localStoreProvider).setExcluded(restaurant, excluded: true),
      '숨긴 식당',
    );
  }

  void restore(String id) {
    final restaurant = state[id];
    if (restaurant == null) return;
    state = {...state}..remove(id);
    _persist(
      ref.read(localStoreProvider).setExcluded(restaurant, excluded: false),
      '숨긴 식당',
    );
  }
}

final excludedProvider =
    NotifierProvider<ExcludedController, Map<String, Restaurant>>(
      ExcludedController.new,
    );

/// 첫 실행 안내(온보딩)를 마쳤는지.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(storedDataProvider.select((d) => d.onboardingDone));

  void complete() {
    if (state) return;
    state = true;
    _persist(ref.read(localStoreProvider).setOnboardingDone(), '온보딩');
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

// ── 위치·날씨 ─────────────────────────────────────────

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return client == null
      ? const FakeLocationRepository()
      : DeviceLocationRepository(client);
});

/// 기준 위치와 GPS로 찾는 중인지, 실패했는지.
class LocationState {
  const LocationState({this.location, this.locating = false, this.failure});

  /// 아직 못 정했으면 null.
  final AppLocation? location;
  final bool locating;
  final LocationFailure? failure;
}

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() {
    if (ref.watch(usesSampleDataProvider)) {
      return LocationState(location: sampleLocations.first);
    }
    // 첫 실행 안내 중이면 안내 화면에서 위치 권한을 물은 뒤에 찾는다.
    if (!ref.read(onboardingDoneProvider)) return const LocationState();
    // 서버를 쓰면 켤 때 GPS로 현재 위치를 찾는다.
    Future.microtask(locateMe);
    return const LocationState(locating: true);
  }

  /// GPS로 현재 위치를 찾는다. 실패하면 이전 위치를 그대로 두고 이유를 남긴다.
  Future<LocationFailure?>? _running;

  /// 이미 찾는 중이면 새로 시작하지 않고 그 결과를 같이 기다린다.
  /// (권한 창이 떠 있는데 또 요청하면 geolocator가 오류를 낸다.)
  Future<LocationFailure?> locateMe() =>
      _running ??= _locate().whenComplete(() => _running = null);

  Future<LocationFailure?> _locate() async {
    state = LocationState(location: state.location, locating: true);
    LocationFailure failure;
    try {
      final found = await ref.read(locationRepositoryProvider).current();
      if (!ref.mounted) return null;
      state = LocationState(location: found);
      return null;
    } on LocationException catch (e) {
      failure = e.failure;
    } on Object catch (e) {
      // 예상하지 못한 오류(플랫폼 오류 등)도 '찾는 중'에 멈춰 있지 않게 실패로 둔다.
      debugPrint('위치 찾기 실패: $e');
      failure = LocationFailure.timeout;
    }
    if (ref.mounted) {
      state = LocationState(location: state.location, failure: failure);
    }
    return failure;
  }

  void select(AppLocation location) =>
      state = LocationState(location: location);
}

final locationStateProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

/// 기준 위치. 아직 못 정했으면 null.
final locationProvider = Provider<AppLocation?>(
  (ref) => ref.watch(locationStateProvider).location,
);

/// 실패한 불러오기를 다시 할지. Riverpod 3은 기본으로 모든 오류를 10번까지 다시 하는데,
/// 위치 권한·서버 호출 제한 같은 오류는 다시 해도 소용이 없어서 네트워크 오류만 2번 다시 한다.
Duration? retryNetworkErrors(int retryCount, Object error) {
  if (error is ApiException && error.isOffline && retryCount < 2) {
    return Duration(seconds: 1 << retryCount);
  }
  return null;
}

/// 위치가 정해질 때까지 기다린다. GPS가 실패했고 위치가 없으면 [LocationException].
Future<AppLocation> _requireLocation(Ref ref) {
  // '찾는 중' 표시만 바뀔 때는 목록을 다시 불러오지 않도록 위치와 실패 이유만 본다.
  final (location, failure, notSet) = ref.watch(
    locationStateProvider.select(
      (s) => (s.location, s.failure, s.location == null && !s.locating),
    ),
  );
  if (location != null) return Future.value(location);
  if (failure != null) return Future.error(LocationException(failure));
  if (notSet) {
    return Future.error(const LocationException(LocationFailure.notSet));
  }
  // 위치가 바뀌면 이 provider가 다시 계산되므로 그때까지 '불러오는 중'으로 둔다.
  return Completer<AppLocation>().future;
}

/// 설정의 '예시 날씨'. 실제 날씨를 붙이면 없앤다.
class SampleWeatherController extends Notifier<SampleWeather> {
  @override
  SampleWeather build() => SampleWeather.rain;

  void select(SampleWeather value) => state = value;
}

final sampleWeatherProvider =
    NotifierProvider<SampleWeatherController, SampleWeather>(
      SampleWeatherController.new,
    );

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => FakeWeatherRepository(ref.watch(sampleWeatherProvider).weather),
);

final weatherProvider = FutureProvider<Weather>((ref) async {
  final location = await _requireLocation(ref);
  return ref
      .watch(weatherRepositoryProvider)
      .fetchCurrent(lat: location.lat, lng: location.lng);
}, retry: retryNetworkErrors);

// ── 주변 식당 ─────────────────────────────────────────

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return client == null
      ? FakePlaceRepository()
      : ApiPlaceRepository(
          client: client,
          mapper: ref.watch(appConfigProvider).cuisineMapper,
        );
});

/// 현재 위치에서 검색 반경 안에 있는 식당. 가까운 순.
final nearbyPlacesProvider = FutureProvider<List<NearbyPlace>>((ref) async {
  final location = await _requireLocation(ref);
  final radiusM = ref.watch(settingsProvider.select((s) => s.radiusM));
  final restaurants = await ref
      .watch(placeRepositoryProvider)
      .fetchNearby(lat: location.lat, lng: location.lng, radiusM: radiusM);
  final places = [
    for (final r in restaurants)
      NearbyPlace(restaurant: r, distanceM: _roundedDistance(location, r)),
  ];
  return places.where((p) => p.distanceM <= radiusM).toList()
    ..sort((a, b) => a.distanceM.compareTo(b.distanceM));
}, retry: retryNetworkErrors);

/// 식당 상세 화면용. 현재 위치에서의 거리를 함께 준다.
final placeByIdProvider = FutureProvider.family<NearbyPlace?, String>((
  ref,
  id,
) async {
  final location = await _requireLocation(ref);
  // 주변 목록을 먼저 받아야 저장소가 식당을 알고 있다.
  await ref.watch(nearbyPlacesProvider.future);
  final restaurant =
      await ref.watch(placeRepositoryProvider).findById(id) ??
      // 지금 주변에 없으면 기록할 때 저장해 둔 정보로 보여준다.
      ref.watch(knownRestaurantsProvider)[id];
  if (restaurant == null) return null;
  return NearbyPlace(
    restaurant: restaurant,
    distanceM: _roundedDistance(location, restaurant),
  );
}, retry: retryNetworkErrors);

int _roundedDistance(AppLocation from, Restaurant to) =>
    (distanceMeters(from.lat, from.lng, to.lat, to.lng) / 10).round() * 10;

// ── 식사 기록 ─────────────────────────────────────────

/// 식사 기록. 최근 기록이 앞에 온다.
class MealLogController extends Notifier<List<MealLog>> {
  var _nextId = 1;

  @override
  List<MealLog> build() {
    final logs = [...ref.watch(storedDataProvider.select((d) => d.logs))]
      ..sort(MealLog.newestFirst);
    _nextId = logs.fold(0, (max, log) => log.id > max ? log.id : max) + 1;
    return logs;
  }

  int newId() => _nextId++;

  /// 같은 id가 있으면 바꾸고, 없으면 더한다.
  /// [restaurant]가 있으면 식당 정보도 저장해 두어 나중에 상세를 열 수 있게 한다.
  void save(MealLog log, {Restaurant? restaurant}) {
    state = [
      for (final existing in state)
        if (existing.id != log.id) existing,
      log,
    ]..sort(MealLog.newestFirst);
    if (log.id >= _nextId) _nextId = log.id + 1;
    if (restaurant != null) {
      ref.read(knownRestaurantsProvider.notifier).remember(restaurant);
    }
    _persist(
      ref.read(localStoreProvider).saveLog(log, restaurant: restaurant),
      '기록',
    );
  }

  void delete(int id) {
    state = [
      for (final log in state)
        if (log.id != id) log,
    ];
    _persist(ref.read(localStoreProvider).deleteLog(id), '기록 삭제');
  }
}

final mealLogsProvider = NotifierProvider<MealLogController, List<MealLog>>(
  MealLogController.new,
);

/// 식당 id → 마지막으로 간 지 며칠 됐는지.
final lastVisitDaysProvider = Provider<Map<String, int>>((ref) {
  final today = ref.watch(clockProvider)();
  final result = <String, int>{};
  for (final log in ref.watch(mealLogsProvider)) {
    final id = log.restaurantId;
    if (id == null) continue;
    final days = daysBetween(log.date, today);
    if (!result.containsKey(id) || days < result[id]!) result[id] = days;
  }
  return result;
});
