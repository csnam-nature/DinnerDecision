enum Precipitation { none, rain, snow }

/// 하늘 상태. 기상청 SKY 코드 1(맑음)·3(구름많음)·4(흐림).
enum Sky { clear, partly, cloudy }

enum DustLevel {
  good('좋음'),
  normal('보통'),
  bad('나쁨'),
  veryBad('매우나쁨');

  const DustLevel(this.label);

  final String label;

  /// 나쁨 이상이면 바깥에 오래 있지 않는 편이 좋다 (가까운 곳 추천).
  bool get isBad => this == bad || this == veryBad;
}

class Weather {
  const Weather({
    required this.tempC,
    this.precipitation = Precipitation.none,
    this.sky = Sky.clear,
    this.dust,
  });

  final double tempC;
  final Precipitation precipitation;
  final Sky sky;

  /// 미세먼지 (에어코리아, PM10·PM2.5 중 나쁜 쪽). 모르면 null.
  final DustLevel? dust;

  int get tempRounded => tempC.round();

  String get skyLabel => switch (precipitation) {
    Precipitation.rain => '비',
    Precipitation.snow => '눈',
    Precipitation.none => switch (sky) {
      Sky.clear => '맑음',
      Sky.partly => '구름많음',
      Sky.cloudy => '흐림',
    },
  };

  String get emoji => switch (precipitation) {
    Precipitation.rain => '☔',
    Precipitation.snow => '🌨',
    Precipitation.none => switch (sky) {
      Sky.clear => '🌤',
      Sky.partly => '⛅',
      Sky.cloudy => '☁️',
    },
  };

  /// 예: "☔ 비 · 9℃"
  String get summary => '$emoji $skyLabel · $tempRounded℃';

  /// 예: "☔ 비 · 9℃ · 미세먼지 보통". 미세먼지를 모르면 summary와 같다.
  String get summaryWithDust =>
      dust == null ? summary : '$summary · 미세먼지 ${dust!.label}';
}
