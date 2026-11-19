import 'package:material_ui/material_ui.dart';

import '../../core/geo.dart';
import '../../domain/models/restaurant.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'cuisine_widgets.dart';

/// 주변 목록의 식당 한 줄.
class RestaurantTile extends StatelessWidget {
  const RestaurantTile({
    super.key,
    required this.place,
    this.lastVisitDays,
    this.onTap,
  });

  final NearbyPlace place;

  /// 마지막으로 간 지 며칠 됐는지. 14일 안이면 배지를 보여준다.
  final int? lastVisitDays;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = place.restaurant;
    final visited = lastVisitDays;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CuisineIcon(r.cuisine),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(r.categoryLabel, style: context.text.bodySmall),
                      if (visited != null && visited <= 14)
                        _VisitBadge(days: visited),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r.roadAddress, style: context.text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            Text(
              formatDistance(place.distanceM),
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitBadge extends StatelessWidget {
  const _VisitBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        days == 0 ? '🕘 오늘 방문' : '🕘 $days일 전 방문',
        style: context.text.labelSmall?.copyWith(
          color: context.scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
