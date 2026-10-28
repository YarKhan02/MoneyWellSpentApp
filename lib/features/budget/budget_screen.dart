import 'package:flutter/material.dart';
import '../../app/shell.dart' show SettingsAction;
import '../../core/design/tokens.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/budget_status.dart';
import '../ledger/models.dart';
import 'widgets/budget_card.dart';
import 'widgets/budget_signals_card.dart';

/// Weekly and monthly caps, plus any milestones already reached.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key, required this.data});
  final LedgerSnapshot data;

  /// The two cap periods Phase 1 supports. They are independent of each
  /// other: setting or removing one never affects the other.
  static const periods = ['week', 'month'];

  @override
  Widget build(BuildContext context) => PageBody(
    gap: Brand.lg,
    children: [
      const AppHeader(
        title: 'Budgets',
        subtitle: 'Weekly and monthly caps work independently.',
        action: SettingsAction(),
      ),
      for (final period in periods)
        BudgetCard(
          status: BudgetStatus.of(data, period),
          profile: data.profile!,
        ),
      if (data.alerts.isNotEmpty) BudgetSignalsCard(signals: data.alerts),
    ],
  );
}
