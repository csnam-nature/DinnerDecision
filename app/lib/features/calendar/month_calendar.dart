import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/dates.dart';
import '../../domain/models/meal_log.dart';

/// 한 달 달력. 기록이 있는 날 아래에 분류 색 점을 찍는다.
///
/// 좌우로 밀거나 화살표를 눌러 달을 바꾼다.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.selectedDay,
    required this.logsByDay,
    required this.onDayTap,
    required this.onMonthChanged,
  });

  /// 보여줄 달. 날짜 부분은 쓰지 않는다.
  final DateTime month;
  final DateTime today;
  final DateTime selectedDay;

  /// 시각을 뗀 날짜 → 그날 기록.
  final Map<DateTime, List<MealLog>> logsByDay;
  final ValueChanged<DateTime> onDayTap;

  /// 바뀐 달의 1일을 넘긴다.
  final ValueChanged<DateTime> onMonthChanged;

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  void _step(int by) => onMonthChanged(DateTime(month.year, month.month + by));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 일요일을 첫 칸으로 둔다. DateTime.weekday는 월=1 … 일=7.
    final leadingBlanks = DateTime(month.year, month.month).weekday % 7;
    final cellCount = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    Color? weekendColor(int column) => switch (column) {
      0 => colors.chinese,
      6 => colors.japanese,
      _ => null,
    };

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 200) _step(velocity > 0 ? -1 : 1);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '이전 달',
                  onPressed: () => _step(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${month.year}년 ${month.month}월',
                    textAlign: TextAlign.center,
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '다음 달',
                  onPressed: () => _step(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                for (final (column, label) in _weekdayLabels.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: context.text.labelSmall?.copyWith(
                          color: weekendColor(column),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            for (var row = 0; row < cellCount ~/ 7; row++)
              Row(
                children: [
                  for (var column = 0; column < 7; column++)
                    Expanded(
                      child: () {
                        final dayNumber = row * 7 + column - leadingBlanks + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox(height: _DayCell.height);
                        }
                        final day = DateTime(
                          month.year,
                          month.month,
                          dayNumber,
                        );
                        return _DayCell(
                          day: day,
                          logs: logsByDay[day] ?? const [],
                          isToday: isSameDate(day, today),
                          isSelected: isSameDate(day, selectedDay),
                          numberColor: weekendColor(column),
                          onTap: () => onDayTap(day),
                        );
                      }(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.logs,
    required this.isToday,
    required this.isSelected,
    required this.numberColor,
    required this.onTap,
  });

  static const double height = 54;

  final DateTime day;
  final List<MealLog> logs;
  final bool isToday;
  final bool isSelected;
  final Color? numberColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = context.scheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: [
        '${day.month}월 ${day.day}일',
        if (isToday) '오늘',
        if (logs.isNotEmpty) '기록 ${logs.length}건',
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: isSelected ? colors.surfaceMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.input),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? scheme.onSurface : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: context.text.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? scheme.surface : numberColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 점은 최대 3개까지만 찍는다.
                    for (final log in logs.take(3))
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: colors.cuisine(log.cuisine),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
