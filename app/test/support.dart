import 'dart:io';

import 'package:dinner_decision/data/app_config.dart';

/// 테스트에서 쓰는 '오늘'. 2026-11-09 (월).
final testToday = DateTime(2026, 11, 9, 18, 20);

/// 실제 앱이 쓰는 규칙 파일을 그대로 읽는다.
AppConfig loadTestConfig() => AppConfig.fromJsonStrings(
  cuisineMapping: File(AppConfig.cuisineMappingAsset).readAsStringSync(),
  weatherRules: File(AppConfig.weatherRulesAsset).readAsStringSync(),
);
