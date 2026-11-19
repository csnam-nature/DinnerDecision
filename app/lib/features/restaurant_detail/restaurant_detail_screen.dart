import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/app_map_view.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../core/dates.dart';
import '../../core/geo.dart';
import '../../data/external_launcher.dart';
import '../../data/providers.dart';
import '../meal_log_edit/meal_log_draft.dart';
import '../nearby/nearby_screen.dart' show hideRestaurant;

/// S-20 식당 상세.
class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeByIdProvider(restaurantId));
    return place.when(
      loading: () =>
          Scaffold(appBar: AppBar(), body: const ListSkeleton(rows: 3)),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: StateView(
          emoji: '📡',
          title: '식당 정보를 불러오지 못했어요',
          actionLabel: '다시 시도',
          onAction: () => ref.invalidate(placeByIdProvider(restaurantId)),
        ),
      ),
      data: (place) => place == null
          ? Scaffold(
              appBar: AppBar(),
              body: const StateView(emoji: '🤔', title: '식당 정보를 찾을 수 없어요'),
            )
          : _Detail(place: place),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.place});

  final PlaceDetail place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = place.restaurant;
    final location = ref.watch(locationProvider);
    final today = ref.watch(clockProvider)();
    final visits = ref
        .watch(mealLogsProvider)
        .where((log) => log.restaurantId == r.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: '이 식당 숨기기',
            icon: const Icon(Icons.visibility_off_outlined),
            onPressed: () {
              hideRestaurant(ref, ScaffoldMessenger.of(context), r);
              context.pop();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 180,
            child: AppMapView(
              centerLat: r.lat,
              centerLng: r.lng,
              // 내 위치가 작은 지도 안에 들어오도록 거리에 맞춰 넓힌다.
              spanM: ((place.distanceM ?? 0) * 1.3).clamp(150, 1500).toDouble(),
              meLat: location?.lat,
              meLng: location?.lng,
              selectedId: r.id,
              interactive: false,
              markers: [
                MapMarker(
                  id: r.id,
                  label: r.name,
                  lat: r.lat,
                  lng: r.lng,
                  cuisine: r.cuisine,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CuisineIcon(r.cuisine, size: 30),
                    const SizedBox(width: Gap.sm),
                    Text(r.categoryLabel, style: context.text.bodySmall),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                Text(r.name, style: context.text.headlineSmall),
                const SizedBox(height: Gap.md),
                if (place.distanceM case final meters?)
                  _InfoLine(
                    icon: Icons.directions_walk,
                    text:
                        '${formatDistance(meters)} · 걸어서 ${walkMinutes(meters)}분',
                  ),
                _InfoLine(
                  icon: Icons.home_outlined,
                  text: r.roadAddress,
                  onTap: () => _copyAddress(context, r.roadAddress),
                  semanticHint: '주소 복사',
                ),
                if (r.phone.isNotEmpty)
                  _InfoLine(
                    icon: Icons.call_outlined,
                    text: r.phone,
                    onTap: () => _open(context, ref, (l) => l.call(r)),
                    semanticHint: '전화 걸기',
                  ),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _open(context, ref, (l) => l.openNaverMap(r)),
                        icon: const Icon(Icons.map_outlined, size: 20),
                        label: const Text('네이버 지도'),
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _open(context, ref, (l) => l.openWalkRoute(r)),
                        icon: const Icon(Icons.near_me_outlined, size: 20),
                        label: const Text('길찾기'),
                      ),
                    ),
                  ],
                ),
                if (r.kakaoUrl != null)
                  TextButton(
                    onPressed: () =>
                        _open(context, ref, (l) => l.openKakaoPlace(r)),
                    child: const Text('카카오 장소 정보 보기 · 메뉴·사진 ›'),
                  ),
              ],
            ),
          ),
          Container(height: Gap.sm, color: context.colors.surfaceMuted),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visits.isEmpty ? '내 방문 기록' : '내 방문 기록 (${visits.length}회)',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: Gap.sm),
                if (visits.isEmpty)
                  Text('아직 방문 기록이 없어요', style: context.text.bodySmall)
                else
                  for (final log in visits)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                formatMonthDay(log.date),
                                if (log.menu.isNotEmpty) log.menu,
                                if (log.memo.isNotEmpty) '"${log.memo}"',
                              ].join(' '),
                              style: context.text.bodyMedium,
                            ),
                          ),
                          RatingStars(rating: log.rating),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PrimaryBottomButton(
        label: '오늘 여기서 먹었어요',
        onPressed: () => context.push(
          Routes.mealLog,
          extra: MealLogDraft.forRestaurant(r, date: today),
        ),
      ),
    );
  }
}

/// 다른 앱을 열고, 열지 못했으면 알려 준다.
Future<void> _open(
  BuildContext context,
  WidgetRef ref,
  Future<OpenResult> Function(RestaurantLinks links) action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await action(ref.read(restaurantLinksProvider));
  if (result == OpenResult.failed) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('열 수 있는 앱이 없어요')));
  }
}

void _copyAddress(BuildContext context, String address) {
  Clipboard.setData(ClipboardData(text: address));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('주소를 복사했어요')));
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.onTap,
    this.semanticHint,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  /// 화면 읽기 프로그램에 알려 줄 누르면 하는 일.
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      onTapHint: semanticHint,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.colors.textSecondary),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  text,
                  style: context.text.bodyMedium?.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
