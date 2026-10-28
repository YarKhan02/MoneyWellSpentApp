import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/shell.dart' show SettingsAction;
import '../../core/design/tokens.dart';
import '../../core/time/period.dart';
import '../../shared/widgets/widgets.dart';
import '../expenses/widgets/expense_tile.dart';
import '../ledger/budget_status.dart';
import '../ledger/formatting.dart';
import '../ledger/models.dart';
import '../ledger/spending_comparison.dart';
import 'widgets/spending_overview.dart';

/// The landing page: a monthly overview, two quick statistics and the most
/// recent entries.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.data});
  final LedgerSnapshot data;

  /// How many entries the "Recent expenses" list shows before "View all".
  static const recentCount = 5;

  @override
  Widget build(BuildContext context) {
    final p = data.profile!;
    final month = p.range(Period.month);
    final previous = p.previousRange(Period.month);
    final monthTotal = data.total(month.start, month.end);
    return PageBody(
      gap: Brand.lg,
      children: [
        const AppHeader(title: 'Money Well Spent', action: SettingsAction()),
        SpendingOverview(
          profile: p,
          month: month,
          monthTotal: monthTotal,
          comparison: SpendingComparison(
            current: monthTotal,
            // The previous window ends exactly where this one starts.
            previous: data.total(previous.start, month.start),
          ),
          weekly: BudgetStatus.of(data, 'week'),
        ),
        _QuickStats(data: data),
        SectionHeader(
          title: 'Recent expenses',
          action: data.expenses.isEmpty
              ? null
              : TextButton(
                  onPressed: () => context.go('/activity'),
                  child: const Text('View all'),
                ),
        ),
        if (data.expenses.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            message: 'Your spending history will appear here.',
          )
        else
          ListSurface(
            children: [
              for (final e in data.expenses.take(recentCount))
                ExpenseTile(expense: e, data: data),
            ],
          ),
      ],
    );
  }
}

/// Today and this-week totals, each linking into the matching insights view.
/// They sit side by side when there is room and stack when there is not.
class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.data});
  final LedgerSnapshot data;

  @override
  Widget build(BuildContext context) {
    final p = data.profile!;
    final day = p.range(Period.day);
    final week = p.range(Period.week);
    return ResponsivePair(
      first: MetricCard(
        label: 'Spent today',
        icon: Icons.calendar_today_outlined,
        iconColor: Brand.forest,
        money: p.money(data.total(day.start, day.end)),
        onTap: () => context.go('/insights?period=day'),
      ),
      second: MetricCard(
        label: 'Spent this week',
        icon: Icons.bar_chart_rounded,
        iconColor: Brand.cherry,
        money: p.money(data.total(week.start, week.end)),
        onTap: () => context.go('/insights?period=week'),
      ),
    );
  }
}
