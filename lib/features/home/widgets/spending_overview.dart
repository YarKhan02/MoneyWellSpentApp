import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/time/period.dart';
import '../../../shared/widgets/widgets.dart';
import '../../ledger/budget_status.dart';
import '../../ledger/formatting.dart';
import '../../ledger/models.dart';
import '../../ledger/spending_comparison.dart';
import 'budget_strip.dart';

/// The one prominent surface on Home: what has been spent this month, how
/// that compares with last month, and where the weekly budget stands.
///
/// Hierarchy runs period → amount → budget, so the figure is read first and
/// the budget is clearly a different, weekly measure rather than a second
/// monthly one.
class SpendingOverview extends StatelessWidget {
  const SpendingOverview({
    super.key,
    required this.profile,
    required this.month,
    required this.monthTotal,
    required this.comparison,
    required this.weekly,
  });

  final Profile profile;
  final CalendarRange month;
  final int monthTotal;
  final SpendingComparison comparison;
  final BudgetStatus weekly;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent this month',
                  style: context.text.bodyMedium?.copyWith(
                    color: t.onHeroMuted,
                  ),
                ),
              ),
              const SizedBox(width: Brand.sm),
              Pill(label: profile.periodLabel(month, Period.month)),
            ],
          ),
          const SizedBox(height: Brand.xs),
          AmountText(
            money: profile.money(monthTotal),
            style: context.text.displaySmall,
            color: Brand.hay,
            currencyColor: t.onHeroMuted,
          ),
          if (comparison.hasChange) ...[
            const SizedBox(height: Brand.xs),
            Text(
              comparison.label('last month'),
              style: context.text.labelLarge?.copyWith(
                color: comparison.increased
                    ? Brand.wheat
                    : const Color(0xFF8FD0A0),
              ),
            ),
          ],
          const SizedBox(height: Brand.lg),
          Divider(height: 1, color: Colors.white.withValues(alpha: .12)),
          const SizedBox(height: Brand.lg),
          if (weekly.hasCap)
            BudgetStrip(status: weekly)
          else
            const SetupBudgetPrompt(),
          const SizedBox(height: Brand.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/insights?period=month'),
              style: TextButton.styleFrom(
                foregroundColor: Brand.wheat,
                padding: const EdgeInsets.symmetric(vertical: Brand.sm),
                minimumSize: const Size(0, Brand.minTouchTarget),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Explore your spending →'),
            ),
          ),
        ],
      ),
    );
  }
}
