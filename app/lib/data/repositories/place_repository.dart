import '../../domain/models/restaurant.dart';
import '../sample/sample_data.dart';

/// 주변 식당을 가져오는 곳.
///
/// 2단계에서 Cloudflare Workers의 `/places`를 부르는 구현으로 바꾼다 (PLAN.md 6장).
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

/// 예시 식당을 돌려주는 가짜 구현.
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
