import '../../domain/models/cuisine.dart';
import '../../domain/models/meal_log.dart';
import '../../domain/models/restaurant.dart';

/// 기록 입력 화면을 열 때 미리 채워 둘 값.
class MealLogDraft {
  const MealLogDraft({
    required this.date,
    this.id,
    this.mealType = MealType.dinner,
    this.restaurant,
    this.restaurantId,
    this.restaurantName = '',
    this.cuisine,
    this.menu = '',
    this.rating = 0,
    this.memo = '',
    this.photoPath,
    this.weatherText = '',
    this.fromRecommend = false,
  });

  /// 빈 기록.
  factory MealLogDraft.blank(DateTime date) => MealLogDraft(date: date);

  /// 식당이 정해진 기록. 추천에서 결정했거나 상세에서 들어온 경우.
  factory MealLogDraft.forRestaurant(
    Restaurant restaurant, {
    required DateTime date,
    String menu = '',
    bool fromRecommend = false,
  }) {
    return MealLogDraft(
      date: date,
      restaurant: restaurant,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      cuisine: restaurant.cuisine,
      menu: menu,
      fromRecommend: fromRecommend,
    );
  }

  /// 이미 있는 기록을 고칠 때.
  factory MealLogDraft.fromLog(MealLog log) {
    return MealLogDraft(
      id: log.id,
      date: log.date,
      mealType: log.mealType,
      restaurantId: log.restaurantId,
      restaurantName: log.restaurantName,
      cuisine: log.cuisine,
      menu: log.menu,
      rating: log.rating,
      memo: log.memo,
      photoPath: log.photoPath,
      weatherText: log.weatherText,
      fromRecommend: log.fromRecommend,
    );
  }

  /// null이면 새 기록.
  final int? id;
  final DateTime date;
  final MealType mealType;

  /// 메뉴 추천 단어를 보여주려고 넘기는 식당 정보. 없어도 된다.
  final Restaurant? restaurant;
  final String? restaurantId;
  final String restaurantName;
  final Cuisine? cuisine;
  final String menu;
  final int rating;
  final String memo;

  /// 사진 파일 이름 (PhotoStore 안).
  final String? photoPath;

  /// 비어 있으면 화면이 지금 날씨로 채운다.
  final String weatherText;
  final bool fromRecommend;
}

/// 집에서 먹었거나 배달시킨 날에 식당 이름 대신 쓰는 말.
const homeMealName = '집밥·배달';
