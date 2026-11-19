import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/geo.dart';
import '../../domain/models/cuisine.dart';
import '../theme/app_colors.dart';

class MapMarker {
  const MapMarker({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
    required this.cuisine,
    this.faded = false,
  });

  final String id;
  final String label;
  final double lat;
  final double lng;
  final Cuisine cuisine;

  /// 최근에 간 곳은 흐리게 보여준다.
  final bool faded;
}

/// 지도 자리.
///
/// 지금은 마커 위치만 보여주는 그림이다. 3단계에서 이 위젯의 안쪽만
/// flutter_naver_map으로 바꾸면 되도록, 화면들은 이 위젯의 입력값만 안다.
class AppMapView extends StatelessWidget {
  const AppMapView({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.spanM,
    required this.markers,
    this.meLat,
    this.meLng,
    this.radiusM,
    this.selectedId,
    this.onMarkerTap,
  });

  final double centerLat;
  final double centerLng;

  /// 가운데에서 가장 가까운 가장자리까지의 거리(m).
  final double spanM;
  final List<MapMarker> markers;

  /// 내 위치. 있으면 파란 점을 찍는다.
  final double? meLat;
  final double? meLng;

  /// 내 위치를 중심으로 그릴 검색 반경(m).
  final int? radiusM;
  final String? selectedId;
  final ValueChanged<String>? onMarkerTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final scale = math.min(size.width, size.height) / 2 / spanM;
        Offset place(double lat, double lng) {
          final o = metersOffset(
            fromLat: centerLat,
            fromLng: centerLng,
            toLat: lat,
            toLng: lng,
          );
          return Offset(
            size.width / 2 + o.eastM * scale,
            size.height / 2 - o.northM * scale,
          );
        }

        final me = meLat == null || meLng == null
            ? null
            : place(meLat!, meLng!);
        // 고른 마커가 맨 위에 그려지도록 마지막에 둔다.
        final ordered = [...markers]
          ..sort(
            (a, b) =>
                (a.id == selectedId ? 1 : 0) - (b.id == selectedId ? 1 : 0),
          );

        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPainter(
                    background: colors.mapBackground,
                    road: colors.mapRoad,
                    accent: context.scheme.primary,
                    meColor: colors.mapMe,
                    me: me,
                    radiusPx: radiusM == null ? null : radiusM! * scale,
                  ),
                ),
              ),
              for (final m in ordered)
                _MarkerDot(
                  marker: m,
                  at: place(m.lat, m.lng),
                  selected: m.id == selectedId,
                  onTap: onMarkerTap == null ? null : () => onMarkerTap!(m.id),
                ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.scheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '예시 지도 · 네이버 지도 연결 전',
                    style: context.text.labelSmall,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({
    required this.marker,
    required this.at,
    required this.selected,
    this.onTap,
  });

  final MapMarker marker;
  final Offset at;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dot = selected ? 38.0 : 28.0;
    // 눌리는 영역은 점보다 넓게 잡는다.
    final hit = math.max(dot, 40.0);
    return Positioned(
      left: at.dx - hit / 2,
      top: at.dy - hit / 2,
      width: hit,
      height: hit,
      child: Semantics(
        button: onTap != null,
        selected: selected,
        label: marker.faded ? '${marker.label}, 최근 방문' : marker.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: Opacity(
              opacity: marker.faded && !selected ? 0.4 : 1,
              child: Container(
                width: dot,
                height: dot,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.cuisine(marker.cuisine),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.scheme.surface,
                    width: selected ? 3.5 : 2.5,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Text(
                    marker.cuisine.emoji,
                    style: TextStyle(fontSize: selected ? 16 : 12, height: 1.1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.background,
    required this.road,
    required this.accent,
    required this.meColor,
    required this.me,
    required this.radiusPx,
  });

  final Color background;
  final Color road;
  final Color accent;
  final Color meColor;
  final Offset? me;
  final double? radiusPx;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    // 길 모양은 꾸밈일 뿐 실제 도로가 아니다.
    final roadPaint = Paint()
      ..color = road
      ..strokeCap = StrokeCap.round;
    void line(double x1, double y1, double x2, double y2, double width) =>
        canvas.drawLine(
          Offset(x1 * size.width, y1 * size.height),
          Offset(x2 * size.width, y2 * size.height),
          roadPaint..strokeWidth = width,
        );
    line(0, 0.24, 1, 0.20, 12);
    line(0, 0.58, 1, 0.55, 9);
    line(0.30, 0, 0.34, 1, 10);
    line(0.74, 0, 0.80, 1, 8);
    line(0, 0.05, 1, 0.82, 6);

    final center = me;
    if (center == null) return;
    final radius = radiusPx;
    if (radius != null) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = accent.withValues(alpha: 0.07),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    canvas.drawCircle(
      center,
      18,
      Paint()..color = meColor.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(center, 5.5, Paint()..color = meColor);
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.background != background ||
      old.road != road ||
      old.accent != accent ||
      old.meColor != meColor ||
      old.me != me ||
      old.radiusPx != radiusPx;
}
