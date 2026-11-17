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
import '../../domain/models/meal_log.dart';
import '../meal_log_edit/meal_log_draft.dart';

/// S-41 그날 기록. 아래에서 올라오는 시트로 보여준다.
Future<void> showDaySheet(BuildContext context, DateTime date) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DaySheet(date: date),
  );
}

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref
        .watch(mealLogsProvider)
        .where((log) => isSameDate(log.date, date))
        .toList();
    final weather = logs.isEmpty ? '' : logs.first.weatherText;
    // 시트를 닫은 뒤에도 쓸 수 있게 미리 잡아 둔다.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    void closeThen(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatMonthDayLong(date),
                    style: context.text.titleLarge,
                  ),
                ),
                if (weather.isNotEmpty)
                  Text(weather, style: context.text.bodySmall),
              ],
            ),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.lg),
                child: Text('이 날은 기록이 없어요', style: context.text.bodySmall),
              )
            else
              for (final log in logs)
                _LogEntry(
                  log: log,
                  onOpenRestaurant: log.restaurantId == null
                      ? null
                      : () => closeThen(
                          () =>
                              router.push(Routes.restaurant(log.restaurantId!)),
                        ),
                  onEdit: () => closeThen(
                    () => router.push(
                      Routes.mealLog,
                      extra: MealLogDraft.fromLog(log),
                    ),
                  ),
                  onDelete: () => closeThen(() {
                    final controller = ref.read(mealLogsProvider.notifier)
                      ..delete(log.id);
                    showUndo(messenger, '기록을 지웠어요', () => controller.save(log));
                  }),
                ),
            const SizedBox(height: Gap.md),
            OutlinedButton.icon(
              onPressed: () => closeThen(
                () => router.push(
                  Routes.mealLog,
                  extra: MealLogDraft.blank(date),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('이 날 기록 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({
    required this.log,
    required this.onEdit,
    required this.onDelete,
    this.onOpenRestaurant,
  });

  final MealLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenRestaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenRestaurant,
            child: Row(
              children: [
                CuisineIcon(log.cuisine, size: 30),
                const SizedBox(width: Gap.sm),
                Text(log.mealType.label, style: context.text.bodySmall),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(
                    log.restaurantName,
                    style: context.text.titleMedium,
                  ),
                ),
                if (onOpenRestaurant != null)
                  Icon(
                    Icons.chevron_right,
                    color: context.colors.textSecondary,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xs),
          Row(
            children: [
              if (log.menu.isNotEmpty) ...[
                Flexible(child: Text(log.menu, style: context.text.bodyMedium)),
                const SizedBox(width: Gap.sm),
              ],
              RatingStars(rating: log.rating),
              if (log.fromRecommend) ...[
                const SizedBox(width: Gap.sm),
                Text('✨ 추천', style: context.text.labelSmall),
              ],
            ],
          ),
          if (log.memo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Text('"${log.memo}"', style: context.text.bodySmall),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onEdit, child: const Text('수정')),
              TextButton(onPressed: onDelete, child: const Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }
}
