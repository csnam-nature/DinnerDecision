import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/meal_log.dart';
import '../../domain/models/restaurant.dart';
import 'codec.dart';
import 'stored_data.dart';

part 'app_database.g.dart';

/// 식사 기록 (PLAN.md 8장 meal_logs). id는 앱이 정한다.
class MealLogRows extends Table {
  @override
  String get tableName => 'meal_logs';

  IntColumn get id => integer()();

  /// yyyy-MM-dd. 시간대가 바뀌어도 날짜가 밀리지 않게 글자로 둔다.
  TextColumn get date => text()();
  TextColumn get mealType => text()();
  TextColumn get restaurantId => text().nullable()();
  TextColumn get restaurantName => text()();
  TextColumn get cuisine => text()();
  TextColumn get menu => text().withDefault(const Constant(''))();
  IntColumn get rating => integer().withDefault(const Constant(0))();
  TextColumn get memo => text().withDefault(const Constant(''))();

  /// 앱 폴더 photos/ 안의 파일 이름.
  TextColumn get photo => text().nullable()();
  TextColumn get weatherText => text().withDefault(const Constant(''))();
  BoolColumn get fromRecommend =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 기록하거나 숨긴 식당 정보 (PLAN.md 8장 restaurants).
class RestaurantRows extends Table {
  @override
  String get tableName => 'restaurants';

  TextColumn get id => text()();

  /// Codec.restaurant 의 JSON. 항목이 늘어도 표를 바꾸지 않아도 된다.
  TextColumn get data => text()();
  BoolColumn get excluded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 설정 등 이름-값.
class KeyValueRows extends Table {
  @override
  String get tableName => 'key_values';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [MealLogRows, RestaurantRows, KeyValueRows])
class AppDatabase extends _$AppDatabase implements LocalStore {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'dinner_decision'));

  /// 표를 바꾸면 올리고 [migration]에 옮기는 방법을 적는다.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
  );

  static const _settingsKey = 'settings';
  static const _onboardingKey = 'onboarding_done';

  @override
  Future<StoredData> load() async {
    final logs = await select(mealLogRows).get();
    final restaurants = await select(restaurantRows).get();
    final values = {
      for (final kv in await select(keyValueRows).get()) kv.key: kv.value,
    };
    final settingsJson = values[_settingsKey];
    return StoredData(
      logs: [for (final row in logs) _toLog(row)]..sort(MealLog.newestFirst),
      settings: settingsJson == null
          ? const AppSettings()
          : Codec.parseSettings(
              jsonDecode(settingsJson) as Map<String, Object?>,
            ),
      excludedIds: {
        for (final r in restaurants)
          if (r.excluded) r.id,
      },
      restaurants: {
        for (final r in restaurants)
          r.id: Codec.parseRestaurant(
            jsonDecode(r.data) as Map<String, Object?>,
          ),
      },
      onboardingDone: values[_onboardingKey] == '1',
    );
  }

  MealLog _toLog(MealLogRow row) => Codec.parseMealLog({
    'id': row.id,
    'date': row.date,
    'mealType': row.mealType,
    'restaurantId': row.restaurantId,
    'restaurantName': row.restaurantName,
    'cuisine': row.cuisine,
    'menu': row.menu,
    'rating': row.rating,
    'memo': row.memo,
    'photo': row.photo,
    'weatherText': row.weatherText,
    'fromRecommend': row.fromRecommend,
  });

  MealLogRowsCompanion _logRow(MealLog l) => MealLogRowsCompanion.insert(
    id: Value(l.id),
    date: Codec.date(l.date),
    mealType: l.mealType.name,
    restaurantId: Value(l.restaurantId),
    restaurantName: l.restaurantName,
    cuisine: l.cuisine.name,
    menu: Value(l.menu),
    rating: Value(l.rating),
    memo: Value(l.memo),
    photo: Value(l.photoPath),
    weatherText: Value(l.weatherText),
    fromRecommend: Value(l.fromRecommend),
    updatedAt: DateTime.now(),
  );

  /// 식당 정보만 고치고 '숨김' 여부는 그대로 둔다.
  Future<void> _upsertRestaurant(Restaurant r, {bool? excluded}) {
    final data = jsonEncode(Codec.restaurant(r));
    final now = DateTime.now();
    return into(restaurantRows).insert(
      RestaurantRowsCompanion.insert(
        id: r.id,
        data: data,
        excluded: Value(excluded ?? false),
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (_) => RestaurantRowsCompanion(
          data: Value(data),
          updatedAt: Value(now),
          excluded: excluded == null ? const Value.absent() : Value(excluded),
        ),
      ),
    );
  }

  @override
  Future<void> saveLog(MealLog log, {Restaurant? restaurant}) =>
      transaction(() async {
        await into(mealLogRows).insertOnConflictUpdate(_logRow(log));
        if (restaurant != null) await _upsertRestaurant(restaurant);
      });

  @override
  Future<void> deleteLog(int id) =>
      (delete(mealLogRows)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> saveSettings(AppSettings settings) => into(keyValueRows)
      .insertOnConflictUpdate(
        KeyValueRowsCompanion.insert(
          key: _settingsKey,
          value: jsonEncode(Codec.settings(settings)),
        ),
      );

  @override
  Future<void> setExcluded(Restaurant restaurant, {required bool excluded}) =>
      _upsertRestaurant(restaurant, excluded: excluded);

  @override
  Future<void> setOnboardingDone() => into(keyValueRows).insertOnConflictUpdate(
    KeyValueRowsCompanion.insert(key: _onboardingKey, value: '1'),
  );

  @override
  Future<void> replaceAll(StoredData data) => transaction(() async {
    await delete(mealLogRows).go();
    await delete(restaurantRows).go();
    await batch((b) {
      b.insertAll(mealLogRows, [for (final l in data.logs) _logRow(l)]);
    });
    for (final r in data.restaurants.values) {
      await _upsertRestaurant(r, excluded: data.excludedIds.contains(r.id));
    }
    await saveSettings(data.settings);
    if (data.onboardingDone) await setOnboardingDone();
  });
}
