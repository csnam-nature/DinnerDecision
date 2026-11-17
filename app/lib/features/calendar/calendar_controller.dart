import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../data/providers.dart';

class CalendarView {
  const CalendarView({
    required this.focusedDay,
    required this.selectedDay,
    this.listMode = false,
    this.query = '',
  });

  /// 달력에 보이는 달.
  final DateTime focusedDay;
  final DateTime selectedDay;

  /// true면 달력 대신 기록 목록을 보여준다.
  final bool listMode;

  /// 목록 보기의 검색어.
  final String query;

  CalendarView copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    bool? listMode,
    String? query,
  }) {
    return CalendarView(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      listMode: listMode ?? this.listMode,
      query: query ?? this.query,
    );
  }
}

class CalendarViewController extends Notifier<CalendarView> {
  @override
  CalendarView build() {
    final today = dateOnly(ref.watch(clockProvider)());
    return CalendarView(focusedDay: today, selectedDay: today);
  }

  void setFocusedMonth(DateTime day) => state = state.copyWith(focusedDay: day);
  void setListMode(bool value) => state = state.copyWith(listMode: value);
  void setQuery(String value) => state = state.copyWith(query: value);

  /// 그 날을 고르고, 그 날이 있는 달을 달력으로 보여준다.
  void showDay(DateTime day) {
    final date = dateOnly(day);
    state = state.copyWith(
      focusedDay: date,
      selectedDay: date,
      listMode: false,
    );
  }
}

final calendarViewProvider =
    NotifierProvider<CalendarViewController, CalendarView>(
      CalendarViewController.new,
    );
