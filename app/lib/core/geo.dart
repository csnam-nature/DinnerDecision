import 'dart:math' as math;

const double _earthRadiusM = 6371000;
const double _metersPerDegLat = 111320;

double _rad(double deg) => deg * math.pi / 180;

/// 두 좌표 사이의 직선 거리(m). 하버사인 공식.
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(a)));
}

/// 기준 좌표에서 동쪽·북쪽으로 몇 m 떨어져 있는지. 지도 그리기용 근사값.
({double eastM, double northM}) metersOffset({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  return (
    eastM: (toLng - fromLng) * _metersPerDegLat * math.cos(_rad(fromLat)),
    northM: (toLat - fromLat) * _metersPerDegLat,
  );
}

/// 기준 좌표에서 동쪽·북쪽으로 주어진 m만큼 옮긴 좌표.
({double lat, double lng}) offsetLatLng(
  double lat,
  double lng, {
  required double eastM,
  required double northM,
}) {
  return (
    lat: lat + northM / _metersPerDegLat,
    lng: lng + eastM / (_metersPerDegLat * math.cos(_rad(lat))),
  );
}

/// 걸어서 걸리는 시간(분). 분당 75m 기준, 최소 1분.
int walkMinutes(int meters) => math.max(1, (meters / 75).round());

/// 목록에 보여줄 거리 글자. 1km부터는 소수 한 자리 km.
String formatDistance(int meters) =>
    meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';
