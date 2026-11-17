import 'package:material_ui/material_ui.dart';

import '../../domain/models/cuisine.dart';

/// Material 색상표에 없는 앱 전용 색 (UI_PLAN.md 2.1).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.primarySoft,
    required this.textSecondary,
    required this.surfaceMuted,
    required this.line,
    required this.star,
    required this.korean,
    required this.chinese,
    required this.japanese,
    required this.western,
    required this.etc,
    required this.mapBackground,
    required this.mapRoad,
    required this.mapMe,
  });

  /// 브랜드 주황. 흰 글자를 올리는 버튼에는 대비가 부족해서 쓰지 않고, 아이콘·강조에만 쓴다.
  final Color brand;

  /// 추천 이유 상자 같은 옅은 주황 배경.
  final Color primarySoft;
  final Color textSecondary;
  final Color surfaceMuted;
  final Color line;
  final Color star;
  final Color korean;
  final Color chinese;
  final Color japanese;
  final Color western;
  final Color etc;
  final Color mapBackground;
  final Color mapRoad;
  final Color mapMe;

  /// 분류 색. 칩, 지도 마커, 달력 점에 함께 쓴다.
  Color cuisine(Cuisine c) => switch (c) {
    Cuisine.korean => korean,
    Cuisine.chinese => chinese,
    Cuisine.japanese => japanese,
    Cuisine.western => western,
    Cuisine.etc => etc,
  };

  static const light = AppColors(
    brand: Color(0xFFFF6B35),
    primarySoft: Color(0xFFFFF0EA),
    textSecondary: Color(0xFF6C757D),
    surfaceMuted: Color(0xFFF8F9FA),
    line: Color(0xFFE9ECEF),
    star: Color(0xFFF08C00),
    korean: Color(0xFFF08C00),
    chinese: Color(0xFFE03131),
    japanese: Color(0xFF1C7ED6),
    western: Color(0xFF2B8A3E),
    etc: Color(0xFF868E96),
    mapBackground: Color(0xFFEEF1EC),
    mapRoad: Color(0xFFFFFFFF),
    mapMe: Color(0xFF1C7ED6),
  );

  static const dark = AppColors(
    brand: Color(0xFFFF8A5C),
    primarySoft: Color(0xFF3A2219),
    textSecondary: Color(0xFFADB5BD),
    surfaceMuted: Color(0xFF1E1E1E),
    line: Color(0xFF2C2C2C),
    star: Color(0xFFFFA94D),
    korean: Color(0xFFFFA94D),
    chinese: Color(0xFFFF6B6B),
    japanese: Color(0xFF4DABF7),
    western: Color(0xFF51CF66),
    etc: Color(0xFFADB5BD),
    mapBackground: Color(0xFF1B1F23),
    mapRoad: Color(0xFF2C3238),
    mapMe: Color(0xFF4DABF7),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brand: mix(brand, other.brand),
      primarySoft: mix(primarySoft, other.primarySoft),
      textSecondary: mix(textSecondary, other.textSecondary),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      line: mix(line, other.line),
      star: mix(star, other.star),
      korean: mix(korean, other.korean),
      chinese: mix(chinese, other.chinese),
      japanese: mix(japanese, other.japanese),
      western: mix(western, other.western),
      etc: mix(etc, other.etc),
      mapBackground: mix(mapBackground, other.mapBackground),
      mapRoad: mix(mapRoad, other.mapRoad),
      mapMe: mix(mapMe, other.mapMe),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}
