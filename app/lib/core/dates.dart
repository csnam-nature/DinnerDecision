/// 시각을 뗀 날짜.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// [from]부터 [to]까지 지난 날 수. 시각은 무시한다.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

String weekdayKo(DateTime d) => _weekdays[d.weekday - 1];

/// 예: 11/7 (금)
String formatMonthDay(DateTime d) => '${d.month}/${d.day} (${weekdayKo(d)})';

/// 예: 11월 7일 (금)
String formatMonthDayLong(DateTime d) =>
    '${d.month}월 ${d.day}일 (${weekdayKo(d)})';

/// 예: 2026-11-07 (금)
String formatFullDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} (${weekdayKo(d)})';

/// 예: 오늘, 어제, 그제, 5일 전
String relativeDay(int daysAgo) => switch (daysAgo) {
  0 => '오늘',
  1 => '어제',
  2 => '그제',
  _ => '$daysAgo일 전',
};
