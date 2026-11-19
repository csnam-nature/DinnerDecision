import 'package:url_launcher/url_launcher.dart';

import '../core/map_links.dart' as links;
import '../domain/models/restaurant.dart';

/// 다른 앱·웹 열기. 테스트에서 바꿔 끼울 수 있게 나눠 둔다.
abstract interface class ExternalLauncher {
  /// 이 주소를 열 앱이 기기에 있는지. 네이버 지도 앱 확인에 쓴다.
  Future<bool> canOpen(Uri uri);

  /// 다른 앱(또는 브라우저)으로 연다. 열지 못하면 false.
  Future<bool> open(Uri uri);
}

class UrlLauncherExternal implements ExternalLauncher {
  const UrlLauncherExternal();

  @override
  Future<bool> canOpen(Uri uri) => canLaunchUrl(uri);

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}

/// 어디로 열었는지. 화면에서 안내 문구를 고르는 데 쓴다.
enum OpenResult { app, web, failed }

/// 식당 상세의 외부 연결 버튼들.
class RestaurantLinks {
  const RestaurantLinks(this._launcher);

  final ExternalLauncher _launcher;

  /// 네이버 지도 앱에서 장소 보기. 앱이 없으면 네이버 지도 웹.
  Future<OpenResult> openNaverMap(Restaurant r) =>
      _naver(links.naverMapPlace(name: r.name, lat: r.lat, lng: r.lng), r);

  /// 네이버 지도 앱 도보 길찾기. 앱이 없으면 네이버 지도 웹에서 장소를 연다.
  Future<OpenResult> openWalkRoute(Restaurant r) =>
      _naver(links.naverMapWalkRoute(name: r.name, lat: r.lat, lng: r.lng), r);

  Future<OpenResult> _naver(Uri appUri, Restaurant r) async {
    if (await _launcher.canOpen(appUri) && await _launcher.open(appUri)) {
      return OpenResult.app;
    }
    final web = links.naverMapWeb(
      name: r.name,
      area: links.areaOf(r.roadAddress),
    );
    return await _launcher.open(web) ? OpenResult.web : OpenResult.failed;
  }

  Future<OpenResult> openKakaoPlace(Restaurant r) =>
      _simple(links.kakaoPlace(r.kakaoUrl));

  Future<OpenResult> call(Restaurant r) => _simple(links.phoneCall(r.phone));

  Future<OpenResult> _simple(Uri? uri) async {
    if (uri == null) return OpenResult.failed;
    return await _launcher.open(uri) ? OpenResult.app : OpenResult.failed;
  }
}
