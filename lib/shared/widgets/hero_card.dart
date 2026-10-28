import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

/// Deep Tilled-Earth surface for prominent financial summaries.
/// Supplies the on-hero text and icon colours to everything beneath it.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(Brand.heroPadding),
    decoration: BoxDecoration(
      color: context.tokens.hero,
      borderRadius: BorderRadius.circular(Brand.heroRadius),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: context.tokens.onHero),
      child: IconTheme.merge(
        data: IconThemeData(color: context.tokens.onHero),
        child: child,
      ),
    ),
  );
}
