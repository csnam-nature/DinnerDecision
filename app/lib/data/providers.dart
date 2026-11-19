import 'dart:async';

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

final recommendEngineProvider = Provider<RecommendEngine>(
  (ref) => RecommendEngine(rules: ref.watch(appConfigProvider).weatherRules),
);

// ── 설정 ──────────────────────────────────────────────

/// 4단계에서 기기 DB에 저장한다. 지금은 앱을 끄면 처음 값으로 돌아간다.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void update(AppSettings Function(AppSettings current) change) =>
      state = change(state);

  void toggleDislike(String tag) {
    final tags = {...state.dislikedTags};
    if (!tags.remove(tag)) tags.add(tag);
    state = state.copyWith(dislikedTags: tags);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// 사용자가 숨긴 식당. id → 식당.
class ExcludedController extends Notifier<Map<String, Restaurant>> {
  @override
  Map<String, Restaurant> build() => const {};

  void hide(Restaurant restaurant) =>
      state = {...state, restaurant.id: restaurant};

  void restore(String id) => state = {...state}..remove(id);
}

final excludedProvider =
    NotifierProvider<ExcludedController, Map<String, Restaurant>>(
      ExcludedController.new,
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
    // 서버를 쓰면 처음 켤 때 GPS로 현재 위치를 찾는다.
    Future.microtask(locateMe);
    return const LocationState(locating: true);
  }

  /// GPS로 현재 위치를 찾는다. 실패하면 이전 위치를 그대로 두고 이유를 남긴다.
  Future<LocationFailure?> locateMe() async {
    state = LocationState(location: state.location, locating: true);
    try {
      final found = await ref.read(locationRepositoryProvider).current();
      if (!ref.mounted) return null;
      state = LocationState(location: found);
      return null;
    } on LocationException catch (e) {
      if (!ref.mounted) return e.failure;
      state = LocationState(location: state.location, failure: e.failure);
      return e.failure;
    }
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
  final (location, failure) = ref.watch(
    locationStateProvider.select((s) => (s.location, s.failure)),
  );
  if (location != null) return Future.value(location);
  if (failure != null) return Future.error(LocationException(failure));
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
  // 주변 목록을 먼저 받아야 가짜 저장소가 식당을 알고 있다.
  await ref.watch(nearbyPlacesProvider.future);
  final restaurant = await ref.watch(placeRepositoryProvider).findById(id);
  if (restaurant == null) return null;
  return NearbyPlace(
    restaurant: restaurant,
    distanceM: _roundedDistance(location, restaurant),
  );
}, retry: retryNetworkErrors);

int _roundedDistance(AppLocation from, Restaurant to) =>
    (distanceMeters(from.lat, from.lng, to.lat, to.lng) / 10).round() * 10;

// ── 식사 기록 ─────────────────────────────────────────

/// 식사 기록. 4단계에서 기기 DB(drift)로 바꾼다. 지금은 메모리에만 있다.
class MealLogController extends Notifier<List<MealLog>> {
  var _nextId = 1;

  @override
  List<MealLog> build() {
    final logs = sampleMealLogs(ref.watch(clockProvider)())
      ..sort(MealLog.newestFirst);
    _nextId = logs.fold(0, (max, log) => log.id > max ? log.id : max) + 1;
    return logs;
  }

  int newId() => _nextId++;

  /// 같은 id가 있으면 바꾸고, 없으면 더한다.
  void save(MealLog log) {
    state = [
      for (final existing in state)
        if (existing.id != log.id) existing,
      log,
    ]..sort(MealLog.newestFirst);
  }

  void delete(int id) => state = [
    for (final log in state)
      if (log.id != id) log,
  ];
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
