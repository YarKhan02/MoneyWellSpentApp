import 'package:flutter/material.dart';
import '../../core/design/category_style.dart';
import '../../core/design/tokens.dart';

/// Rounded tinted square holding a category icon.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.iconKey,
    this.colorKey = 'forest',
    this.size = Brand.avatarSize,
    this.onHero = false,
  });
  final String iconKey, colorKey;
  final double size;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final c = categoryColor(colorKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: onHero ? .28 : .16),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(
        categoryIcon(iconKey),
        size: size * .5,
        color: onHero ? Brand.hay : c,
      ),
    );
  }
}
