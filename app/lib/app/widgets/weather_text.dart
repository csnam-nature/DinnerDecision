import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/weather.dart';

/// 화면 위쪽에 보이는 날씨 한 줄.
String weatherLine(AsyncValue<Weather?> weather) => switch (weather) {
  AsyncData(value: final w?) => w.summaryWithDust,
  AsyncData() || AsyncError() => '날씨 정보 없음',
  _ => '날씨를 확인하는 중…',
};
