import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../core/dates.dart';
import '../../core/geo.dart';
import '../../data/device_files.dart';
import '../../data/providers.dart';
import '../../domain/models/cuisine.dart';
import '../../domain/models/meal_log.dart';
import '../../domain/models/restaurant.dart';
import '../calendar/calendar_controller.dart';
import 'meal_log_draft.dart';

/// 메뉴 추천 단어로 쓰기엔 너무 넓은 태그.
const _broadTags = {'국물', '냉', '구이', '매운', '회', '고기', '튀김', '술집', '탕', '분식'};

/// S-50 기록 입력·수정. 꼭 넣어야 하는 것은 날짜, 식당, 분류뿐이다.
class MealLogEditScreen extends ConsumerStatefulWidget {
  const MealLogEditScreen({super.key, this.initial});

  final MealLogDraft? initial;

  @override
  ConsumerState<MealLogEditScreen> createState() => _MealLogEditScreenState();
}

class _MealLogEditScreenState extends ConsumerState<MealLogEditScreen> {
  late final MealLogDraft _draft =
      widget.initial ?? MealLogDraft.blank(dateOnly(ref.read(clockProvider)()));
  late DateTime _date = _draft.date;
  late MealType _mealType = _draft.mealType;
  late Restaurant? _restaurant = _draft.restaurant;
  late String? _restaurantId = _draft.restaurantId;
  late Cuisine? _cuisine = _draft.cuisine;
  late int _rating = _draft.rating;
  late String? _photo = _draft.photoPath;
  var _addingPhoto = false;
  late final _name = TextEditingController(text: _draft.restaurantName);
  late final _menu = TextEditingController(text: _draft.menu);
  late final _memo = TextEditingController(text: _draft.memo);
  String? _error;

  bool get _isEdit => _draft.id != null;

  /// 식당을 골랐거나 집밥으로 정해서 이름 칸을 잠근 상태.
  bool get _nameLocked => _restaurantId != null || _name.text == homeMealName;

  @override
  void dispose() {
    _name.dispose();
    _menu.dispose();
    _memo.dispose();
    super.dispose();
  }

  String get _weatherText => _draft.weatherText.isNotEmpty
      ? _draft.weatherText
      : ref.watch(weatherProvider).value?.summary ?? '';

  Future<void> _pickDate() async {
    final today = dateOnly(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _pickRestaurant(Restaurant r) {
    setState(() {
      _restaurant = r;
      _restaurantId = r.id;
      _cuisine = r.cuisine;
      _name.text = r.name;
    });
  }

  void _clearRestaurant() {
    setState(() {
      _restaurant = null;
      _restaurantId = null;
      _name.clear();
    });
  }

  void _save() {
    final name = _name.text.trim();
    final cuisine = _cuisine;
    if (name.isEmpty || cuisine == null) {
      setState(() => _error = '식당과 분류는 꼭 입력해 주세요');
      return;
    }
    final logs = ref.read(mealLogsProvider.notifier);
    logs.save(
      MealLog(
        id: _draft.id ?? logs.newId(),
        date: _date,
        mealType: _mealType,
        restaurantId: _restaurantId,
        restaurantName: name,
        cuisine: cuisine,
        menu: _menu.text.trim(),
        rating: _rating,
        memo: _memo.text.trim(),
        photoPath: _photo,
        weatherText: _weatherText,
        fromRecommend: _draft.fromRecommend,
      ),
      restaurant: _restaurant,
    );
    // 저장한 날을 달력에서 바로 볼 수 있게 한다.
    ref.read(calendarViewProvider.notifier).showDay(_date);
    final messenger = ScaffoldMessenger.of(context);
    context.go(Routes.calendar);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(_isEdit ? '기록을 고쳤어요' : '기록했어요. 달력에 점이 생겼어요')),
      );
  }

