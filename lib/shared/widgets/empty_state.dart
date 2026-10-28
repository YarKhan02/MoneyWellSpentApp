import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import 'app_card.dart';

/// Reassuring placeholder for a screen or list with nothing to show.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.spa_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: Brand.xxl, horizontal: Brand.xl),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Brand.forest.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Brand.forest),
        ),
        const SizedBox(height: Brand.md),
        Text(
          title,
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Brand.sm),
        Text(
          message,
          style: context.text.bodyMedium?.copyWith(color: Brand.muted),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: Brand.lg), action!],
      ],
    ),
  );
}
