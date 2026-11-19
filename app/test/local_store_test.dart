import 'package:dinner_decision/data/local/app_database.dart';
import 'package:dinner_decision/data/local/codec.dart';
import 'package:dinner_decision/data/local/stored_data.dart';
import 'package:dinner_decision/domain/models/app_settings.dart';
import 'package:dinner_decision/domain/models/cuisine.dart';
import 'package:dinner_decision/domain/models/meal_log.dart';
import 'package:dinner_decision/domain/models/restaurant.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const r1 = Restaurant(
  id: 'k1',
  name: '성수 할매순대국',
  categoryRaw: '음식점 > 한식 > 순대',
  cuisine: Cuisine.korean,
  subCategory: '순대',
  tags: ['국밥', '순대'],
  roadAddress: '서울 성동구 성수이로 1',
  phone: '02-000-0000',
  lat: 37.5446,
  lng: 127.0559,
  kakaoUrl: 'http://place.map.kakao.com/1',
);

MealLog log(int id, {String? restaurantId = 'k1', String? photo}) => MealLog(
  id: id,
  date: DateTime(2026, 11, id),
  mealType: MealType.dinner,
  restaurantId: restaurantId,
  restaurantName: '성수 할매순대국',
  cuisine: Cuisine.korean,
  menu: '순대국',
  rating: 4,
  memo: '진해요',
  photoPath: photo,
  weatherText: '☔ 비 · 9℃',
  fromRecommend: true,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('처음에는 비어 있고 온보딩 전이다', () async {
    final data = await db.load();
    expect(data.logs, isEmpty);
    expect(data.onboardingDone, isFalse);
    expect(data.settings.radiusM, const AppSettings().radiusM);
  });

  test('기록과 식당 정보를 저장하고 그대로 읽는다', () async {
    await db.saveLog(log(3, photo: 'a.jpg'), restaurant: r1);
    await db.saveLog(log(5));
    final data = await db.load();
    expect(data.logs.map((l) => l.id), [5, 3]); // 최근 기록 먼저
    final saved = data.logs.last;
    expect(Codec.mealLog(saved), Codec.mealLog(log(3, photo: 'a.jpg')));
    expect(data.restaurants['k1']?.name, '성수 할매순대국');
    expect(data.restaurants['k1']?.tags, ['국밥', '순대']);
  });

  test('같은 id로 저장하면 고치고, 지우면 없어진다', () async {
    await db.saveLog(log(3));
    await db.saveLog(
      MealLog(
        id: 3,
        date: DateTime(2026, 11, 4),
        mealType: MealType.lunch,
        restaurantName: '집밥·배달',
        cuisine: Cuisine.etc,
      ),
    );
    var data = await db.load();
    expect(data.logs.single.mealType, MealType.lunch);
    expect(data.logs.single.restaurantId, isNull);

    await db.deleteLog(3);
    data = await db.load();
    expect(data.logs, isEmpty);
  });

  test('숨긴 식당은 기록을 다시 저장해도 숨김이 유지된다', () async {
    await db.setExcluded(r1, excluded: true);
    await db.saveLog(log(1), restaurant: r1);
    var data = await db.load();
    expect(data.excludedIds, {'k1'});
    expect(data.excluded.keys, ['k1']);

    await db.setExcluded(r1, excluded: false);
    data = await db.load();
    expect(data.excludedIds, isEmpty);
    expect(data.restaurants, contains('k1'));
  });

  test('설정과 온보딩 완료를 저장한다', () async {
    await db.saveSettings(
      const AppSettings(
        radiusM: 2000,
        includeEtc: true,
        themeMode: AppThemeMode.dark,
        dislikedTags: {'회', '매운'},
      ),
    );
    await db.setOnboardingDone();
    final data = await db.load();
    expect(data.settings.radiusM, 2000);
    expect(data.settings.includeEtc, isTrue);
    expect(data.settings.themeMode, AppThemeMode.dark);
    expect(data.settings.dislikedTags, {'회', '매운'});
    expect(data.onboardingDone, isTrue);
  });

  test('복원하면 전부 바뀐다', () async {
    await db.saveLog(log(9), restaurant: r1);
    await db.replaceAll(
      StoredData(
        logs: [log(1), log(2)],
        excludedIds: const {'k1'},
        restaurants: const {'k1': r1},
        settings: const AppSettings(radiusM: 500),
        onboardingDone: true,
      ),
    );
    final data = await db.load();
    expect(data.logs.map((l) => l.id), [2, 1]);
    expect(data.excludedIds, {'k1'});
    expect(data.settings.radiusM, 500);
  });

  test('MemoryStore도 같은 규칙으로 동작한다', () async {
    final store = MemoryStore();
    await store.setExcluded(r1, excluded: true);
    await store.saveLog(log(1), restaurant: r1);
    await store.deleteLog(1);
    final data = await store.load();
    expect(data.logs, isEmpty);
    expect(data.excludedIds, {'k1'});
  });
}