  Future<void> _addPhoto() async {
    final store = ref.read(photoStoreProvider);
    if (store == null) return;
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('사진 찍기'),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 고르기'),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _addingPhoto = true);
    try {
      final picked = await ref.read(deviceFilesProvider).pickPhoto(source);
      if (picked == null) return;
      final name = await store.add(picked);
      if (mounted) setState(() => _photo = name);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text('사진을 가져오지 못했어요')));
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant;
    final photoStore = ref.watch(photoStoreProvider);
    final photo = _photo;
    final menuWords = restaurant == null
        ? const <String>[]
        : {
            restaurant.subCategory,
            ...restaurant.tags.where((t) => !_broadTags.contains(t)),
          }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '기록 수정' : '식사 기록'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: TextButton(onPressed: _save, child: const Text('저장')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        children: [
          if (_draft.fromRecommend && !_isEdit)
            Container(
              margin: const EdgeInsets.only(top: Gap.xs),
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: context.colors.primarySoft,
                borderRadius: BorderRadius.circular(Radii.input),
              ),
              child: Text(
                '추천에서 결정한 식당이라 미리 채워 두었어요. 별점만 남겨 주세요.',
                style: context.text.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),
          _Field(
            label: '날짜',
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 20),
                label: Text(formatFullDate(_date)),
              ),
            ),
          ),
          _Field(
            label: '식사',
            child: SegmentedButton<MealType>(
              showSelectedIcon: false,
              segments: [
                for (final m in MealType.values)
                  ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {_mealType},
              onSelectionChanged: (s) => setState(() => _mealType = s.first),
            ),
          ),
          _Field(
            label: '식당',
            child: _nameLocked
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      avatar: restaurant == null
                          ? null
                          : Text(restaurant.cuisine.emoji),
                      label: Text(_name.text),
                      onDeleted: _clearRestaurant,
                      deleteButtonTooltipMessage: '식당 지우기',
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _name,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '식당 이름 검색 또는 직접 입력',
                        ),
                      ),
                      _RestaurantSuggestions(
                        query: _name.text,
                        onPick: _pickRestaurant,
                      ),
                      const SizedBox(height: Gap.sm),
                      ActionChip(
                        label: const Text('🏠 $homeMealName'),
                        onPressed: () =>
                            setState(() => _name.text = homeMealName),
                      ),
                    ],
                  ),
          ),
          _Field(
            label: '분류',
            child: Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.xs,
              children: [
                for (final c in Cuisine.values)
                  CuisineChip(
                    cuisine: c,
                    selected: _cuisine == c,
                    onSelected: () => setState(() => _cuisine = c),
                  ),
              ],
            ),
          ),
          _Field(
            label: '메뉴',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _menu,
                  decoration: const InputDecoration(hintText: '예: 순대국'),
                ),
                if (menuWords.isNotEmpty) ...[
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: Gap.sm,
                    children: [
                      for (final word in menuWords)
                        ActionChip(
                          label: Text(word),
                          onPressed: () => setState(() => _menu.text = word),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _Field(
            label: '별점',
            child: Align(
              alignment: Alignment.centerLeft,
              child: RatingStars(
                rating: _rating,
                size: 34,
                onChanged: (v) => setState(() => _rating = v),
              ),
            ),
          ),
          _Field(
            label: '메모',
            child: TextField(
              controller: _memo,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: '맛, 양, 다시 갈지…'),
            ),
          ),
          if (photoStore != null)
            _Field(
              label: '사진',
              child: Align(
                alignment: Alignment.centerLeft,
                child: photo != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.card),
                            child: Image.file(
                              photoStore.file(photo),
                              height: 160,
                              fit: BoxFit.cover,
                              semanticLabel: '기록 사진',
                              errorBuilder: (_, _, _) => const SizedBox(
                                height: 60,
                                child: Center(child: Text('사진을 찾을 수 없어요')),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton.filledTonal(
                              tooltip: '사진 빼기',
                              onPressed: () => setState(() => _photo = null),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: _addingPhoto ? null : _addPhoto,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                        label: Text(_addingPhoto ? '가져오는 중…' : '사진 추가'),
                      ),
              ),
            ),
          _Field(
            label: '날씨',
            divider: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _weatherText.isEmpty ? '날씨를 확인하는 중…' : '$_weatherText (자동)',
                style: context.text.bodyMedium,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Gap.sm),
              child: Text(
                _error!,
                style: context.text.titleSmall?.copyWith(
                  color: context.scheme.error,
                ),
              ),
            ),
          const SizedBox(height: Gap.xl),
        ],
      ),
      bottomNavigationBar: PrimaryBottomButton(label: '저장', onPressed: _save),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, this.divider = true});

  final String label;
  final Widget child;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      decoration: divider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.line)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 입력한 글자가 이름에 들어간 주변 식당을 최대 5곳 보여준다.
class _RestaurantSuggestions extends ConsumerWidget {
  const _RestaurantSuggestions({required this.query, required this.onPick});

  final String query;
  final ValueChanged<Restaurant> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = query.trim();
    if (q.isEmpty) return const SizedBox.shrink();
    final matches =
        (ref.watch(nearbyPlacesProvider).value ?? const <NearbyPlace>[])
            .where((p) => p.restaurant.name.contains(q))
            .take(5)
            .toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Gap.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final p in matches)
              ListTile(
                dense: true,
                leading: CuisineIcon(p.restaurant.cuisine, size: 30),
                title: Text(p.restaurant.name, style: context.text.bodyMedium),
                trailing: Text(
                  formatDistance(p.distanceM),
                  style: context.text.bodySmall,
                ),
                onTap: () => onPick(p.restaurant),
              ),
          ],
        ),
      ),
    );
  }
}
