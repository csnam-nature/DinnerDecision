import 'dart:math';

import 'package:dinner_decision/core/geo.dart';
import 'package:dinner_decision/data/sample/sample_data.dart';
import 'package:dinner_decision/domain/models/app_settings.dart';
import 'package:dinner_decision/domain/models/cuisine.dart';
import 'package:dinner_decision/domain/models/meal_log.dart';
import 'package:dinner_decision/domain/models/restaurant.dart';
import 'package:dinner_decision/domain/models/weather.dart';
import 'package:dinner_decision/domain/recommend/recommend_engine.dart';
import 'package:dinner_decision/domain/recommend/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  final rules = loadTestConfig().weatherRules;
  final here = sampleLocations.first;
  final places = [
    for (final r in sampleRestaurantsAround(here.lat, here.lng))
      NearbyPlace(
        restaurant: r,
        distanceM:
            (distanceMeters(here.lat, here.lng, r.lat, r.lng) / 10).round() *
            10,
      ),
  ];
  final logs = sampleMealLogs(testToday);

  /// 무작위 뽑기까지 포함해 여러 번 돌려서, 나올 수 있는 추천을 모두 모은다.
  List<Recommendation> picksOverSeeds(
    Weather? weather, {
    AppSettings settings = const AppSettings(),
    List<MealLog>? withLogs,
    Set<String> excluded = const {},
    Set<String> skipped = const {},
    Cuisine? lock,
  }) {
    return [
      for (var seed = 0; seed < 40; seed++)
        ...RecommendEngine(rules: rules, random: Random(seed))
            .recommend(
              places: places,
              logs: withLogs ?? logs,
              weather: weather,
              settings: settings,
              today: testToday,
              excludedIds: excluded,
              skippedIds: skipped,
              lockCuisine: lock,
            )
            .picks,
    ];
  }

  String id(Recommendation r) => r.place.restaurant.id;
  final rain = SampleWeather.rain.weather;

  test('세 곳을 점수가 높은 순서로 돌려준다', () {
    final result = RecommendEngine(rules: rules, random: Random(1)).recommend(
      places: places,
      logs: logs,
      weather: rain,
      settings: const AppSettings(),
      today: testToday,
    );
    expect(result.picks, hasLength(3));
    expect(result.picks.map(id).toSet(), hasLength(3));
    expect(result.picks[0].score, greaterThanOrEqualTo(result.picks[1].score));
    expect(result.picks[1].score, greaterThanOrEqualTo(result.picks[2].score));
    expect(result.relaxed, isFalse);
    // 마지막 이유는 항상 거리.
    expect(result.picks.first.reasons.last.code, ReasonCode.near);
    expect(result.picks.first.reasons.length, lessThanOrEqualTo(4));
  });

  test('최근 7일 안에 간 식당은 추천하지 않는다', () {
    // 예시 기록: 1일 전 트라토리아(19), 2일 전 스시 하루(14), 4일 전 김치찌개(2), 6일 전 진짬뽕(10)
    final recent = {19, 14, 2, 10}.map(sampleRestaurantId).toSet();
    for (final weather in SampleWeather.values) {
      final ids = picksOverSeeds(weather.weather).map(id).toSet();
      expect(ids.intersection(recent), isEmpty, reason: weather.label);
    }
  });

  test('1km 밖, 기타 분류, 숨긴 식당, 넘긴 식당은 빠진다', () {
    final hidden = sampleRestaurantId(3);
    final passed = sampleRestaurantId(8);
    final picks = picksOverSeeds(rain, excluded: {hidden}, skipped: {passed});
    expect(picks.every((p) => p.place.distanceM <= 1000), isTrue);
    expect(
      picks.every((p) => p.place.restaurant.cuisine != Cuisine.etc),
      isTrue,
    );
    expect(picks.map(id), isNot(contains(hidden)));
    expect(picks.map(id), isNot(contains(passed)));
  });

  test("'기타'도 추천하도록 켜면 기타 분류가 후보에 들어간다", () {
    final off = RecommendEngine(rules: rules).recommend(
      places: places,
      logs: logs,
      weather: rain,
      settings: const AppSettings(),
      today: testToday,
    );
    final on = RecommendEngine(rules: rules).recommend(
      places: places,
      logs: logs,
      weather: rain,
      settings: const AppSettings(includeEtc: true),
      today: testToday,
    );
    expect(on.candidateCount, off.candidateCount + 2);
  });

  test('못 먹는 음식이 들어간 식당은 빠진다', () {
    final picks = picksOverSeeds(
      rain,
      settings: const AppSettings(dislikedTags: {'국물'}),
    );
    expect(picks, isNotEmpty);
    expect(picks.every((p) => !p.place.restaurant.tags.contains('국물')), isTrue);
  });

  test('분류를 고정하면 그 분류만 나온다', () {
    final picks = picksOverSeeds(rain, lock: Cuisine.japanese);
    expect(picks, isNotEmpty);
    expect(
      picks.every((p) => p.place.restaurant.cuisine == Cuisine.japanese),
      isTrue,
    );
  });

  test('비 오는 날 1등은 국물 요리이고 이유에 날씨가 나온다', () {
    for (var seed = 0; seed < 20; seed++) {
      final best = RecommendEngine(rules: rules, random: Random(seed))
          .recommend(
            places: places,
            logs: logs,
            weather: rain,
            settings: const AppSettings(),
            today: testToday,
          )
          .picks
          .first;
      expect(best.place.restaurant.tags.any(rules.wetTags.contains), isTrue);
      final weatherReason = best.reasons.firstWhere(
        (r) => r.code == ReasonCode.weatherWet,
      );
      expect(weatherReason.text, startsWith('비가 오고 9℃라 따뜻한'));
    }
  });

  test('더운 날에는 시원한 메뉴에 날씨 이유가 붙는다', () {
    final picks = picksOverSeeds(SampleWeather.hot.weather);
    final withReason = picks.where(
      (p) => p.reasons.any((r) => r.code == ReasonCode.weatherHot),
    );
    expect(withReason, isNotEmpty);
    expect(
      withReason.every(
        (p) => p.place.restaurant.tags.any(rules.hotTags.contains),
      ),
      isTrue,
    );
  });

  test('미세먼지가 나쁜 날의 날씨 이유는 가까운 곳에만 붙는다', () {
    final picks = picksOverSeeds(SampleWeather.dust.weather);
    final withReason = picks.where(
      (p) => p.reasons.any((r) => r.code == ReasonCode.weatherDusty),
    );
    expect(withReason, isNotEmpty);
    expect(
      withReason.every((p) => p.place.distanceM <= rules.nearMeters),
      isTrue,
    );
  });

  test('최근 두 번과 다른 분류면 분류를 바꿨다는 이유가 붙는다', () {
    // 예시 기록의 최근 두 번은 양식(1일 전), 일식(2일 전).
    final picks = picksOverSeeds(SampleWeather.clear.weather);
    for (final pick in picks) {
      final rotated = pick.reasons.any(
        (r) => r.code == ReasonCode.cuisineRotate,
      );
      final cuisine = pick.place.restaurant.cuisine;
      if (rotated) {
        expect(cuisine, isNot(anyOf(Cuisine.western, Cuisine.japanese)));
      }
    }
    expect(
      picks
          .expand((p) => p.reasons)
          .where((r) => r.code == ReasonCode.cuisineRotate)
          .first
          .text,
      contains('최근 2번은 일식·양식'),
    );
  });

  test('후보가 5곳보다 적으면 피하는 기간을 3일로 줄인다', () {
    // 일식 5곳을 모두 4~6일 전에 다녀온 상황.
    final visits = [
      for (final (i, n) in [14, 15, 16, 17, 18].indexed)
        MealLog(
          id: 100 + i,
          date: testToday.subtract(Duration(days: 4 + i % 3)),
          mealType: MealType.dinner,
          restaurantId: sampleRestaurantId(n),
          restaurantName: '일식 $n',
          cuisine: Cuisine.japanese,
        ),
    ];
    final result = RecommendEngine(rules: rules, random: Random(3)).recommend(
      places: places,
      logs: visits,
      weather: rain,
      settings: const AppSettings(),
      today: testToday,
      lockCuisine: Cuisine.japanese,
    );
    expect(result.relaxed, isTrue);
    expect(result.candidateCount, 5);
    expect(result.picks, hasLength(3));
  });

  test('조건에 맞는 식당이 없으면 빈 결과를 돌려준다', () {
    final result = RecommendEngine(rules: rules).recommend(
      places: places,
      logs: logs,
      weather: rain,
      settings: const AppSettings(),
      today: testToday,
      excludedIds: {for (final p in places) p.restaurant.id},
    );
    expect(result.picks, isEmpty);
    expect(result.candidateCount, 0);
  });

  group('실제 날씨 (5단계)', () {
    const weatherCodes = {
      ReasonCode.weatherWet,
      ReasonCode.weatherCold,
      ReasonCode.weatherHot,
      ReasonCode.weatherNice,
      ReasonCode.weatherDusty,
    };

    test('날씨를 못 받아도 추천하고, 날씨 이유는 붙이지 않는다', () {
      final picks = picksOverSeeds(null);
      expect(picks, isNotEmpty);
      for (final pick in picks) {
        expect(
          pick.reasons.map((r) => r.code).toSet().intersection(weatherCodes),
          isEmpty,
        );
      }
    });

    test('구름이 좀 있는 걷기 좋은 날도 걷기 좋은 날로 본다', () {
      expect(
        rules.kindOf(const Weather(tempC: 20, sky: Sky.partly)),
        rules.kindOf(const Weather(tempC: 20)),
      );
      expect(
        rules.kindOf(const Weather(tempC: 20, sky: Sky.cloudy)),
        isNot(rules.kindOf(const Weather(tempC: 20))),
      );
    });

    test('미세먼지를 모르면 미세먼지 이유를 붙이지 않는다', () {
      const weather = Weather(tempC: 14, sky: Sky.cloudy);
      expect(weather.summaryWithDust, '☁️ 흐림 · 14℃');
      for (final pick in picksOverSeeds(weather)) {
        expect(
          pick.reasons.map((r) => r.code),
          isNot(contains(ReasonCode.weatherDusty)),
        );
      }
    });
  });
}
