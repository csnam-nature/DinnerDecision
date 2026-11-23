import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/models/weather.dart';

/// 화면 위쪽에 보이는 날씨 한 줄 (하늘·기온). 미세먼지는 [dustLine]으로 따로.
String weatherLine(AsyncValue<Weather?> weather) => switch (weather) {
  AsyncData(value: final w?) => w.summary,
  AsyncData() || AsyncError() => '날씨 정보 없음',
  _ => '날씨를 확인하는 중…',
};

/// 미세먼지 줄. 예: "미세먼지 나쁨 85㎍/㎥ · 초미세먼지 보통 30㎍/㎥". 모르면 null.
String? dustLine(AsyncValue<Weather?> weather) => weather.value?.dustLine;

/// 날씨 줄 + (있으면) 미세먼지 줄. [suffix]는 날씨 줄 뒤에 붙인다 (예: 위치 이름).
class WeatherSummary extends StatelessWidget {
  const WeatherSummary({
    super.key,
    required this.weather,
    this.style,
    this.suffix = '',
  });

  final AsyncValue<Weather?> weather;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final dust = dustLine(weather);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${weatherLine(weather)}$suffix', style: style),
        if (dust != null) Text(dust, style: style),
      ],
    );
  }
}
