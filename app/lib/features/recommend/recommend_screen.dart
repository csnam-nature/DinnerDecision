import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../core/dates.dart';
import '../../core/geo.dart';
import '../../data/providers.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/models/meal_log.dart';
import '../../domain/recommend/recommendation.dart';
import '../meal_log_edit/meal_log_draft.dart';
import 'recommend_controller.dart';

/// S-30 오늘의 추천.
class RecommendScreen extends ConsumerWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendProvider);
    final controller = ref.read(recommendProvider.notifier);
    // 설정에서 껐거나 기기에서 움직임 줄이기를 켰으면 고르는 연출을 건너뛴다.
    final animate =
        ref.watch(settingsProvider.select((s) => s.recommendAnimation)) &&
        !MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 추천'),
        actions: [
          if (state.phase == RecommendPhase.result)
            IconButton(
              tooltip: '다른 추천 받기',
              onPressed: () => controller.again(animate: animate),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: switch (state.phase) {
        RecommendPhase.idle => _StartView(
          state: state,
          onStart: () => controller.start(animate: animate),
        ),
        RecommendPhase.picking => const _PickingView(),
        RecommendPhase.result => _ResultView(
          state: state,
          onAgain: () => controller.again(animate: animate),
        ),
      },
    );
  }
}

class _StartView extends ConsumerWidget {
  const _StartView({required this.state, required this.onStart});

  final RecommendState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider).value;
    final location = ref.watch(locationProvider);
    final today = ref.watch(clockProvider)();
    final avoidDays = ref.watch(
      settingsProvider.select((s) => s.avoidRestaurantDays),
    );
    final recentDinners = ref
        .watch(mealLogsProvider)
        .where((log) => log.mealType == MealType.dinner)
        .take(3)
        .map((log) {
          final what = log.menu.isEmpty ? log.restaurantName : log.menu;
          return '${relativeDay(daysBetween(log.date, today))} ${log.cuisine.emoji} $what';
        })
        .join(' · ');

    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('지금', style: context.text.labelSmall),
              Text(
                '${weather?.summaryWithDust ?? '날씨를 확인하는 중…'} · 📍 ${location.name}',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: Gap.sm),
              Text('최근 저녁', style: context.text.labelSmall),
              Text(
                recentDinners.isEmpty ? '아직 기록이 없어요' : recentDinners,
                style: context.text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
        const ExcludeSemantics(
          child: Text(
            '✨',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 56),
          ),
        ),
        const SizedBox(height: Gap.lg),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 60),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: const StadiumBorder(),
              textStyle: context.text.labelLarge?.copyWith(fontSize: 18),
            ),
            onPressed: onStart,
            child: const Text('오늘 뭐 먹지? 추천 받기'),
          ),
        ),
        const SizedBox(height: Gap.lg),
        Text(
          state.failed
              ? '주변 식당이나 날씨를 불러오지 못했어요. 잠시 후 다시 눌러 주세요.'
              : '최근 $avoidDays일 안에 간 식당은 빼고, 날씨에 맞는 곳을 골라요',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: state.failed ? context.scheme.error : null,
          ),
        ),
        const SizedBox(height: Gap.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('분류 고정', style: context.text.bodySmall),
            const SizedBox(width: Gap.md),
            DropdownButton<Cuisine?>(
              value: state.lockCuisine,
              style: context.text.titleSmall,
              onChanged: ref.read(recommendProvider.notifier).setLock,
              items: [
                const DropdownMenuItem(value: null, child: Text('상관없음')),
                for (final c in Cuisine.filterable)
                  DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}만'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// 고르는 동안 분류 그림이 번갈아 나오는 짧은 연출.
class _PickingView extends StatefulWidget {
  const _PickingView();

  @override
  State<_PickingView> createState() => _PickingViewState();
}

class _PickingViewState extends State<_PickingView> {
  late final Timer _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 110),
      (_) => setState(() => _index = (_index + 1) % Cuisine.filterable.length),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Text(
              Cuisine.filterable[_index].emoji,
              style: const TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: Gap.md),
          Text('날씨와 기록을 보고 고르는 중…', style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.state, required this.onAgain});

  final RecommendState state;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = state.result!;
    final big = state.big;
    final controller = ref.read(recommendProvider.notifier);
    if (big == null) {
      return StateView(
        emoji: '🤔',
        title: '조건에 맞는 식당이 더 없어요',
        message: '넘긴 식당, 분류 고정, 못 먹는 음식 설정을 확인해 주세요',
        actionLabel: '처음부터 다시 추천',
        onAction: controller.reset,
      );
    }
    final others = [
      for (final (index, pick) in result.picks.indexed)
        if (pick != big) (index, pick),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.xl),
      children: [
        if (result.relaxed)
          Container(
            margin: const EdgeInsets.only(bottom: Gap.sm),
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: context.scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Radii.input),
            ),
            child: Text(
              '최근 간 곳을 빼니 후보가 너무 적어서, 3일 전 기록까지만 피했어요',
              style: context.text.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
        _BigCard(pick: big, candidateCount: result.candidateCount),
        if (others.isNotEmpty) ...[
          const SizedBox(height: Gap.xl),
          Text('다른 후보', style: context.text.titleSmall),
          const SizedBox(height: Gap.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (index, pick)) in others.indexed) ...[
                  if (i > 0) const SizedBox(width: Gap.sm),
                  Expanded(
                    child: _SmallCard(
                      pick: pick,
                      onTap: () => controller.showBig(index),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        Center(
          child: OutlinedButton.icon(
            onPressed: onAgain,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('다른 추천 받기'),
          ),
        ),
      ],
    );
  }
}

class _BigCard extends ConsumerWidget {
  const _BigCard({required this.pick, required this.candidateCount});

  final Recommendation pick;
  final int candidateCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = pick.place.restaurant;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CuisineIcon(r.cuisine, size: 30),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(
                    '${r.cuisine.label} · ${r.subCategory} · ${formatDistance(pick.place.distanceM)}',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            Text(r.name, style: context.text.headlineMedium),
            const SizedBox(height: Gap.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: context.colors.primarySoft,
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('왜 추천하나요?', style: context.text.labelMedium),
                  for (final reason in pick.reasons)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.sm),
                      child: ReasonRow(reason),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              '추천 점수 ${pick.score} · 후보 $candidateCount곳 중에서 골랐어요',
              style: context.text.labelSmall,
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
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 48),
                    ),
                    onPressed: () => context.push(
                      Routes.mealLog,
                      extra: MealLogDraft.forRestaurant(
                        r,
                        date: dateOnly(ref.read(clockProvider)()),
                        menu: r.subCategory,
                        fromRecommend: true,
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('여기로 결정'),
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

class _SmallCard extends StatelessWidget {
  const _SmallCard({required this.pick, required this.onTap});

  final Recommendation pick;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = pick.place.restaurant;
    final first = pick.reasons.first;
    return Semantics(
      button: true,
      hint: '크게 보기',
      child: Material(
        color: context.colors.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: context.colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.cuisine.emoji} ${r.name}',
                  style: context.text.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  '${formatDistance(pick.place.distanceM)} · ${r.subCategory}',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  '${first.emoji} ${first.short}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
