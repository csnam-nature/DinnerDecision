import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../data/api/api_client.dart';
import '../../data/providers.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/sample/sample_data.dart';
import '../../domain/models/app_location.dart';

/// S-12 위치 설정. GPS로 현재 위치를 쓰거나, 주소·장소를 검색해서 고른다 (F-01).
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _query = TextEditingController();
  List<AppLocation>? _results;
  String? _searchError;
  var _searching = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _close() {
    // 온보딩에서 바로 들어온 경우처럼 돌아갈 화면이 없으면 주변 화면으로 간다.
    context.canPop() ? context.pop() : context.go(Routes.nearby);
  }

  void _choose(AppLocation location) {
    ref.read(locationStateProvider.notifier).select(location);
    _close();
  }

  Future<void> _useCurrent() async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref.read(locationStateProvider.notifier).locateMe();
    if (!mounted) return;
    if (failure == null) {
      _close();
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(failure.message),
        action: SnackBarAction(
          label: failure.actionLabel,
          onPressed: () => switch (failure) {
            LocationFailure.serviceOff || LocationFailure.deniedForever =>
              ref.read(locationRepositoryProvider).openSettings(failure),
            LocationFailure.denied ||
            LocationFailure.timeout ||
            LocationFailure.notSet => _useCurrent(),
          },
        ),
      ),
    );
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.length < 2) {
      setState(() => _searchError = '두 글자 이상 입력해 주세요');
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await ref.read(locationRepositoryProvider).search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _results = null;
        _searchError = e.isOffline ? '인터넷 연결을 확인해 주세요' : e.message;
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationStateProvider);
    final current = state.location;
    final sample = ref.watch(usesSampleDataProvider);

    Widget? check(AppLocation location) => location == current
        ? Icon(Icons.check, color: context.scheme.primary, semanticLabel: '선택됨')
        : null;

    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('위치 설정')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.md),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '동, 도로명, 건물·역 이름 검색',
                errorText: _searchError,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(Gap.md),
                        child: SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: '검색',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _search,
                      ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.my_location),
            title: Text(
              state.locating
                  ? '현재 위치 찾는 중…'
                  : current?.source == LocationSource.gps
                  ? '현재 위치 사용 · ${current!.name}'
                  : '현재 위치 사용',
            ),
            subtitle: state.failure != null
                ? Text(state.failure!.message)
                : const Text('GPS로 지금 있는 곳을 찾아요'),
            trailing: current?.source == LocationSource.gps
                ? check(current!)
                : null,
            enabled: !state.locating,
            onTap: _useCurrent,
          ),
          if (results != null) ...[
            const SectionLabel('검색 결과'),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Gap.lg),
                child: Text('찾는 곳이 없어요', style: context.text.bodySmall),
              ),
            for (final location in results)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(location.name),
                subtitle: location.detail.isEmpty
                    ? null
                    : Text(location.detail),
                trailing: check(location),
                onTap: () => _choose(location),
              ),
          ],
          if (current != null &&
              current.source == LocationSource.search &&
              results == null) ...[
            const SectionLabel('지금 위치'),
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(current.name),
              subtitle: current.detail.isEmpty ? null : Text(current.detail),
              trailing: check(current),
            ),
          ],
          if (sample) ...[
            const SectionLabel('예시 위치'),
            for (final location in sampleLocations)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(location.name),
                subtitle: Text(location.detail),
                trailing: check(location),
                onTap: () => _choose(location),
              ),
            Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Text(
                '지금은 예시 데이터라 어느 위치를 골라도 같은 식당이 나와요.',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
