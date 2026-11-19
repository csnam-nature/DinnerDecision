import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/recommend/recommendation.dart';

enum RecommendPhase { idle, picking, result }

class RecommendState {
  const RecommendState({
    this.phase = RecommendPhase.idle,
    this.lockCuisine,
    this.skippedIds = const {},
    this.result,
    this.bigIndex = 0,
    this.failed = false,
  });

  final RecommendPhase phase;

  /// "오늘은 한식 중에서"처럼 분류를 고정했을 때. null이면 상관없음.
  final Cuisine? lockCuisine;

  /// '다른 추천'으로 넘긴 식당. 다시 나오지 않는다.
  final Set<String> skippedIds;
  final RecommendResult? result;

  /// 큰 카드로 보여줄 추천의 순서.
  final int bigIndex;

  /// 주변 식당이나 날씨를 불러오지 못했을 때.
  final bool failed;

  Recommendation? get big {
    final picks = result?.picks ?? const <Recommendation>[];
    return picks.isEmpty ? null : picks[bigIndex.clamp(0, picks.length - 1)];
  }
}

class RecommendController extends Notifier<RecommendState> {
  var _run = 0;

  @override
  RecommendState build() {
    // 추천에 영향을 주는 값이 바뀌면 이전 결과는 버리고 처음 화면으로 돌아간다.
    ref
      ..watch(locationProvider)
      ..watch(sampleWeatherProvider)
      ..watch(mealLogsProvider)
      ..watch(excludedProvider)
      ..watch(
        settingsProvider.select(
          (s) => (
            s.radiusM,
            s.avoidRestaurantDays,
            s.avoidCuisineStreak,
            s.includeEtc,
            s.dislikedTags,
          ),
        ),
      );
    _run++;
    return const RecommendState();
  }

  void setLock(Cuisine? cuisine) =>
      state = RecommendState(lockCuisine: cuisine);

  void showBig(int index) => state = RecommendState(
    phase: state.phase,
    lockCuisine: state.lockCuisine,
    skippedIds: state.skippedIds,
    result: state.result,
    bigIndex: index,
  );

  void reset() => state = RecommendState(lockCuisine: state.lockCuisine);

  /// 지금 보인 곳들은 빼고 다시 추천한다.
  Future<void> again({required bool animate}) {
    final shown = {
      for (final pick in state.result?.picks ?? const <Recommendation>[])
        pick.place.restaurant.id,
    };
    return start(animate: animate, skip: {...state.skippedIds, ...shown});
  }

  /// [animate]가 true면 고르는 연출을 잠깐 보여준다.
  Future<void> start({required bool animate, Set<String>? skip}) async {
    final run = ++_run;
    final lock = state.lockCuisine;
    final skipped = skip ?? state.skippedIds;
    state = RecommendState(
      phase: RecommendPhase.picking,
      lockCuisine: lock,
      skippedIds: skipped,
    );
    try {
      final places = await ref.read(nearbyPlacesProvider.future);
      final weather = await ref.read(weatherProvider.future);
      if (animate) {
        await Future<void>.delayed(const Duration(milliseconds: 850));
      }
      // 기다리는 사이에 설정이 바뀌었거나 다시 눌렀으면 이 결과는 버린다.
      if (!ref.mounted || run != _run) return;
      final result = ref
          .read(recommendEngineProvider)
          .recommend(
            places: places,
            logs: ref.read(mealLogsProvider),
            weather: weather,
            settings: ref.read(settingsProvider),
            today: ref.read(clockProvider)(),
            excludedIds: ref.read(excludedProvider).keys.toSet(),
            skippedIds: skipped,
            lockCuisine: lock,
          );
      state = RecommendState(
        phase: RecommendPhase.result,
        lockCuisine: lock,
        skippedIds: skipped,
        result: result,
      );
    } on Exception {
      if (!ref.mounted || run != _run) return;
      state = RecommendState(
        lockCuisine: lock,
        skippedIds: skipped,
        failed: true,
      );
    }
  }
}

final recommendProvider = NotifierProvider<RecommendController, RecommendState>(
  RecommendController.new,
);
