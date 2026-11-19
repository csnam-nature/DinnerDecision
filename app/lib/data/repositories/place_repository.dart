import '../../domain/cuisine_mapper.dart';
import '../../domain/models/restaurant.dart';
import '../api/api_client.dart';
import '../sample/sample_data.dart';

/// 주변 식당을 가져오는 곳.
abstract interface class PlaceRepository {
  /// [radiusM] 안의 음식점. 거리 계산과 정렬은 부르는 쪽에서 한다.
  Future<List<Restaurant>> fetchNearby({
    required double lat,
    required double lng,
    required int radiusM,
  });

  /// 식당 상세에 쓸 한 곳. 모르는 id면 null.
  Future<Restaurant?> findById(String id);
}

/// 서버 `/places`를 부르는 구현 (PLAN.md 4장).
///
/// 서버는 카카오 호출 횟수 제한 때문에 식당이 아주 많은 동네에서는 일부만 주고
/// `complete: false`로 알린다. 다시 부르면 서버 캐시 다음부터 이어서 채우므로
/// [maxRounds]번까지 다시 부른다.
class ApiPlaceRepository implements PlaceRepository {
  ApiPlaceRepository({
    required this._client,
    required this._mapper,
    this.maxRounds = 4,
  });

  final ApiClient _client;
  final CuisineMapper _mapper;
  final int maxRounds;
  final _known = <String, Restaurant>{};

  /// 마지막 검색에서 반경 안을 모두 확인했는지.
  bool lastComplete = true;

  @override
  Future<List<Restaurant>> fetchNearby({
    required double lat,
    required double lng,
    required int radiusM,
  }) async {
    var body = const <String, dynamic>{};
    for (var round = 0; round < maxRounds; round++) {
      body = await _client.get(
        '/places',
        query: {
          'lat': lat.toStringAsFixed(5),
          'lng': lng.toStringAsFixed(5),
          'radius': radiusM,
        },
      );
      if (body['complete'] == true) break;
    }
    lastComplete = body['complete'] == true;
    final restaurants = [
      for (final item in body['places'] as List<dynamic>? ?? const [])
        restaurantFromJson(item as Map<String, dynamic>, _mapper),
    ];
    _known
      ..clear()
      ..addEntries(restaurants.map((r) => MapEntry(r.id, r)));
    return restaurants;
  }

  @override
  Future<Restaurant?> findById(String id) async => _known[id];
}

/// 서버가 준 식당 하나. 분류는 앱의 cuisine_mapping.json으로 정한다.
Restaurant restaurantFromJson(Map<String, dynamic> json, CuisineMapper mapper) {
  final category = json['category'] as String? ?? '';
  final classified = mapper.classify(category);
  final road = json['roadAddress'] as String? ?? '';
  final url = json['url'] as String? ?? '';
  return Restaurant(
    id: json['id'] as String,
    name: json['name'] as String,
    categoryRaw: category,
    cuisine: classified.cuisine,
    subCategory: classified.subCategory,
    tags: classified.tags,
    roadAddress: road.isNotEmpty ? road : json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    kakaoUrl: url.isEmpty ? null : url,
  );
}

/// 예시 식당을 돌려주는 가짜 구현. 서버 주소 없이 실행하거나 테스트할 때 쓴다.
class FakePlaceRepository implements PlaceRepository {
  FakePlaceRepository({this.delay = const Duration(milliseconds: 600)});

  /// 불러오는 중 화면을 볼 수 있게 일부러 두는 지연.
  final Duration delay;
  final _known = <String, Restaurant>{};

  @override
  Future<List<Restaurant>> fetchNearby({
    required double lat,
    required double lng,
    required int radiusM,
  }) async {
    await Future<void>.delayed(delay);
    final all = sampleRestaurantsAround(lat, lng);
    _known
      ..clear()
      ..addEntries(all.map((r) => MapEntry(r.id, r)));
    return all;
  }

  @override
  Future<Restaurant?> findById(String id) async => _known[id];
}
