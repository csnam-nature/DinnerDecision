import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/models/restaurant.dart';

enum NearbySort {
  nearest('가까운 순'),
  unvisitedFirst('안 가본 곳 먼저'),
  name('이름순');

  const NearbySort(this.label);

  final String label;
}

/// 주변 화면에서 사용자가 고른 보기 방식.
class NearbyView {
  const NearbyView({
    this.cuisine,
    this.sort = NearbySort.nearest,
    this.hideRecent = false,
    this.mapMode = false,
    this.selectedMapId,
  });

  /// null이면 전체.
  final Cuisine? cuisine;
  final NearbySort sort;

  /// '같은 식당 피하기' 기간 안에 간 곳을 숨길지.
  final bool hideRecent;
  final bool mapMode;

  /// 지도에서 고른 식당.
  final String? selectedMapId;
}

class NearbyViewController extends Notifier<NearbyView> {
  @override
  NearbyView build() => const NearbyView();

  NearbyView _copy({
    Cuisine? Function()? cuisine,
    NearbySort? sort,
    bool? hideRecent,
    bool? mapMode,
    String? Function()? selectedMapId,
  }) {
    return NearbyView(
      cuisine: cuisine == null ? state.cuisine : cuisine(),
      sort: sort ?? state.sort,
      hideRecent: hideRecent ?? state.hideRecent,
      mapMode: mapMode ?? state.mapMode,
      selectedMapId: selectedMapId == null
          ? state.selectedMapId
          : selectedMapId(),
    );
  }

  void setCuisine(Cuisine? cuisine) =>
      state = _copy(cuisine: () => cuisine, selectedMapId: () => null);
  void setSort(NearbySort sort) => state = _copy(sort: sort);
  void setHideRecent(bool value) => state = _copy(hideRecent: value);
  void toggleMap() => state = _copy(mapMode: !state.mapMode);
  void selectOnMap(String? id) => state = _copy(selectedMapId: () => id);
}

final nearbyViewProvider = NotifierProvider<NearbyViewController, NearbyView>(
  NearbyViewController.new,
);

/// 반경 안의 식당에서 숨긴 식당을 뺀 것. 분류 칩의 개수와 지도에 쓴다.
final shownPlacesProvider = Provider<AsyncValue<List<NearbyPlace>>>((ref) {
  final excluded = ref.watch(excludedProvider);
  return ref
      .watch(nearbyPlacesProvider)
      .whenData(
        (all) =>
            all.where((p) => !excluded.containsKey(p.restaurant.id)).toList(),
      );
});

/// 분류 필터만 적용한 것. 지도에 쓴다.
final cuisineFilteredPlacesProvider = Provider<AsyncValue<List<NearbyPlace>>>((
  ref,
) {
  final cuisine = ref.watch(nearbyViewProvider.select((v) => v.cuisine));
  return ref
      .watch(shownPlacesProvider)
      .whenData(
        (all) => cuisine == null
            ? all
            : all.where((p) => p.restaurant.cuisine == cuisine).toList(),
      );
});

/// 목록에 보이는 식당. 분류·최근 방문 숨김·정렬을 모두 적용한다.
final nearbyListProvider = Provider<AsyncValue<List<NearbyPlace>>>((ref) {
  final view = ref.watch(nearbyViewProvider);
  final lastVisit = ref.watch(lastVisitDaysProvider);
  final avoidDays = ref.watch(
    settingsProvider.select((s) => s.avoidRestaurantDays),
  );
  return ref.watch(cuisineFilteredPlacesProvider).whenData((filtered) {
    final list = [
      for (final p in filtered)
        if (!view.hideRecent ||
            (lastVisit[p.restaurant.id] ?? avoidDays + 1) > avoidDays)
          p,
    ];
    switch (view.sort) {
      case NearbySort.nearest:
        break; // 이미 가까운 순이다.
      case NearbySort.unvisitedFirst:
        int rank(NearbyPlace p) =>
            lastVisit.containsKey(p.restaurant.id) ? 1 : 0;
        list.sort((a, b) {
          final byVisit = rank(a).compareTo(rank(b));
          return byVisit != 0 ? byVisit : a.distanceM.compareTo(b.distanceM);
        });
      case NearbySort.name:
        list.sort((a, b) => a.restaurant.name.compareTo(b.restaurant.name));
    }
    return list;
  });
});
