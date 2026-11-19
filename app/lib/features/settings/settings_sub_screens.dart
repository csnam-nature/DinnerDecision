import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/cuisine_widgets.dart';
import '../../data/device_files.dart';
import '../../data/local/backup.dart';
import '../../data/local/backup_service.dart';
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
                  subtitle: Text(r.categoryLabel),
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

/// S-63 백업·복원 (F-12).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  var _busy = false;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 예상하지 못한 오류는 내용을 그대로 보여주고 로그에 남긴다. 원인을 알려면 내용이 필요하다.
  Future<void> _fail(String what, Object error, StackTrace stack) async {
    debugPrint('$what: $error\n$stack');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(what),
        content: SingleChildScrollView(
          child: SelectableText('$error', style: context.text.bodySmall),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: '$what\n$error\n$stack')),
            child: const Text('오류 내용 복사'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _explain(String title, String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    try {
      await ref.read(backupServiceProvider).export();
    } on Object catch (e, stack) {
      await _fail('백업 파일을 만들지 못했어요', e, stack);
    }
  });

  Future<void> _restore() => _run(() async {
    final service = ref.read(backupServiceProvider);
    final BackupContents? contents;
    try {
      contents = await service.pick();
    } on BackupException catch (e) {
      if (mounted) _say(e.message);
      return;
    } on BackupPickException catch (e) {
      if (mounted) await _explain('파일을 열 수 없어요', e.message);
      return;
    } on Object catch (e, stack) {
      await _fail('백업 파일을 읽지 못했어요', e, stack);
      return;
    }
    if (contents == null || !mounted) return;

    final current = ref.read(mealLogsProvider).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업에서 복원할까요?'),
        content: Text(
          '지금 기록 $current건을 지우고 백업의 기록 ${contents!.logCount}건으로 바꿔요. '
          '설정과 숨긴 식당도 백업 내용으로 바뀌어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.restore(contents);
      if (mounted) _say('기록 ${contents.logCount}건을 복원했어요');
    } on Object catch (e, stack) {
      await _fail('복원하지 못했어요', e, stack);
    }
  });

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(mealLogsProvider).length;
    final photos = ref.watch(
      mealLogsProvider.select(
        (l) => l.where((e) => e.photoPath != null).length,
      ),
    );
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
                  '휴대폰을 바꾸기 전에 꼭 백업 파일을 만들어 두세요. '
                  '공유 창에서 드라이브에 저장하거나 카카오톡 나에게 보내기로 보관할 수 있어요.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(
            '기록 $count건${photos > 0 ? ' · 사진 $photos장' : ''}',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Gap.lg),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('백업 파일 만들기'),
          ),
          const SizedBox(height: Gap.sm),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.download_outlined),
            label: const Text('백업 파일에서 복원'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(Gap.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
