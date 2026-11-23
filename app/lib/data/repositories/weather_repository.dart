import '../../core/geo.dart';
import '../../domain/models/weather.dart';
import '../api/api_client.dart';

/// 현재 날씨를 가져오는 곳.
abstract interface class WeatherRepository {
  Future<Weather> fetchCurrent({required double lat, required double lng});
}

/// 서버 `/weather`(기상청 초단기실황·예보)를 부르는 구현.
///
/// 기상청 자료는 한 시간에 한 번 바뀌므로, 같은 동네(약 1km)는 [ttl] 동안 다시 부르지 않는다.
class ApiWeatherRepository implements WeatherRepository {
  ApiWeatherRepository(
    this._client, {
    this._clock = DateTime.now,
    this.ttl = const Duration(minutes: 15),
  });

  final ApiClient _client;
  final DateTime Function() _clock;
  final Duration ttl;
  ({String key, DateTime at, Weather weather})? _last;

  @override
  Future<Weather> fetchCurrent({
    required double lat,
    required double lng,
  }) async {
    final key = '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
    final now = _clock();
    final last = _last;
    if (last != null && last.key == key && now.difference(last.at) < ttl) {
      return last.weather;
    }
    final body = await _client.get(
      '/weather',
      query: {'lat': coarseCoord(lat), 'lng': coarseCoord(lng)},
    );
    final weather = weatherFromJson(body);
    _last = (key: key, at: now, weather: weather);
    return weather;
  }
}

Weather weatherFromJson(Map<String, dynamic> json) {
  final temp = json['tempC'];
  if (temp is! num) {
    throw const ApiException(ApiException.badResponse, '날씨 응답에 기온이 없어요');
  }
  return Weather(
    tempC: temp.toDouble(),
    precipitation: switch (json['precipitation']) {
      'rain' => Precipitation.rain,
      'snow' => Precipitation.snow,
      _ => Precipitation.none,
    },
    sky: switch (json['sky']) {
      'partly' => Sky.partly,
      'cloudy' => Sky.cloudy,
      // 하늘 상태를 못 받았으면(null) 맑음으로 둔다. 비·눈은 precipitation으로 따로 안다.
      _ => Sky.clear,
    },
    dust: switch (json['dust']) {
      'good' => DustLevel.good,
      'normal' => DustLevel.normal,
      'bad' => DustLevel.bad,
      _ => null,
    },
  );
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
