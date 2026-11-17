import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../core/dates.dart';
import '../../data/providers.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/models/meal_log.dart';
import '../meal_log_edit/meal_log_draft.dart';
import 'calendar_controller.dart';
import 'day_sheet.dart';
import 'month_calendar.dart';

/// S-40 달력. 기록이 있는 날에 분류 색 점을 찍는다.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    final controller = ref.read(calendarViewProvider.notifier);
    final today = dateOnly(ref.watch(clockProvider)());

    return Scaffold(
      appBar: AppBar(
        title: const Text('달력'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: TextButton(
              onPressed: () => controller.showDay(today),
              child: const Text('오늘'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('달력')),
                  ButtonSegment(value: true, label: Text('목록')),
                ],
                selected: {view.listMode},
                onSelectionChanged: (s) => controller.setListMode(s.first),
              ),
            ),
          ),
          Expanded(
            child: view.listMode ? const _LogList() : const _MonthView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar-add',
        tooltip: '${formatMonthDayLong(view.selectedDay)} 기록 추가',
        onPressed: () => context.push(
          Routes.mealLog,
          extra: MealLogDraft.blank(view.selectedDay),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthView extends ConsumerWidget {
  const _MonthView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    final controller = ref.read(calendarViewProvider.notifier);
    final logs = ref.watch(mealLogsProvider);
    final today = dateOnly(ref.watch(clockProvider)());

    final byDay = <DateTime, List<MealLog>>{};
    for (final log in logs) {
      byDay.putIfAbsent(dateOnly(log.date), () => []).add(log);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        MonthCalendar(
          month: view.focusedDay,
          today: today,
          selectedDay: view.selectedDay,
          logsByDay: byDay,
          onMonthChanged: controller.setFocusedMonth,
          onDayTap: (day) {
            controller.showDay(day);
            showDaySheet(context, day);
          },
        ),
        _MonthSummary(month: view.focusedDay, logs: logs),
      ],
    );
  }
}

/// 보고 있는 달의 분류 비율과 횟수.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.month, required this.logs});

  final DateTime month;
  final List<MealLog> logs;

  @override
  Widget build(BuildContext context) {
    final inMonth = logs
        .where(
          (log) => log.date.year == month.year && log.date.month == month.month,
        )
        .toList();
    final counts = <Cuisine, int>{};
    for (final log in inMonth) {
      counts[log.cuisine] = (counts[log.cuisine] ?? 0) + 1;
    }
    final order = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    // 그 식당에 처음 간 기록이 이 달에 있는 경우를 센다.
    final firstVisits = inMonth
        .where(
          (log) =>
              log.restaurantId != null &&
              !logs.any(
                (other) =>
                    other.restaurantId == log.restaurantId &&
                    other.date.isBefore(log.date),
              ),
        )
        .map((log) => log.restaurantId)
        .toSet()
        .length;
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${month.month}월 요약', style: context.text.titleSmall),
          const SizedBox(height: Gap.sm),
          if (inMonth.isEmpty)
            Text('이 달에는 기록이 없어요', style: context.text.bodySmall)
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final c in order)
                      Expanded(
                        flex: counts[c]!,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: colors.cuisine(c),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.md,
              runSpacing: Gap.xs,
              children: [
                for (final c in order)
                  Text(
                    '${c.emoji} ${c.label} ${(counts[c]! * 100 / inMonth.length).round()}%',
                    style: context.text.bodySmall?.copyWith(
                      color: context.scheme.onSurface,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Text(
              '이번 달 ${inMonth.length}번 기록 · 처음 간 곳 $firstVisits곳',
              style: context.text.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// 목록 보기. 식당·메뉴 이름으로 찾을 수 있다.
class _LogList extends ConsumerWidget {
  const _LogList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(calendarViewProvider.select((v) => v.query)).trim();
    final logs = ref
        .watch(mealLogsProvider)
        .where(
          (log) =>
              query.isEmpty ||
              '${log.restaurantName} ${log.menu}'.contains(query),
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
          child: TextField(
            onChanged: ref.read(calendarViewProvider.notifier).setQuery,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '식당·메뉴 이름으로 찾기',
            ),
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? const StateView(emoji: '🔍', title: '찾는 기록이 없어요')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      leading: CuisineIcon(log.cuisine, size: 36),
                      title: Text(
                        log.restaurantName,
                        style: context.text.titleSmall,
                      ),
                      subtitle: Text(
                        [
                          formatMonthDay(log.date),
                          log.mealType.label,
                          if (log.menu.isNotEmpty) log.menu,
                        ].join(' · '),
                      ),
                      trailing: RatingStars(rating: log.rating),
                      onTap: () => showDaySheet(context, log.date),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
