import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

/// Neutral card that sits on the cream canvas. Soft border + gentle shadow.
/// Pass [onTap] to make the whole card an ink-responding target.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Brand.cardPadding),
    this.radius = Brand.cardRadius,
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final card = Ink(
      decoration: BoxDecoration(
        color: color ?? t.neutralCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.cardBorder),
        boxShadow: onTap == null ? t.shadow : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: t.shadow,
        ),
        child: card,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
