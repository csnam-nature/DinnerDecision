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

/// 가까운 측정소의 미세먼지(PM10)·초미세먼지(PM2.5) 농도(㎍/㎥)와 등급 (에어코리아).
class AirQuality {
  const AirQuality({
    this.pm10,
    this.pm10Level,
    this.pm25,
    this.pm25Level,
    this.station = '',
    this.measuredAt = '',
  });

  final int? pm10;
  final DustLevel? pm10Level;
  final int? pm25;
  final DustLevel? pm25Level;
  final String station;
  final String measuredAt;
}

class Weather {
  const Weather({
    required this.tempC,
    this.precipitation = Precipitation.none,
    this.sky = Sky.clear,
    this.dust,
    this.air,
  });

  final double tempC;
  final Precipitation precipitation;
  final Sky sky;

  /// 미세먼지 (에어코리아, PM10·PM2.5 중 나쁜 쪽). 모르면 null.
  final DustLevel? dust;

  /// 미세먼지·초미세먼지 수치. 서버가 주지 않았으면 null (예시 날씨 등).
  final AirQuality? air;

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

  /// 화면에 보이는 미세먼지 줄. 모르면 null.
  /// 예: "미세먼지 나쁨 85㎍/㎥ · 초미세먼지 보통 30㎍/㎥", 수치가 없으면 "미세먼지 보통".
  String? get dustLine {
    final a = air;
    if (a != null) {
      String? part(String name, DustLevel? level, int? value) {
        final words = [
          if (level != null) level.label,
          if (value != null) '$value㎍/㎥',
        ];
        return words.isEmpty ? null : '$name ${words.join(' ')}';
      }

      final parts = [
        ?part('미세먼지', a.pm10Level, a.pm10),
        ?part('초미세먼지', a.pm25Level, a.pm25),
      ];
      if (parts.isNotEmpty) return parts.join(' · ');
    }
    return dust == null ? null : '미세먼지 ${dust!.label}';
  }

  /// 예: "☔ 비 · 9℃ · 미세먼지 보통". 미세먼지를 모르면 summary와 같다.
  String get summaryWithDust =>
      dust == null ? summary : '$summary · 미세먼지 ${dust!.label}';
}
