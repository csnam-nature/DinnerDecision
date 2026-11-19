import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

const _fontFamily = 'Pretendard';

/// 앱 테마 (UI_PLAN.md 2장).
ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = dark ? AppColors.dark : AppColors.light;

  final background = dark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  final onBackground = dark ? const Color(0xFFF1F3F5) : const Color(0xFF212529);
  // 흰 글자를 올려도 읽히도록 라이트 모드의 버튼 색은 브랜드 주황보다 조금 진하게 쓴다.
  final primary = dark ? const Color(0xFFFF8A5C) : const Color(0xFFE0581F);
  final onPrimary = dark ? const Color(0xFF1A0F0A) : const Color(0xFFFFFFFF);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.brand,
        brightness: brightness,
      ).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        secondaryContainer: colors.primarySoft,
        onSecondaryContainer: onBackground,
        surface: background,
        onSurface: onBackground,
        onSurfaceVariant: colors.textSecondary,
        surfaceContainerLowest: background,
        surfaceContainerLow: colors.surfaceMuted,
        surfaceContainer: colors.surfaceMuted,
        surfaceContainerHigh: colors.surfaceMuted,
        surfaceContainerHighest: dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFEEF0F2),
        outline: dark ? const Color(0xFF5C5F66) : const Color(0xFFADB5BD),
        outlineVariant: colors.line,
        error: dark ? const Color(0xFFFF6B6B) : const Color(0xFFE03131),
        onError: dark ? const Color(0xFF1A0F0A) : const Color(0xFFFFFFFF),
        surfaceTint: Colors.transparent,
      );

  TextStyle style(
    double size,
    FontWeight weight, {
    double? height,
    Color? color,
  }) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color ?? onBackground,
    letterSpacing: 0,
  );

  // 이름 붙인 네 가지(Display 28 / Title 20 / Body 16 / Caption 13)를 중심으로 쓴다.
  final textTheme = TextTheme(
    headlineMedium: style(28, FontWeight.w700, height: 1.25),
    headlineSmall: style(24, FontWeight.w700, height: 1.3),
    titleLarge: style(20, FontWeight.w600, height: 1.3),
    titleMedium: style(16, FontWeight.w700, height: 1.35),
    titleSmall: style(14, FontWeight.w600, height: 1.4),
    bodyLarge: style(16, FontWeight.w400, height: 1.5),
    bodyMedium: style(14, FontWeight.w400, height: 1.5),
    bodySmall: style(
      13,
      FontWeight.w400,
      height: 1.45,
      color: colors.textSecondary,
    ),
    labelLarge: style(16, FontWeight.w700),
    labelMedium: style(13, FontWeight.w600),
    labelSmall: style(12, FontWeight.w500, color: colors.textSecondary),
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.button),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: background,
    extensions: [colors],
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: buttonShape,
        foregroundColor: onBackground,
        backgroundColor: colors.surfaceMuted,
        side: BorderSide(color: colors.line),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: onBackground,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.titleSmall,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      extendedTextStyle: textTheme.labelLarge?.copyWith(fontSize: 17),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: colors.line),
      backgroundColor: background,
      labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 6),
      showCheckmark: false,
    ),
    cardTheme: CardThemeData(
      color: background,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: colors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.md,
        vertical: Gap.md,
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.input),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.input),
        borderSide: BorderSide(color: colors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      indicatorColor: colors.primarySoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected)
              ? onBackground
              : colors.textSecondary,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.button),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      minVerticalPadding: Gap.md,
      titleTextStyle: textTheme.bodyLarge,
      subtitleTextStyle: textTheme.bodySmall,
    ),
  );
}
