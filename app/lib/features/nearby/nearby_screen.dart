import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../app/widgets/restaurant_tile.dart';
import '../../core/geo.dart';
import '../../data/providers.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/models/restaurant.dart';
import 'nearby_controller.dart';
import 'nearby_map.dart';

/// S-10 주변 목록 / S-11 주변 지도.
class NearbyScreen extends ConsumerWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final view = ref.watch(nearbyViewProvider);
    final weather = ref.watch(weatherProvider).value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Gap.sm,
        title: TextButton.icon(
          onPressed: () => context.push(Routes.location),
          icon: const Icon(Icons.place_outlined),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  location.name,
                  style: context.text.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: view.mapMode ? '목록으로 보기' : '지도로 보기',
            onPressed: ref.read(nearbyViewProvider.notifier).toggleMap,
            icon: Icon(
              view.mapMode ? Icons.format_list_bulleted : Icons.map_outlined,
            ),
          ),
          IconButton(
            tooltip: '새로고침',
            onPressed: () => ref.invalidate(nearbyPlacesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: Text(
              weather?.summaryWithDust ?? '날씨를 확인하는 중…',
              style: context.text.bodySmall,
            ),
          ),
          const _CuisineFilterBar(),
          if (!view.mapMode) const _ListTools(),
          Expanded(
            child: view.mapMode ? const NearbyMap() : const _NearbyList(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: view.mapMode
          ? null
          : FloatingActionButton.extended(
              // 탭마다 떠 있는 버튼이 있어서 서로 다른 이름을 붙여야 한다.
              heroTag: 'nearby-recommend',
              onPressed: () => context.go(Routes.recommend),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('오늘의 추천 받기'),
            ),
    );
  }
}

class _CuisineFilterBar extends ConsumerWidget {
  const _CuisineFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(nearbyViewProvider.select((v) => v.cuisine));
    final places = ref.watch(shownPlacesProvider).value;
    int? count(Cuisine? c) => places == null
        ? null
        : c == null
        ? places.length
        : places.where((p) => p.restaurant.cuisine == c).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: Row(
        children: [
          for (final c in <Cuisine?>[null, ...Cuisine.filterable])
            Padding(
              padding: const EdgeInsets.only(right: Gap.sm),
              child: CuisineChip(
                cuisine: c,
                count: count(c),
                selected: selected == c,
                onSelected: () =>
                    ref.read(nearbyViewProvider.notifier).setCuisine(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListTools extends ConsumerWidget {
  const _ListTools();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(nearbyViewProvider);
    final controller = ref.read(nearbyViewProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.xs, 0),
      child: Row(
        children: [
          Text('정렬', style: context.text.bodySmall),
          const SizedBox(width: Gap.sm),
          // 글자를 키워도 오른쪽 체크박스 글자가 줄바꿈되지 않도록 정렬 쪽이 줄어들게 한다.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<NearbySort>(
                value: view.sort,
                isDense: true,
                underline: const SizedBox.shrink(),
                style: context.text.titleSmall,
                onChanged: (sort) => controller.setSort(sort!),
                items: [
                  for (final s in NearbySort.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => controller.setHideRecent(!view.hideRecent),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: view.hideRecent,
                  onChanged: (v) => controller.setHideRecent(v ?? false),
                ),
                Text('최근 간 곳 숨김', style: context.text.bodySmall),
                const SizedBox(width: Gap.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyList extends ConsumerWidget {
  const _NearbyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(nearbyListProvider);
    final lastVisit = ref.watch(lastVisitDaysProvider);
    final radiusM = ref.watch(settingsProvider.select((s) => s.radiusM));
    final cuisine = ref.watch(nearbyViewProvider.select((v) => v.cuisine));

    return list.when(
      loading: () => const ListSkeleton(),
      error: (error, _) => StateView(
        emoji: '📡',
        title: '식당 목록을 불러오지 못했어요',
        message: '인터넷 연결을 확인한 뒤 다시 시도해 주세요',
        actionLabel: '다시 시도',
        onAction: () => ref.invalidate(nearbyPlacesProvider),
      ),
      data: (places) {
        if (places.isEmpty) {
          final what = cuisine == null ? '식당' : '${cuisine.label} 식당';
          return StateView(
            emoji: '🍽',
            title: '${formatDistance(radiusM)} 안에 $what이 없어요',
            actionLabel: radiusM < 2000 ? '반경 2km로 넓히기' : null,
            onAction: () => ref
                .read(settingsProvider.notifier)
                .update((s) => s.copyWith(radiusM: 2000)),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(nearbyPlacesProvider.future),
          child: ListView.separated(
            // 떠 있는 추천 버튼에 마지막 줄이 가리지 않게 아래를 비운다.
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: places.length + 1,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              if (index == places.length) {
                return Padding(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: Text(
                    '줄을 왼쪽으로 밀면 숨길 수 있어요 · 지금은 예시 데이터예요',
                    style: context.text.labelSmall,
                  ),
                );
              }
              final place = places[index];
              return _DismissibleRow(
                place: place,
                lastVisitDays: lastVisit[place.restaurant.id],
              );
            },
          ),
        );
      },
    );
  }
}

class _DismissibleRow extends ConsumerWidget {
  const _DismissibleRow({required this.place, required this.lastVisitDays});

  final NearbyPlace place;
  final int? lastVisitDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = place.restaurant;
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: context.scheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
        child: Text(
          '숨기기',
          style: context.text.labelLarge?.copyWith(
            color: context.scheme.onError,
          ),
        ),
      ),
      onDismissed: (_) => hideRestaurant(ref, ScaffoldMessenger.of(context), r),
      child: RestaurantTile(
        place: place,
        lastVisitDays: lastVisitDays,
        onTap: () => context.push(Routes.restaurant(r.id)),
      ),
    );
  }
}

/// 식당을 숨기고 되돌리기 알림을 띄운다.
void hideRestaurant(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
  Restaurant restaurant,
) {
  final excluded = ref.read(excludedProvider.notifier)..hide(restaurant);
  showUndo(
    messenger,
    '${restaurant.name} 숨김',
    () => excluded.restore(restaurant.id),
  );
}
