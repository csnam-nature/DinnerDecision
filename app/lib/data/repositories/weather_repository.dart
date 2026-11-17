import '../../domain/models/weather.dart';

/// 현재 날씨를 가져오는 곳.
///
/// 5단계에서 Cloudflare Workers의 `/weather`를 부르는 구현으로 바꾼다 (PLAN.md 6장).
abstract interface class WeatherRepository {
  Future<Weather> fetchCurrent({required double lat, required double lng});
}

/// 정해 둔 날씨를 그대로 돌려주는 가짜 구현.
class FakeWeatherRepository implements WeatherRepository {
  const FakeWeatherRepository(this.weather);

  final Weather weather;

  @override
  Future<Weather> fetchCurrent({
    required double lat,
    required double lng,
  }) async => weather;
}
