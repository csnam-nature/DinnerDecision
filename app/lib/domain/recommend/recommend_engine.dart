import 'dart:math' as math;

import '../../core/dates.dart';
import '../../core/geo.dart';
import '../../core/korean.dart';
import '../models/app_settings.dart';
import '../models/cuisine.dart';
import '../models/meal_log.dart';
import '../models/restaurant.dart';
import '../models/weather.dart';
import 'recommendation.dart';
import 'weather_rules.dart';

/// 오늘의 추천을 고른다 (PLAN.md 9장).
///
/// 방문 기록이 기기에만 있으므로 계산도 기기 안에서 한다.
class RecommendEngine {
  RecommendEngine({required this.rules, math.Random? random})
    : _random = random ?? math.Random();

  /// 후보가 이보다 적으면 '같은 식당 피하기' 기간을 줄인다.
  static const minCandidates = 5;
  static const relaxedAvoidDays = 3;

  /// 이틀 안에 먹은 메뉴와 겹치면 메뉴 다양성 점수를 주지 않는다.
  static const recentMenuDays = 2;

  /// 이 기간 안에 다시 가면 식당 다양성 점수를 낮게 준다.
  static const revisitPenaltyDays = 14;

  final WeatherRules rules;
  final math.Random _random;

  RecommendResult recommend({
    required List<NearbyPlace> places,
    required List<MealLog> logs,
    required Weather weather,
    required AppSettings settings,
    required DateTime today,
    Set<String> excludedIds = const {},
    Set<String> skippedIds = const {},
    Cuisine? lockCuisine,
  }) {
    final recent = [...logs]..sort(MealLog.newestFirst);
    final lastVisit = <String, int>{};
    final bestRating = <String, int>{};
    for (final log in recent) {
      final id = log.restaurantId;
      if (id == null) continue;
      lastVisit.putIfAbsent(id, () => daysBetween(log.date, today));
      bestRating[id] = math.max(bestRating[id] ?? 0, log.rating);
    }

    final base = places.where((p) {
      final r = p.restaurant;
      return p.distanceM <= settings.radiusM &&
          !excludedIds.contains(r.id) &&
          !skippedIds.contains(r.id) &&
          (settings.includeEtc || r.cuisine != Cuisine.etc) &&
          !r.tags.any(settings.dislikedTags.contains) &&
          (lockCuisine == null || r.cuisine == lockCuisine);
    }).toList();

    List<NearbyPlace> notVisitedWithin(int days) => base.where((p) {
      final last = lastVisit[p.restaurant.id];
      return last == null || last > days;
    }).toList();

    var candidates = notVisitedWithin(settings.avoidRestaurantDays);
    var relaxed = false;
    if (candidates.length < minCandidates &&
        settings.avoidRestaurantDays > relaxedAvoidDays) {
      relaxed = true;
      candidates = notVisitedWithin(relaxedAvoidDays);
    }
    if (candidates.isEmpty) {
      return RecommendResult(
        picks: const [],
        candidateCount: 0,
        relaxed: relaxed,
      );
    }

    final restaurantsById = {
      for (final p in places) p.restaurant.id: p.restaurant,
    };
    final recentTags = <String>{};
    for (final log in recent) {
      if (daysBetween(log.date, today) > recentMenuDays) continue;
      if (log.menu.isNotEmpty) recentTags.add(log.menu);
      final visited = restaurantsById[log.restaurantId];
      if (visited != null) {
        recentTags.addAll([...visited.tags, visited.subCategory]);
      }
    }

    final kind = rules.kindOf(weather);
    final scored = [
      for (final place in candidates)
        _score(
          place,
          kind: kind,
          weather: weather,
          settings: settings,
          recentCuisines: [for (final log in recent) log.cuisine],
          recentTags: recentTags,
          lastVisitDays: lastVisit[place.restaurant.id],
          bestRating: bestRating[place.restaurant.id] ?? 0,
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    // 상위 10곳 중에서 점수가 높을수록 잘 뽑히게 3곳을 고른다. 매번 같은 결과가 나오지 않게 하려는 것.
    final pool = scored.take(10).toList();
    final picks = <Recommendation>[];
    while (picks.length < 3 && pool.isNotEmpty) {
      final total = pool.fold<double>(0, (sum, x) => sum + _weight(x));
      var target = _random.nextDouble() * total;
      var index = 0;
      for (; index < pool.length - 1; index++) {
        target -= _weight(pool[index]);
        if (target <= 0) break;
      }
      picks.add(pool.removeAt(index));
    }
    picks.sort((a, b) => b.score.compareTo(a.score));

    return RecommendResult(
      picks: picks,
      candidateCount: candidates.length,
      relaxed: relaxed,
    );
  }

  double _weight(Recommendation r) => (r.score * r.score).toDouble();

  Recommendation _score(
    NearbyPlace place, {
    required WeatherKind kind,
    required Weather weather,
    required AppSettings settings,
    required List<Cuisine> recentCuisines,
    required Set<String> recentTags,
    required int? lastVisitDays,
    required int bestRating,
  }) {
    final r = place.restaurant;
    final reasons = <Reason>[];
    var total = 0.0;
    void add(double points, [Reason Function(double points)? reason]) {
      total += points;
      if (reason != null) reasons.add(reason(points));
    }

    // 1. 식당 다양성 (0~30)
    if (lastVisitDays == null) {
      add(
        30,
        (p) => Reason(
          code: ReasonCode.newPlace,
          points: p,
          emoji: '🆕',
          text: '아직 가 보지 않은 식당이에요',
          short: '처음 가는 곳',
        ),
      );
    } else if (lastVisitDays <= revisitPenaltyDays) {
      add(10);
    } else {
      add(
        20,
        (p) => Reason(
          code: ReasonCode.longAgo,
          points: p,
          emoji: '🔁',
          text: '마지막 방문이 $lastVisitDays일 전이라 다시 가기 좋아요',
          short: '오랜만',
        ),
      );
    }

    // 2. 분류 다양성 (0~20)
    final streak = recentCuisines.take(settings.avoidCuisineStreak).toList();
    final lastTwo = recentCuisines.take(2).toList();
    final sameInLastTwo = lastTwo.where((c) => c == r.cuisine).length;
    final name = r.cuisine.label;
    if (streak.length == settings.avoidCuisineStreak &&
        streak.every((c) => c == r.cuisine)) {
      add(0);
    } else if (lastTwo.length == 2 && sameInLastTwo == 0) {
      final older = lastTwo[1].label;
      final newer = lastTwo[0].label;
      add(
        20,
        (p) => Reason(
          code: ReasonCode.cuisineRotate,
          points: p,
          emoji: '🔄',
          text: older == newer
              ? '최근 2번 연속 ${josa(older, '을', '를')} 먹어서 오늘은 ${josa(name, '으로', '로')} 바꿨어요'
              : '최근 2번은 $older·$newer, 오늘은 ${josa(name, '으로', '로')} 바꿨어요',
          short: '${josa(name, '으로', '로')} 변화',
        ),
      );
    } else {
      add(20 - 10.0 * sameInLastTwo);
    }

    // 3. 메뉴 다양성 (0~10)
    final repeatsMenu =
        recentTags.contains(r.subCategory) || r.tags.any(recentTags.contains);
    add(repeatsMenu ? 0 : 10);

    // 4. 날씨 적합도 (0~25)
    final temp = weather.tempRounded;
    switch (kind) {
      case WeatherKind.wet || WeatherKind.cold || WeatherKind.hot:
        if (r.tags.any(rules.boostTags(kind).contains)) {
          add(25, (p) => _weatherReason(kind, weather, r, p));
        } else {
          add(8);
        }
      case WeatherKind.nice:
        if (lastVisitDays == null && place.distanceM >= rules.nearMeters) {
          add(
            25,
            (p) => Reason(
              code: ReasonCode.weatherNice,
              points: p,
              emoji: '🌤',
              text: '$temp℃ 맑은 날이라 조금 걸어도 좋은 새 식당이에요',
              short: '걷기 좋은 날',
            ),
          );
        } else {
          add(12);
        }
      case WeatherKind.dusty:
        if (place.distanceM <= rules.nearMeters) {
          add(
            25,
            (p) => Reason(
              code: ReasonCode.weatherDusty,
              points: p,
              emoji: '😷',
              text: '미세먼지가 나빠서 가까운 곳으로 골랐어요',
              short: '가까운 곳',
            ),
          );
        } else {
          add(5);
        }
      case WeatherKind.neutral:
        add(12);
    }

    // 5. 거리 (0~10, 비·눈이 오면 2배)
    final wet = kind == WeatherKind.wet;
    add(
      math.max(0, 10 * (1 - place.distanceM / settings.radiusM)) *
          (wet ? 2 : 1),
    );

    // 6. 만족도 (0~5)
    if (lastVisitDays != null &&
        lastVisitDays > revisitPenaltyDays &&
        bestRating >= 4) {
      add(
        5,
        (p) => Reason(
          code: ReasonCode.ratedHigh,
          points: p,
          emoji: '⭐',
          text: '지난번에 별점 $bestRating점을 준 곳이에요',
          short: '별점 $bestRating점',
        ),
      );
    }

    reasons.sort((a, b) => b.points.compareTo(a.points));
    final minutes = walkMinutes(place.distanceM);
    final shown = [
      ...reasons.take(3),
      Reason(
        code: ReasonCode.near,
        points: 0,
        emoji: '📍',
        text: wet
            ? '걸어서 $minutes분 거리예요 (${weather.skyLabel} 오는 날이라 가까운 곳에 점수를 더 줬어요)'
            : '걸어서 $minutes분 거리예요',
        short: '걸어서 $minutes분',
      ),
    ];
    return Recommendation(place: place, score: total.round(), reasons: shown);
  }

  Reason _weatherReason(
    WeatherKind kind,
    Weather weather,
    Restaurant r,
    double points,
  ) {
    final temp = weather.tempRounded;
    final menu = r.subCategory;
    return switch (kind) {
      WeatherKind.wet => Reason(
        code: ReasonCode.weatherWet,
        points: points,
        emoji: weather.emoji,
        text:
            '${josa(weather.skyLabel, '이', '가')} 오고 $temp℃라 따뜻한 ${josa(menu, '이', '가')} 좋아요',
        short: '따뜻한 국물',
      ),
      WeatherKind.cold => Reason(
        code: ReasonCode.weatherCold,
        points: points,
        emoji: '🥶',
        text: '$temp℃로 추워서 뜨끈한 ${josa(menu, '을', '를')} 추천해요',
        short: '추운 날 국물',
      ),
      _ => Reason(
        code: ReasonCode.weatherHot,
        points: points,
        emoji: '🥵',
        text: '$temp℃ 더운 날이라 시원한 $menu 어때요?',
        short: '시원한 메뉴',
      ),
    };
  }
}
