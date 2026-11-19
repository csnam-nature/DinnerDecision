/// 위치를 어떻게 정했는지.
enum LocationSource {
  /// 휴대폰 GPS
  gps,

  /// 위치 설정 화면에서 검색해서 고름
  search,

  /// 예시 데이터
  sample,
}

/// 주변 식당을 찾는 기준 위치.
class AppLocation {
  const AppLocation({
    required this.name,
    required this.lat,
    required this.lng,
    this.detail = '',
    this.source = LocationSource.sample,
  });

  /// 화면 위쪽에 보이는 이름. 예: 성수동2가
  final String name;
  final double lat;
  final double lng;

  /// 목록에서 이름 아래에 보이는 설명.
  final String detail;
  final LocationSource source;

  @override
  bool operator ==(Object other) =>
      other is AppLocation &&
      other.name == name &&
      other.lat == lat &&
      other.lng == lng &&
      other.source == source;

  @override
  int get hashCode => Object.hash(name, lat, lng, source);
}
