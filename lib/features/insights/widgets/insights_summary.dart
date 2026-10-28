import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../core/time/period.dart';
import '../../../shared/widgets/widgets.dart';
import 'period_selector.dart';

/// Period total and transaction count for the window being viewed.
///
/// This is the one place the period total is given prominence; the chart
/// below shows composition, not the same figure again.
class InsightsSummary extends StatelessWidget {
  const InsightsSummary({
    super.key,
    required this.period,
    required this.total,
    required this.count,
  });
  final Period period;
  final Money total;
  final int count;

  @override
  Widget build(BuildContext context) => HeroCard(
    padding: const EdgeInsets.symmetric(
      horizontal: Brand.xl,
      vertical: Brand.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${periodName(period)} · $count ${count == 1 ? 'transaction' : 'transactions'}',
          style: context.text.bodyMedium?.copyWith(
            color: context.tokens.onHeroMuted,
          ),
        ),
        const SizedBox(height: Brand.xs),
        AmountText(
          money: total,
          style: context.text.displaySmall,
          color: Brand.hay,
          currencyColor: context.tokens.onHeroMuted,
        ),
      ],
    ),
  );
}
