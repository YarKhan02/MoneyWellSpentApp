import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Icon, headline and one line of detail — one promise on the welcome card.
class FeatureRow extends StatelessWidget {
  const FeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Brand.forest.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Brand.forest),
      ),
      const SizedBox(width: Brand.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text(
              detail,
              style: context.text.bodyMedium?.copyWith(color: Brand.muted),
            ),
          ],
        ),
      ),
    ],
  );
}
