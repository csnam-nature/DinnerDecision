import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../data/providers.dart';
import '../../data/sample/sample_data.dart';
import '../../domain/models/app_location.dart';

/// S-12 위치 직접 설정.
///
/// 지금은 예시 위치 중에서 고른다. GPS와 주소 검색은 3단계에서 붙인다.
class LocationScreen extends ConsumerWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(locationProvider);

    void choose(AppLocation location) {
      ref.read(locationProvider.notifier).select(location);
      // 온보딩에서 바로 들어온 경우처럼 돌아갈 화면이 없으면 주변 화면으로 간다.
      context.canPop() ? context.pop() : context.go(Routes.nearby);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('위치 설정')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.md),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '동, 도로명, 건물 이름 검색 (연결 전)',
              ),
            ),
          ),
          for (final location in sampleLocations)
            ListTile(
              leading: Icon(
                location == sampleLocations.first
                    ? Icons.my_location
                    : Icons.star_outline,
              ),
              title: Text(
                location == sampleLocations.first
                    ? '현재 위치 사용 · ${location.name}'
                    : location.name,
              ),
              subtitle: Text(location.detail),
              trailing: location.name == current.name
                  ? Icon(
                      Icons.check,
                      color: context.scheme.primary,
                      semanticLabel: '선택됨',
                    )
                  : null,
              onTap: () => choose(location),
            ),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Text(
              '지금은 예시 데이터라 어느 위치를 골라도 같은 식당이 나와요.',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
