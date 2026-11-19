enum AppThemeMode {
  system('시스템'),
  light('라이트'),
  dark('다크');

  const AppThemeMode(this.label);

  final String label;
}

/// 사용자가 고를 수 있는 '못 먹는 음식' 태그.
const dislikeTagOptions = ['매운', '회', '고기', '튀김', '구이', '냉면', '국물', '분식', '술집'];

/// 추천과 화면 설정 (PLAN.md 8장 settings).
class AppSettings {
  const AppSettings({
    this.radiusM = 1000,
    this.avoidRestaurantDays = 7,
    this.avoidCuisineStreak = 2,
    this.includeEtc = false,
    this.recommendAnimation = true,
    this.themeMode = AppThemeMode.system,
    this.dislikedTags = const {},
  });

  /// 검색 반경(m).
  final int radiusM;

  /// 이 기간 안에 간 식당은 추천에서 뺀다.
  final int avoidRestaurantDays;

  /// 같은 분류를 이만큼 연속으로 먹었으면 그 분류를 크게 감점한다.
  final int avoidCuisineStreak;

  /// '기타' 분류(아시아음식, 술집 등)도 추천할지.
  final bool includeEtc;
  final bool recommendAnimation;
  final AppThemeMode themeMode;
  final Set<String> dislikedTags;

  AppSettings copyWith({
    int? radiusM,
    int? avoidRestaurantDays,
    int? avoidCuisineStreak,
    bool? includeEtc,
    bool? recommendAnimation,
    AppThemeMode? themeMode,
    Set<String>? dislikedTags,
  }) {
    return AppSettings(
      radiusM: radiusM ?? this.radiusM,
      avoidRestaurantDays: avoidRestaurantDays ?? this.avoidRestaurantDays,
      avoidCuisineStreak: avoidCuisineStreak ?? this.avoidCuisineStreak,
      includeEtc: includeEtc ?? this.includeEtc,
      recommendAnimation: recommendAnimation ?? this.recommendAnimation,
      themeMode: themeMode ?? this.themeMode,
      dislikedTags: dislikedTags ?? this.dislikedTags,
    );
  }
}
