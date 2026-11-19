import 'package:material_ui/material_ui.dart';

import '../../domain/models/cuisine.dart';
import '../theme/app_colors.dart';

/// 분류 아이콘. 분류 색을 옅게 깐 둥근 네모 안에 그림 글자를 넣는다.
class CuisineIcon extends StatelessWidget {
  const CuisineIcon(this.cuisine, {super.key, this.size = 42});

  final Cuisine cuisine;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.cuisine(cuisine).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Text(
          cuisine.emoji,
          style: TextStyle(fontSize: size * 0.5, height: 1.1),
        ),
      ),
    );
  }
}

/// 분류를 고르는 칩. [cuisine]이 null이면 '전체'.
/// 색만으로 구분하지 않도록 그림 글자와 이름을 함께 보여준다.
class CuisineChip extends StatelessWidget {
  const CuisineChip({
    super.key,
    required this.cuisine,
    required this.selected,
    required this.onSelected,
    this.count,
  });

  final Cuisine? cuisine;
  final bool selected;
  final VoidCallback? onSelected;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = cuisine;
    final name = c == null ? '전체' : '${c.emoji} ${c.label}';
    final selectedColor = c == null
        ? context.scheme.onSurface
        : context.colors.cuisine(c);
    final onSelectedColor = c == null ? context.scheme.surface : Colors.white;
    return FilterChip(
      label: Text(count == null ? name : '$name $count'),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
      selectedColor: selectedColor,
      labelStyle: context.text.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? onSelectedColor : context.scheme.onSurface,
      ),
      side: selected ? const BorderSide(color: Colors.transparent) : null,
    );
  }
}
