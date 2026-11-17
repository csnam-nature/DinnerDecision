import 'package:material_ui/material_ui.dart';

import '../../domain/recommend/recommendation.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// 별점. [onChanged]가 있으면 눌러서 고칠 수 있다. 같은 별을 다시 누르면 0점.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 16,
  });

  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final on = context.colors.star;
    final off = context.colors.line;
    if (onChanged == null) {
      return Semantics(
        label: '별점 $rating점',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: i <= rating ? on : context.colors.textSecondary,
                ),
            ],
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i점',
            isSelected: i <= rating,
            onPressed: () => onChanged!(rating == i ? 0 : i),
            iconSize: size,
            icon: Icon(Icons.star_rounded, color: i <= rating ? on : off),
          ),
      ],
    );
  }
}

/// 추천 이유 한 줄.
class ReasonRow extends StatelessWidget {
  const ReasonRow(this.reason, {super.key});

  final Reason reason;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(reason.emoji, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: Gap.sm),
        Expanded(
          child: Text(
            reason.text,
            style: context.text.bodyMedium?.copyWith(fontSize: 14.5),
          ),
        ),
      ],
    );
  }
}

/// 화면 아래에 붙는 큰 버튼.
class PrimaryBottomButton extends StatelessWidget {
  const PrimaryBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.lg),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}

/// 목록이 비었거나 오류가 났을 때 가운데에 보여주는 안내.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.emoji,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: Gap.md),
            Text(
              title,
              style: context.text.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: Gap.xs),
              Text(
                message!,
                style: context.text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: Gap.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 불러오는 동안 보여주는 회색 줄.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final color = context.scheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Semantics(
      label: '불러오는 중',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(42, 42),
              const SizedBox(width: Gap.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(150, 14),
                  const SizedBox(height: Gap.sm),
                  bar(90, 11),
                  const SizedBox(height: Gap.sm),
                  bar(190, 11),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 설정 화면 같은 곳의 작은 구역 제목.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xs),
      child: Text(
        text,
        style: context.text.labelMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// 아직 연결하지 않은 기능을 눌렀을 때 알려준다.
void showNotReady(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// 되돌리기 버튼이 있는 알림.
void showUndo(
  ScaffoldMessengerState messenger,
  String message,
  VoidCallback onUndo,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: '되돌리기', onPressed: onUndo),
      ),
    );
}
