import '../../domain/models/app_settings.dart';
import '../../domain/models/meal_log.dart';
import '../../domain/models/restaurant.dart';

/// 기기에 저장된 것 전부. 앱을 켤 때 한 번 읽어 메모리에 올리고,
/// 바뀔 때마다 [LocalStore]로 바로 저장한다. 기록은 1년에 수백 건이라 전부 올려도 가볍다.
class StoredData {
  const StoredData({
    this.logs = const [],
    this.settings = const AppSettings(),
    this.excludedIds = const {},
    this.restaurants = const {},
    this.onboardingDone = false,
  });

  final List<MealLog> logs;
  final AppSettings settings;

  /// '안 갈 식당'으로 숨긴 식당 id.
  final Set<String> excludedIds;

  /// 기록하거나 숨길 때 저장해 둔 식당 정보. 지금 주변 목록에 없는 식당의 상세에 쓴다.
  final Map<String, Restaurant> restaurants;
  final bool onboardingDone;

  Map<String, Restaurant> get excluded => {
    for (final id in excludedIds) id: ?restaurants[id],
  };
}

/// 기기 저장소. 화면은 이것만 알고, 실제 구현은 drift(SQLite) 또는 메모리.
abstract interface class LocalStore {
  Future<StoredData> load();

  /// 기록을 넣거나 고친다. [restaurant]가 있으면 식당 정보도 저장해 둔다.
  Future<void> saveLog(MealLog log, {Restaurant? restaurant});

  Future<void> deleteLog(int id);

  Future<void> saveSettings(AppSettings settings);

  Future<void> setExcluded(Restaurant restaurant, {required bool excluded});

  Future<void> setOnboardingDone();

  /// 백업에서 복원할 때 전부 바꾼다.
  Future<void> replaceAll(StoredData data);
}

/// 저장하지 않는 구현. 예시 데이터 모드와 테스트에서 쓴다.
class MemoryStore implements LocalStore {
  MemoryStore([this._data = const StoredData()]);

  StoredData _data;

  @override
  Future<StoredData> load() async => _data;

  @override
  Future<void> saveLog(MealLog log, {Restaurant? restaurant}) async {
    _data = StoredData(
      logs: [
        for (final l in _data.logs)
          if (l.id != log.id) l,
        log,
      ],
      settings: _data.settings,
      excludedIds: _data.excludedIds,
      restaurants: {
        ..._data.restaurants,
        ...?restaurant == null ? null : {restaurant.id: restaurant},
      },
      onboardingDone: _data.onboardingDone,
    );
  }

  @override
  Future<void> deleteLog(int id) async => _data = StoredData(
    logs: [
      for (final l in _data.logs)
        if (l.id != id) l,
    ],
    settings: _data.settings,
    excludedIds: _data.excludedIds,
    restaurants: _data.restaurants,
    onboardingDone: _data.onboardingDone,
  );

  @override
  Future<void> saveSettings(AppSettings settings) async => _data = StoredData(
    logs: _data.logs,
    settings: settings,
    excludedIds: _data.excludedIds,
    restaurants: _data.restaurants,
    onboardingDone: _data.onboardingDone,
  );

  @override
  Future<void> setExcluded(
    Restaurant restaurant, {
    required bool excluded,
  }) async => _data = StoredData(
    logs: _data.logs,
    settings: _data.settings,
    excludedIds: excluded
        ? {..._data.excludedIds, restaurant.id}
        : ({..._data.excludedIds}..remove(restaurant.id)),
    restaurants: {..._data.restaurants, restaurant.id: restaurant},
    onboardingDone: _data.onboardingDone,
  );

  @override
  Future<void> setOnboardingDone() async => _data = StoredData(
    logs: _data.logs,
    settings: _data.settings,
    excludedIds: _data.excludedIds,
    restaurants: _data.restaurants,
    onboardingDone: true,
  );

  @override
  Future<void> replaceAll(StoredData data) async => _data = data;
}
