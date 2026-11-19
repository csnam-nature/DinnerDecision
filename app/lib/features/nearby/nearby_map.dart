import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/app_map_view.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../core/geo.dart';
import '../../data/providers.dart';
import '../../domain/models/restaurant.dart';
import 'nearby_controller.dart';

/// S-11 주변 지도. 마커를 누르면 아래에 미리보기 카드가 나온다.
class NearbyMap extends ConsumerWidget {
  const NearbyMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final radiusM = ref.watch(settingsProvider.select((s) => s.radiusM));
    final avoidDays = ref.watch(
      settingsProvider.select((s) => s.avoidRestaurantDays),
    );
    final lastVisit = ref.watch(lastVisitDaysProvider);
    final places =
        ref.watch(cuisineFilteredPlacesProvider).value ?? const <NearbyPlace>[];
    final selectedId = ref.watch(
      nearbyViewProvider.select((v) => v.selectedMapId),
    );
    final controller = ref.read(nearbyViewProvider.notifier);

    final selectedIndex = places.indexWhere(
      (p) => p.restaurant.id == selectedId,
    );
    final selected = selectedIndex < 0 ? null : places[selectedIndex];
    void step(int by) => controller.selectOnMap(
      places[(selectedIndex + by) % places.length].restaurant.id,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: AppMapView(
            centerLat: location.lat,
            centerLng: location.lng,
            spanM: radiusM * 1.08,
            meLat: location.lat,
            meLng: location.lng,
            radiusM: radiusM,
            selectedId: selected?.restaurant.id,
            onMarkerTap: controller.selectOnMap,
            markers: [
              for (final p in places)
                MapMarker(
                  id: p.restaurant.id,
                  label: p.restaurant.name,
                  lat: p.restaurant.lat,
                  lng: p.restaurant.lng,
                  cuisine: p.restaurant.cuisine,
                  faded:
                      (lastVisit[p.restaurant.id] ?? avoidDays + 1) <=
                      avoidDays,
                ),
            ],
          ),
        ),
        Positioned(
          left: Gap.md,
          right: Gap.md,
          bottom: Gap.xl + Gap.sm,
          child: selected == null
              ? Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.lg,
                        vertical: Gap.sm,
                      ),
                      child: Text(
                        '마커를 누르면 식당 정보가 나와요',
                        style: context.text.bodySmall,
                      ),
                    ),
                  ),
                )
              : _PreviewCard(
                  place: selected,
                  onPrevious: () => step(-1),
                  onNext: () => step(1),
                ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.place,
    required this.onPrevious,
    required this.onNext,
  });

  final NearbyPlace place;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final r = place.restaurant;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CuisineIcon(r.cuisine),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: context.text.titleMedium),
                      Text(
                        '${r.cuisine.label} · ${r.subCategory} · ${formatDistance(place.distanceM)}',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '이전 식당',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: '다음 식당',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(Routes.restaurant(r.id)),
                    child: const Text('상세 보기'),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 48),
                    ),
                    onPressed: () =>
                        showNotReady(context, '네이버 지도 길찾기는 아직 연결 전이에요'),
                    child: const Text('네이버 길찾기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
