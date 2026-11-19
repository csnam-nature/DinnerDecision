import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/models/app_location.dart';
import '../api/api_client.dart';
import '../sample/sample_data.dart';

/// 현재 위치를 가져오지 못한 이유.
enum LocationFailure {
  serviceOff('위치 서비스(GPS)가 꺼져 있어요', '위치 켜기'),
  denied('위치 권한을 허용하지 않았어요', '다시 요청'),
  deniedForever('설정에서 위치 권한을 허용해 주세요', '설정 열기'),
  timeout('위치를 찾는 데 시간이 너무 걸려요', '다시 시도');

  const LocationFailure(this.message, this.actionLabel);

  final String message;
  final String actionLabel;
}

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  @override
  String toString() => 'LocationException(${failure.name})';
}

/// 기준 위치를 정하는 곳: GPS로 현재 위치 찾기, 동 이름 붙이기, 주소·장소 검색.
abstract interface class LocationRepository {
  /// GPS로 찾은 현재 위치. 실패하면 [LocationException].
  Future<AppLocation> current();

  /// 위치 직접 설정 화면의 검색.
  Future<List<AppLocation>> search(String query);

  /// 권한이나 GPS가 꺼져 있을 때 휴대폰 설정 화면을 연다.
  Future<void> openSettings(LocationFailure failure);
}

/// 휴대폰 GPS(geolocator) + 서버 `/region`, `/search`.
class DeviceLocationRepository implements LocationRepository {
  DeviceLocationRepository(this._client);

  final ApiClient _client;

  @override
  Future<AppLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationException(LocationFailure.denied);
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        // 식당 1km 검색에는 수십 m 정확도면 충분하다. 배터리와 시간을 아낀다.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) {
      throw const LocationException(LocationFailure.timeout);
    }
    return _named(position.latitude, position.longitude);
  }

  /// 동 이름을 못 가져와도 위치는 쓸 수 있게 '현재 위치'로 둔다.
  Future<AppLocation> _named(double lat, double lng) async {
    try {
      final region = await _client.get(
        '/region',
        query: {'lat': lat.toStringAsFixed(5), 'lng': lng.toStringAsFixed(5)},
      );
      return AppLocation(
        name: region['name'] as String? ?? '현재 위치',
        detail: region['detail'] as String? ?? '',
        lat: lat,
        lng: lng,
        source: LocationSource.gps,
      );
    } on ApiException {
      return AppLocation(
        name: '현재 위치',
        lat: lat,
        lng: lng,
        source: LocationSource.gps,
      );
    }
  }

  @override
  Future<List<AppLocation>> search(String query) async {
    final body = await _client.get('/search', query: {'query': query});
    return [
      for (final item in body['results'] as List<dynamic>? ?? const [])
        AppLocation(
          name: (item as Map<String, dynamic>)['name'] as String,
          detail: item['detail'] as String? ?? '',
          lat: (item['lat'] as num).toDouble(),
          lng: (item['lng'] as num).toDouble(),
          source: LocationSource.search,
        ),
    ];
  }

  @override
  Future<void> openSettings(LocationFailure failure) async {
    if (failure == LocationFailure.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}

/// 예시 위치를 쓰는 가짜 구현. 서버 없이 실행하거나 테스트할 때 쓴다.
class FakeLocationRepository implements LocationRepository {
  const FakeLocationRepository({this.failure});

  /// 정해 두면 [current]가 이 이유로 실패한다.
  final LocationFailure? failure;

  @override
  Future<AppLocation> current() async {
    if (failure != null) throw LocationException(failure!);
    return sampleLocations.first;
  }

  @override
  Future<List<AppLocation>> search(String query) async => [
    for (final l in sampleLocations)
      if (l.name.contains(query) || l.detail.contains(query)) l,
  ];

  @override
  Future<void> openSettings(LocationFailure failure) async {}
}
