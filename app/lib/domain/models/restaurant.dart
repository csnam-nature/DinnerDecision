import 'cuisine.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.categoryRaw,
    required this.cuisine,
    required this.subCategory,
    required this.tags,
    required this.roadAddress,
    required this.phone,
    required this.lat,
    required this.lng,
    this.kakaoUrl,
  });

  /// 카카오 장소 id.
  final String id;
  final String name;

  /// 카카오 원본 분류. 예: "음식점 > 한식 > 해장국"
  final String categoryRaw;
  final Cuisine cuisine;

  /// 세부 분류. 예: 해장국
  final String subCategory;

  /// 날씨 추천과 '못 먹는 음식'에 쓰는 세부 메뉴 태그.
  final List<String> tags;
  final String roadAddress;
  final String phone;
  final double lat;
  final double lng;
  final String? kakaoUrl;
}

/// 현재 위치에서의 거리를 함께 가진 식당.
class NearbyPlace {
  const NearbyPlace({required this.restaurant, required this.distanceM});

  final Restaurant restaurant;

  /// 10m 단위로 반올림한 직선 거리.
  final int distanceM;
}
