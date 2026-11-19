import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../domain/cuisine_mapper.dart';
import '../domain/recommend/weather_rules.dart';

/// assets/config 의 규칙 파일을 읽어 둔 것. 앱 시작할 때 한 번 읽는다.
class AppConfig {
  const AppConfig({required this.cuisineMapper, required this.weatherRules});

  static const cuisineMappingAsset = 'assets/config/cuisine_mapping.json';
  static const weatherRulesAsset = 'assets/config/weather_rules.json';

  factory AppConfig.fromJsonStrings({
    required String cuisineMapping,
    required String weatherRules,
  }) {
    return AppConfig(
      cuisineMapper: CuisineMapper.fromJson(
        jsonDecode(cuisineMapping) as Map<String, dynamic>,
      ),
      weatherRules: WeatherRules.fromJson(
        jsonDecode(weatherRules) as Map<String, dynamic>,
      ),
    );
  }

  static Future<AppConfig> load(AssetBundle bundle) async {
    return AppConfig.fromJsonStrings(
      cuisineMapping: await bundle.loadString(cuisineMappingAsset),
      weatherRules: await bundle.loadString(weatherRulesAsset),
    );
  }

  final CuisineMapper cuisineMapper;
  final WeatherRules weatherRules;
}
