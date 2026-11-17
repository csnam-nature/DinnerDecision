/// 앱의 메뉴 분류 (PLAN.md 4.3).
enum Cuisine {
  korean('한식', '🍚'),
  chinese('중식', '🥟'),
  japanese('일식', '🍣'),
  western('양식', '🍝'),
  etc('기타', '🍽');

  const Cuisine(this.label, this.emoji);

  final String label;
  final String emoji;

  /// 주변 화면 필터에 보이는 분류. '기타'는 전체에서만 보인다.
  static const filterable = [korean, chinese, japanese, western];
}
