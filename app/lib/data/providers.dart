import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../core/geo.dart';
import '../domain/models/app_location.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/meal_log.dart';
import '../domain/models/restaurant.dart';
import '../domain/models/weather.dart';
import '../domain/recommend/recommend_engine.dart';
import 'app_config.dart';
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

/// 3단계에서 GPS와 연결한다. 지금은 예시 위치 중에서 고른다.
class LocationController extends Notifier<AppLocation> {
  @override
  AppLocation build() => sampleLocations.first;

  void select(AppLocation location) => state = location;
}

final locationProvider = NotifierProvider<LocationController, AppLocation>(
  LocationController.new,
);

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

final weatherProvider = FutureProvider<Weather>((ref) {
  final location = ref.watch(locationProvider);
  return ref
      .watch(weatherRepositoryProvider)
      .fetchCurrent(lat: location.lat, lng: location.lng);
});

// ── 주변 식당 ─────────────────────────────────────────

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => FakePlaceRepository(),
);

/// 현재 위치에서 검색 반경 안에 있는 식당. 가까운 순.
final nearbyPlacesProvider = FutureProvider<List<NearbyPlace>>((ref) async {
  final location = ref.watch(locationProvider);
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
});

/// 식당 상세 화면용. 현재 위치에서의 거리를 함께 준다.
final placeByIdProvider = FutureProvider.family<NearbyPlace?, String>((
  ref,
  id,
) async {
  final location = ref.watch(locationProvider);
  // 주변 목록을 먼저 받아야 가짜 저장소가 식당을 알고 있다.
  await ref.watch(nearbyPlacesProvider.future);
  final restaurant = await ref.watch(placeRepositoryProvider).findById(id);
  if (restaurant == null) return null;
  return NearbyPlace(
    restaurant: restaurant,
    distanceM: _roundedDistance(location, restaurant),
  );
});

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
