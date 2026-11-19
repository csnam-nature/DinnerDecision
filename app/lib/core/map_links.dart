/// 외부 앱·웹으로 여는 주소 (PLAN.md 4.1, F-05).
///
/// 네이버 지도 URL 스킴: https://guide.ncloud-docs.com/docs/maps-url-scheme
library;

/// 네이버 지도 앱이 '어느 앱에서 열었는지' 알 수 있게 넘기는 값. 앱 ID와 같다.
const appName = 'kr.naturetec.dinnerdecision';

String _q(String value) => Uri.encodeComponent(value);
String _coord(double value) => value.toStringAsFixed(7);

/// 네이버 지도 앱에서 장소 보기.
Uri naverMapPlace({
  required String name,
  required double lat,
  required double lng,
}) => Uri.parse(
  'nmap://place?lat=${_coord(lat)}&lng=${_coord(lng)}'
  '&name=${_q(name)}&appname=$appName',
);

/// 네이버 지도 앱에서 현재 위치 → 식당 도보 길찾기. 출발지를 비우면 앱이 현재 위치를 쓴다.
Uri naverMapWalkRoute({
  required String name,
  required double lat,
  required double lng,
}) => Uri.parse(
  'nmap://route/walk?dlat=${_coord(lat)}&dlng=${_coord(lng)}'
  '&dname=${_q(name)}&appname=$appName',
);

/// 네이버 지도 앱이 없을 때 여는 네이버 지도 웹 검색. 같은 이름 가게가 많아 동네 이름을 붙인다.
Uri naverMapWeb({required String name, String area = ''}) {
  final query = area.isEmpty ? name : '$name $area';
  return Uri.parse('https://map.naver.com/p/search/${_q(query)}');
}

/// 주소에서 동네 이름만. 구가 있으면 구, 없으면 시·군.
/// 예: '서울 성동구 성수이로 12길 3' → '성동구', '경기 양평군 양평읍 …' → '양평군'
String areaOf(String address) {
  final parts = address.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) return '';
  final rest = parts.sublist(1); // 첫 단어는 시·도
  return rest.firstWhere(
    (p) => p.endsWith('구'),
    orElse: () => rest.firstWhere(
      (p) => p.endsWith('시') || p.endsWith('군'),
      orElse: () => rest.first,
    ),
  );
}

/// 카카오 장소 페이지. 카카오는 http 주소를 주므로 https로 바꾼다.
Uri? kakaoPlace(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) return null;
  return uri.replace(scheme: 'https');
}

/// 전화 걸기. 번호가 없으면 null.
Uri? phoneCall(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  return digits.length < 3 ? null : Uri(scheme: 'tel', path: digits);
}
