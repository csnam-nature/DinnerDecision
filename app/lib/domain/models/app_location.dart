/// 주변 식당을 찾는 기준 위치.
class AppLocation {
  const AppLocation({
    required this.name,
    required this.lat,
    required this.lng,
    this.detail = '',
  });

  /// 화면 위쪽에 보이는 이름. 예: 성수동2가
  final String name;
  final double lat;
  final double lng;

  /// 목록에서 이름 아래에 보이는 설명.
  final String detail;
}
