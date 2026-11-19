import '../../core/dates.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/models/meal_log.dart';
import '../../domain/models/restaurant.dart';

/// 기록·식당·설정 ↔ JSON. 기기 DB의 설정 저장과 백업 파일에 같이 쓴다.
///
/// 이름(enum.name)으로 저장하므로 enum 순서를 바꿔도 된다. 모르는 값은 기본값으로 읽는다.
abstract final class Codec {
  static String date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime parseDate(String s) => dateOnly(DateTime.parse(s));

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.asNameMap()[name] ?? fallback;

  static Map<String, Object?> mealLog(MealLog l) => {
    'id': l.id,
    'date': date(l.date),
    'mealType': l.mealType.name,
    'restaurantId': l.restaurantId,
    'restaurantName': l.restaurantName,
    'cuisine': l.cuisine.name,
    'menu': l.menu,
    'rating': l.rating,
    'memo': l.memo,
    'photo': l.photoPath,
    'weatherText': l.weatherText,
    'fromRecommend': l.fromRecommend,
  };

  static MealLog parseMealLog(Map<String, Object?> j) => MealLog(
    id: j['id'] as int,
    date: parseDate(j['date'] as String),
    mealType: _enum(MealType.values, j['mealType'], MealType.dinner),
    restaurantId: j['restaurantId'] as String?,
    restaurantName: j['restaurantName'] as String? ?? '',
    cuisine: _enum(Cuisine.values, j['cuisine'], Cuisine.etc),
    menu: j['menu'] as String? ?? '',
    rating: (j['rating'] as int? ?? 0).clamp(0, 5),
    memo: j['memo'] as String? ?? '',
    photoPath: j['photo'] as String?,
    weatherText: j['weatherText'] as String? ?? '',
    fromRecommend: j['fromRecommend'] as bool? ?? false,
  );

  static Map<String, Object?> restaurant(Restaurant r) => {
    'id': r.id,
    'name': r.name,
    'categoryRaw': r.categoryRaw,
    'cuisine': r.cuisine.name,
    'subCategory': r.subCategory,
    'tags': r.tags,
    'roadAddress': r.roadAddress,
    'phone': r.phone,
    'lat': r.lat,
    'lng': r.lng,
    'kakaoUrl': r.kakaoUrl,
  };

  static Restaurant parseRestaurant(Map<String, Object?> j) => Restaurant(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    categoryRaw: j['categoryRaw'] as String? ?? '',
    cuisine: _enum(Cuisine.values, j['cuisine'], Cuisine.etc),
    subCategory: j['subCategory'] as String? ?? '',
    tags: [
      for (final t in j['tags'] as List<Object?>? ?? const []) t as String,
    ],
    roadAddress: j['roadAddress'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    lat: (j['lat'] as num? ?? 0).toDouble(),
    lng: (j['lng'] as num? ?? 0).toDouble(),
    kakaoUrl: j['kakaoUrl'] as String?,
  );

  static Map<String, Object?> settings(AppSettings s) => {
    'radiusM': s.radiusM,
    'avoidRestaurantDays': s.avoidRestaurantDays,
    'avoidCuisineStreak': s.avoidCuisineStreak,
    'includeEtc': s.includeEtc,
    'recommendAnimation': s.recommendAnimation,
    'themeMode': s.themeMode.name,
    'dislikedTags': s.dislikedTags.toList()..sort(),
  };

  static AppSettings parseSettings(Map<String, Object?> j) {
    const d = AppSettings();
    return AppSettings(
      radiusM: j['radiusM'] as int? ?? d.radiusM,
      avoidRestaurantDays:
          j['avoidRestaurantDays'] as int? ?? d.avoidRestaurantDays,
      avoidCuisineStreak:
          j['avoidCuisineStreak'] as int? ?? d.avoidCuisineStreak,
      includeEtc: j['includeEtc'] as bool? ?? d.includeEtc,
      recommendAnimation:
          j['recommendAnimation'] as bool? ?? d.recommendAnimation,
      themeMode: _enum(AppThemeMode.values, j['themeMode'], d.themeMode),
      dislikedTags: {
        for (final t in j['dislikedTags'] as List<Object?>? ?? const [])
          t as String,
      },
    );
  }
}
