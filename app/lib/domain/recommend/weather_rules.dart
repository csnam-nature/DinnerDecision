import '../models/weather.dart';

/// 추천에서 날씨를 어떻게 볼지. 위에 있을수록 먼저 적용된다.
enum WeatherKind { wet, cold, hot, dusty, nice, neutral }

/// 날씨 규칙 (PLAN.md 9.3). assets/config/weather_rules.json 에서 읽는다.
class WeatherRules {
  const WeatherRules({
    required this.coldMaxTempC,
    required this.hotMinTempC,
    required this.niceMinTempC,
    required this.niceMaxTempC,
    required this.nearMeters,
    required this.wetTags,
    required this.coldTags,
    required this.hotTags,
  });

  factory WeatherRules.fromJson(Map<String, dynamic> json) {
    Set<String> tags(String key) =>
        Set<String>.from(json[key] as List<dynamic>);
    return WeatherRules(
      coldMaxTempC: (json['coldMaxTempC'] as num).toDouble(),
      hotMinTempC: (json['hotMinTempC'] as num).toDouble(),
      niceMinTempC: (json['niceMinTempC'] as num).toDouble(),
      niceMaxTempC: (json['niceMaxTempC'] as num).toDouble(),
      nearMeters: (json['nearMeters'] as num).toInt(),
      wetTags: tags('wetTags'),
      coldTags: tags('coldTags'),
      hotTags: tags('hotTags'),
    );
  }

  final double coldMaxTempC;
  final double hotMinTempC;
  final double niceMinTempC;
  final double niceMaxTempC;

  /// '가까운 곳'으로 보는 거리. 미세먼지가 나쁜 날과 걷기 좋은 날에 쓴다.
  final int nearMeters;
  final Set<String> wetTags;
  final Set<String> coldTags;
  final Set<String> hotTags;

  WeatherKind kindOf(Weather weather) {
    if (weather.precipitation != Precipitation.none) return WeatherKind.wet;
    if (weather.tempC <= coldMaxTempC) return WeatherKind.cold;
    if (weather.tempC >= hotMinTempC) return WeatherKind.hot;
    if (weather.dust == DustLevel.bad) return WeatherKind.dusty;
    if (weather.sky == Sky.clear &&
        weather.tempC >= niceMinTempC &&
        weather.tempC <= niceMaxTempC) {
      return WeatherKind.nice;
    }
    return WeatherKind.neutral;
  }

  /// 이 날씨에 점수를 올릴 태그. 태그로 고르지 않는 날씨면 빈 집합.
  Set<String> boostTags(WeatherKind kind) => switch (kind) {
    WeatherKind.wet => wetTags,
    WeatherKind.cold => coldTags,
    WeatherKind.hot => hotTags,
    _ => const {},
  };
}
