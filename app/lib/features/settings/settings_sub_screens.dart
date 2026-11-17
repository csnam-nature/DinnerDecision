import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../data/providers.dart';
import '../../domain/models/app_settings.dart';

/// S-61 제외한 식당.
class ExcludedScreen extends ConsumerWidget {
  const ExcludedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excluded = ref.watch(excludedProvider).values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('제외한 식당')),
      body: excluded.isEmpty
          ? const StateView(
              emoji: '🙈',
              title: '숨긴 식당이 없어요',
              message: '주변 목록에서 줄을 왼쪽으로 밀거나, 식당 상세 오른쪽 위 버튼으로 숨길 수 있어요',
            )
          : ListView.separated(
              itemCount: excluded.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final r = excluded[index];
                return ListTile(
                  leading: CuisineIcon(r.cuisine, size: 36),
                  title: Text(r.name),
                  subtitle: Text('${r.cuisine.label} · ${r.subCategory}'),
                  trailing: OutlinedButton(
                    onPressed: () =>
                        ref.read(excludedProvider.notifier).restore(r.id),
                    child: const Text('다시 보기'),
                  ),
                );
              },
            ),
    );
  }
}

/// S-62 못 먹는 음식.
class DislikesScreen extends ConsumerWidget {
  const DislikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disliked = ref.watch(settingsProvider.select((s) => s.dislikedTags));
    return Scaffold(
      appBar: AppBar(title: const Text('못 먹는 음식')),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          Text(
            '고른 음식이 들어간 식당은 추천에서 빠져요. 주변 목록에는 그대로 보여요.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Gap.lg),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final tag in dislikeTagOptions)
                FilterChip(
                  label: Text(tag),
                  selected: disliked.contains(tag),
                  showCheckmark: true,
                  onSelected: (_) =>
                      ref.read(settingsProvider.notifier).toggleDislike(tag),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// S-63 백업·복원. 파일 만들기와 복원은 4단계에서 붙인다.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(mealLogsProvider).length;
    return Scaffold(
      appBar: AppBar(title: const Text('백업·복원')),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(Gap.lg),
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('기록은 이 휴대폰에만 저장돼요', style: context.text.titleMedium),
                const SizedBox(height: Gap.xs),
                Text(
                  '휴대폰을 바꾸기 전에 꼭 백업 파일을 만들어 두세요.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text('기록 $count건 · 아직 백업한 적이 없어요', style: context.text.bodySmall),
          const SizedBox(height: Gap.lg),
          FilledButton.icon(
            onPressed: () => showNotReady(context, '백업 파일 만들기는 아직 연결 전이에요'),
            icon: const Icon(Icons.upload_outlined),
            label: const Text('백업 파일 만들기'),
          ),
          const SizedBox(height: Gap.sm),
          OutlinedButton.icon(
            onPressed: () => showNotReady(context, '백업 파일에서 복원은 아직 연결 전이에요'),
            icon: const Icon(Icons.download_outlined),
            label: const Text('백업 파일에서 복원'),
          ),
        ],
      ),
    );
  }
}
