import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/money/money.dart';
import 'amount_text.dart';
import 'app_card.dart';

/// Compact secondary statistic, e.g. spent today / spent this week.
///
/// The label states the period explicitly, so two tiles showing the same
/// figure can never be mistaken for the same measure.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.money,
    this.icon,
    this.iconColor = Brand.forest,
    this.onTap,
  });

  final String label;
  final Money money;
  final IconData? icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(Brand.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: Brand.smallIconSize),
              const SizedBox(width: Brand.sm),
            ],
            Expanded(
              child: Text(
                label,
                style: context.text.labelLarge?.copyWith(color: Brand.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: Brand.sm),
        AmountText(money: money, style: context.text.titleLarge),
      ],
    ),
  );
}
