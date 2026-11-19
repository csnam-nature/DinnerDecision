enum Precipitation { none, rain, snow }

enum Sky { clear, cloudy }

enum DustLevel {
  good('좋음'),
  normal('보통'),
  bad('나쁨');

  const DustLevel(this.label);

  final String label;
}

class Weather {
  const Weather({
    required this.tempC,
    this.precipitation = Precipitation.none,
    this.sky = Sky.clear,
    this.dust = DustLevel.normal,
  });

  final double tempC;
  final Precipitation precipitation;
  final Sky sky;
  final DustLevel dust;

  int get tempRounded => tempC.round();

  String get skyLabel => switch (precipitation) {
    Precipitation.rain => '비',
    Precipitation.snow => '눈',
    Precipitation.none => sky == Sky.clear ? '맑음' : '흐림',
  };

  String get emoji => switch (precipitation) {
    Precipitation.rain => '☔',
    Precipitation.snow => '🌨',
    Precipitation.none => sky == Sky.clear ? '🌤' : '☁️',
  };

  /// 예: "☔ 비 · 9℃"
  String get summary => '$emoji $skyLabel · $tempRounded℃';

  /// 예: "☔ 비 · 9℃ · 미세먼지 보통"
  String get summaryWithDust => '$summary · 미세먼지 ${dust.label}';
}
