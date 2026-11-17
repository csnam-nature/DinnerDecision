import 'cuisine.dart';

enum MealType {
  dinner('저녁'),
  lunch('점심'),
  etc('기타');

  const MealType(this.label);

  final String label;
}

/// 식사 기록 한 건 (PLAN.md 8장 meal_logs).
class MealLog {
  const MealLog({
    required this.id,
    required this.date,
    required this.mealType,
    required this.restaurantName,
    required this.cuisine,
    this.restaurantId,
    this.menu = '',
    this.rating = 0,
    this.memo = '',
    this.photoPath,
    this.weatherText = '',
    this.fromRecommend = false,
  });

  final int id;

  /// 날짜만 쓴다. 달력 표시 기준.
  final DateTime date;
  final MealType mealType;

  /// 집밥·배달이나 직접 입력한 식당이면 null.
  final String? restaurantId;

  /// 식당 정보가 바뀌어도 기록이 남도록 이름을 복사해 둔다.
  final String restaurantName;
  final Cuisine cuisine;
  final String menu;

  /// 0은 아직 별점을 주지 않은 상태.
  final int rating;
  final String memo;
  final String? photoPath;

  /// 기록할 때의 날씨. 예: "☔ 비 · 9℃"
  final String weatherText;
  final bool fromRecommend;

  /// 최근 기록이 앞에 오도록 정렬. 같은 날이면 저녁 → 점심 → 기타.
  static int newestFirst(MealLog a, MealLog b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : a.mealType.index.compareTo(b.mealType.index);
  }
}
