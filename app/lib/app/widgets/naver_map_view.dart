import 'dart:math' as math;

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/geo.dart';
import '../theme/app_colors.dart';
import 'app_map_view.dart';

/// 네이버 지도 Client ID. 빌드할 때 넣는다. 비밀값은 아니고 앱 ID로 사용처가 제한된다.
///
/// ```
/// flutter run --dart-define=NAVER_MAP_CLIENT_ID=<Client ID>
/// ```
const naverMapClientId = String.fromEnvironment('NAVER_MAP_CLIENT_ID');

/// 네이버 지도를 쓸 준비. 성공하면 [AppMapView]가 네이버 지도로 그린다.
/// Client ID가 없거나 초기화에 실패하면 그림 지도로 둔다.
Future<void> initNaverMap() async {
  if (naverMapClientId.isEmpty) return;
  try {
    await FlutterNaverMap().init(
      clientId: naverMapClientId,
      onAuthFailed: (e) => debugPrint('네이버 지도 인증 실패: $e'),
    );
    AppMapView.useNaverMap = true;
  } on Exception catch (e) {
    debugPrint('네이버 지도 초기화 실패: $e');
  }
}

/// 네이버 지도로 그리는 [AppMapView]. 입력값은 [AppMapView]와 같다.
///
/// - 마커: 분류 색, 고른 식당은 크게, 최근 간 곳은 흐리게
/// - 내 위치: 네이버 지도의 위치 표시 + 검색 반경 원
/// - 로고 누르기는 끈다. 로고를 누르면 뜨는 정보 창이 예전 material 대화상자라
///   material_ui 앱에서는 동작하지 않기 때문이다. 출처는 설정 화면에 적는다.
class NaverMapView extends StatefulWidget {
  const NaverMapView({super.key, required this.config});

  final AppMapView config;

  @override
  State<NaverMapView> createState() => _NaverMapViewState();
}

class _NaverMapViewState extends State<NaverMapView> {
  NaverMapController? _controller;
  final _markers = <String, NMarker>{};
  NCircleOverlay? _radius;

  AppMapView get _c => widget.config;

  @override
  void didUpdateWidget(NaverMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.config;
    if (old.centerLat != _c.centerLat ||
        old.centerLng != _c.centerLng ||
        old.spanM != _c.spanM) {
      _fitCamera();
    }
    _syncOverlays();
  }

  Future<void> _onReady(NaverMapController controller) async {
    _controller = controller;
    await _fitCamera();
    await _syncOverlays();
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null) return;
    final sw = offsetLatLng(
      _c.centerLat,
      _c.centerLng,
      eastM: -_c.spanM,
      northM: -_c.spanM,
    );
    final ne = offsetLatLng(
      _c.centerLat,
      _c.centerLng,
      eastM: _c.spanM,
      northM: _c.spanM,
    );
    await controller.updateCamera(
      NCameraUpdate.fitBounds(
        NLatLngBounds(
          southWest: NLatLng(sw.lat, sw.lng),
          northEast: NLatLng(ne.lat, ne.lng),
        ),
      ),
    );
  }

  /// 바뀐 마커만 더하고, 빼고, 고친다. 식당이 수백 곳이어도 고른 식당만 바뀌면 두 개만 고친다.
  Future<void> _syncOverlays() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final colors = context.colors;

    final wanted = {for (final m in _c.markers) m.id: m};
    for (final id in _markers.keys.toList()) {
      if (!wanted.containsKey(id)) {
        final marker = _markers.remove(id)!;
        await controller.deleteOverlay(marker.info);
      }
    }

    final added = <NAddableOverlay>{};
    for (final m in _c.markers) {
      final style = _MarkerStyle.of(m, selected: m.id == _c.selectedId);
      final existing = _markers[m.id];
      if (existing == null) {
        final marker = NMarker(
          id: m.id,
          position: NLatLng(m.lat, m.lng),
          icon: _pin,
          iconTintColor: colors.cuisine(m.cuisine),
          size: style.size,
          alpha: style.alpha,
          caption: NOverlayCaption(text: m.label, textSize: 11),
          isHideCollidedCaptions: true,
        )..setZIndex(style.zIndex);
        final onTap = _c.onMarkerTap;
        if (onTap != null) marker.setOnTapListener((_) => onTap(m.id));
        _markers[m.id] = marker;
        added.add(marker);
      } else if (existing.size != style.size || existing.alpha != style.alpha) {
        existing
          ..setSize(style.size)
          ..setAlpha(style.alpha)
          ..setZIndex(style.zIndex);
      }
    }

    final meLat = _c.meLat;
    final meLng = _c.meLng;
    final radiusM = _c.radiusM;
    if (meLat != null && meLng != null) {
      controller.getLocationOverlay()
        ..setPosition(NLatLng(meLat, meLng))
        ..setIsVisible(true);
      if (radiusM != null) {
        final circle = _radius;
        if (circle == null) {
          final newCircle = NCircleOverlay(
            id: 'search-radius',
            center: NLatLng(meLat, meLng),
            radius: radiusM.toDouble(),
            color: colors.mapMe.withValues(alpha: 0.06),
            outlineColor: colors.mapMe.withValues(alpha: 0.5),
            outlineWidth: 1,
          );
          _radius = newCircle;
          added.add(newCircle);
        } else {
          circle
            ..setCenter(NLatLng(meLat, meLng))
            ..setRadius(radiusM.toDouble());
        }
      }
    }

    if (added.isNotEmpty) await controller.addOverlayAll(added);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return NaverMap(
          // 목록·상세 화면 안에 있어도 지도를 손가락으로 움직일 수 있게 한다.
          forceGesture: _c.interactive,
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(_c.centerLat, _c.centerLng),
              zoom: initialZoom(
                spanM: _c.spanM,
                lat: _c.centerLat,
                sizePx: math.min(box.maxWidth, box.maxHeight),
              ),
            ),
            locale: const Locale('ko'),
            logoClickEnable: false,
            scaleBarEnable: _c.interactive,
            scrollGesturesEnable: _c.interactive,
            zoomGesturesEnable: _c.interactive,
            rotationGesturesEnable: false,
            tiltGesturesEnable: false,
          ),
          onMapReady: _onReady,
        );
      },
    );
  }
}

/// 검은 핀 + 가운데 흰 점. 네이버 지도는 아이콘에 색을 덧입히므로
/// 검은 부분은 분류 색이 되고 흰 점은 그대로 남는다.
const _pin = NOverlayImage.fromAssetImage('assets/map/marker.png');

class _MarkerStyle {
  const _MarkerStyle(this.size, this.alpha, this.zIndex);

  factory _MarkerStyle.of(MapMarker m, {required bool selected}) {
    if (selected) return const _MarkerStyle(Size(34, 44), 1, 10);
    return _MarkerStyle(const Size(24, 31), m.faded ? 0.45 : 1, 0);
  }

  final Size size;
  final double alpha;
  final int zIndex;
}

/// 가운데에서 가장자리까지 [spanM]이 보이는 줌 레벨 (256px 타일 웹 메르카토르 기준).
/// 지도가 뜬 뒤 fitBounds로 정확히 맞추므로 처음 잠깐만 쓰인다.
double initialZoom({
  required double spanM,
  required double lat,
  required double sizePx,
}) {
  if (sizePx <= 0 || !sizePx.isFinite) return 15;
  final metersPerPx = spanM * 2 / sizePx;
  final zoom =
      math.log(156543.03392 * math.cos(lat * math.pi / 180) / metersPerPx) /
      math.ln2;
  return zoom.clamp(6, 19).toDouble();
}
