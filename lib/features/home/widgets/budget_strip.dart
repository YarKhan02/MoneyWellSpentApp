import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/money/money_display.dart';
import '../../../shared/widgets/widgets.dart';
import '../../ledger/budget_status.dart';

/// Compact weekly-budget summary for the home hero: one label row, a slim
/// progress bar, and the full spent-of-limit relationship underneath.
///
/// Replaces the two nested cards that used to sit here. The relationship
/// text is allowed to wrap onto a second line — it is never truncated, so a
/// long amount can no longer read as `PKR 1,250.00 / …`.
class BudgetStrip extends StatelessWidget {
  const BudgetStrip({super.key, required this.status});
  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A Wrap, not a Row: "Over by PKR 1,250.00" beside "Weekly budget"
        // does not fit on a narrow phone or at large text, and the two move
        // onto separate lines rather than overflowing.
        Wrap(
          spacing: Brand.sm,
          runSpacing: Brand.xs,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Weekly budget',
              style: context.text.labelLarge?.copyWith(color: Brand.hay),
            ),
            // Status is carried by words, not only by the bar's colour.
            Text(
              status.over
                  ? 'Over by ${status.remainingMoney.display}'
                  : '${status.remainingMoney.display} left',
              style: context.text.labelLarge?.copyWith(
                color: status.over ? Brand.cherry : Brand.wheat,
              ),
            ),
          ],
        ),
        const SizedBox(height: Brand.sm),
        ProgressBar(
          percent: status.percentUsed,
          color: status.over ? Brand.cherry : Brand.wheat,
          track: Colors.white.withValues(alpha: .16),
          label: 'Weekly budget used',
        ),
        const SizedBox(height: Brand.sm),
        Text(
          '${status.spentMoney.display} of ${status.capMoney!.display} this week',
          style: context.text.bodyMedium?.copyWith(color: t.onHeroMuted),
        ),
      ],
    );
  }
}

/// Shown in place of [BudgetStrip] before any weekly cap is set.
class SetupBudgetPrompt extends StatelessWidget {
  const SetupBudgetPrompt({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No weekly budget yet',
              style: context.text.labelLarge?.copyWith(color: Brand.hay),
            ),
            const SizedBox(height: 2),
            Text(
              'Give yourself a comfortable limit.',
              style: context.text.bodyMedium?.copyWith(
                color: context.tokens.onHeroMuted,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: Brand.md),
      TextButton(
        onPressed: () => context.push('/budget/week/edit'),
        style: TextButton.styleFrom(
          foregroundColor: Brand.wheat,
          minimumSize: const Size(0, Brand.minTouchTarget),
        ),
        child: const Text('Set budget'),
      ),
    ],
  );
}
