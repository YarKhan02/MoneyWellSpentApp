import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../shared/widgets/widgets.dart';

/// Restrained summary of what the current filter is showing: how many
/// entries, and their total.
///
/// Deliberately a neutral card rather than a dark hero — the page's job is
/// the list, and only one surface per screen should shout.
class ActivitySummary extends StatelessWidget {
  const ActivitySummary({super.key, required this.count, required this.total});
  final int count;
  final Money total;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(
      horizontal: Brand.lg,
      vertical: Brand.md,
    ),
    child: ResponsivePair(
      gap: Brand.sm,
      minChildWidth: 120,
      first: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count ${count == 1 ? 'expense' : 'expenses'}',
          style: context.text.bodyMedium?.copyWith(color: Brand.muted),
        ),
      ),
      second: Align(
        alignment: Alignment.centerRight,
        child: AmountText(
          money: total,
          style: context.text.titleLarge,
          textAlign: TextAlign.end,
        ),
      ),
    ),
  );
}
