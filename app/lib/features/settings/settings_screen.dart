import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../data/api/api_client.dart';
import '../../data/providers.dart';
import '../../data/sample/sample_data.dart';
import '../../domain/models/app_settings.dart';

/// S-60 설정. 바꾼 값은 주변 목록과 추천에 바로 반영된다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final excludedCount = ref.watch(excludedProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const SectionLabel('추천'),
          _ChoiceTile<int>(
            title: '검색 반경',
            value: settings.radiusM,
            options: const {500: '500m', 1000: '1km', 2000: '2km'},
            onChanged: (v) => controller.update((s) => s.copyWith(radiusM: v)),
          ),
          _ChoiceTile<int>(
            title: '같은 식당 피하기',
            value: settings.avoidRestaurantDays,
            options: const {3: '3일', 7: '7일', 14: '14일'},
            onChanged: (v) =>
                controller.update((s) => s.copyWith(avoidRestaurantDays: v)),
          ),
          _ChoiceTile<int>(
            title: '같은 분류 연속 피하기',
            value: settings.avoidCuisineStreak,
            options: const {2: '2번', 3: '3번'},
            onChanged: (v) =>
                controller.update((s) => s.copyWith(avoidCuisineStreak: v)),
          ),
          _LinkTile(
            title: '못 먹는 음식',
            value: settings.dislikedTags.isEmpty
                ? null
                : '${settings.dislikedTags.length}개',
            onTap: () => context.push(Routes.dislikes),
          ),
          _LinkTile(
            title: '제외한 식당',
            value: excludedCount == 0 ? null : '$excludedCount곳',
            onTap: () => context.push(Routes.excluded),
          ),
          SwitchListTile(
            title: const Text("'기타' 분류도 추천"),
            subtitle: const Text('아시아음식, 술집 등'),
            value: settings.includeEtc,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(includeEtc: v)),
          ),
          SwitchListTile(
            title: const Text('추천 애니메이션'),
            value: settings.recommendAnimation,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(recommendAnimation: v)),
          ),
          const Divider(),
          const SectionLabel('위치'),
          _LinkTile(
            title: '위치 바꾸기',
            onTap: () => context.push(Routes.location),
          ),
          const Divider(),
          const SectionLabel('데이터'),
          _LinkTile(title: '백업·복원', onTap: () => context.push(Routes.backup)),
          const Divider(),
          const SectionLabel('화면'),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.sm,
            ),
            child: Row(
              children: [
                Expanded(child: Text('테마', style: context.text.bodyLarge)),
                SegmentedButton<AppThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    for (final mode in AppThemeMode.values)
                      ButtonSegment(value: mode, label: Text(mode.label)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => controller.update(
                    (current) => current.copyWith(themeMode: s.first),
                  ),
                ),
              ],
            ),
          ),
          if (kDebugMode) ...[
            const Divider(),
            const SectionLabel('개발용 (출시 빌드에는 보이지 않음)'),
            _ChoiceTile<SampleWeather?>(
              title: '예시 날씨',
              value: ref.watch(sampleWeatherProvider),
              options: {
                if (!ref.watch(usesSampleDataProvider)) null: '실제 날씨',
                for (final w in SampleWeather.values) w: w.label,
              },
              onChanged: ref.read(sampleWeatherProvider.notifier).select,
            ),
            _LinkTile(
              title: '온보딩 다시 보기',
              onTap: () => context.push(Routes.onboarding),
            ),
            if (ref.watch(firebaseEnabledProvider))
              _LinkTile(
                title: 'Crashlytics 시험 오류 보내기',
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(errorReporterProvider).sendTestReport();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('기록했어요. 앱을 완전히 껐다 켜면 보내져요 (콘솔에 몇 분 걸림)'),
                    ),
                  );
                },
              )
            else
              const ListTile(
                title: Text('Firebase 꺼짐'),
                subtitle: Text('Firebase를 시작하지 못해 오류 수집·앱 인증 없이 실행 중'),
              ),
          ],
          const Divider(),
          const SectionLabel('정보'),
          _LinkTile(
            title: '개인정보처리방침',
            onTap: () async {
              // 서버의 공개 페이지 (스토어에 적는 주소와 같음)
              if (apiBaseUrl.isEmpty) {
                showNotReady(context, '서버 주소 없이 실행 중이라 열 수 없어요');
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              final opened = await ref
                  .read(externalLauncherProvider)
                  .open(Uri.parse('$apiBaseUrl/privacy'));
              if (!opened) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('열 수 있는 앱이 없어요')),
                );
              }
            },
          ),
          _LinkTile(
            title: '오픈소스 라이선스',
            onTap: () => showLicensePage(
              context: context,
              applicationName: '오늘 저녁 뭐 먹지',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Text(
              '데이터 출처: 카카오(장소), 네이버 지도(지도), 기상청(날씨)\n'
              '${ref.watch(usesSampleDataProvider) ? '지금은 예시 데이터로 동작해요 · ' : ''}버전 1.0.0',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 몇 가지 값 중에서 하나를 고르는 줄.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        style: context.text.titleSmall,
        onChanged: (v) => onChanged(v as T),
        items: [
          for (final entry in options.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
      ),
    );
  }
}

/// 다른 화면으로 들어가는 줄.
class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.onTap, this.value});

  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value!, style: context.text.bodySmall),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}
