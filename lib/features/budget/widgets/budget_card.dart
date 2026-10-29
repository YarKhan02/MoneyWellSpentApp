import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/money/money_display.dart';
import '../../../shared/widgets/widgets.dart';
import '../../ledger/budget_status.dart';
import '../../ledger/formatting.dart';
import '../../ledger/models.dart';

/// One period's budget: an invitation when no cap is set, otherwise a
/// compact progress card.
///
/// Both states sit on a neutral surface. Dark green is reserved for the
/// single headline summary on Home, so two budget cards stacked here do not
/// turn the page into a wall of it.
///
/// Every state is also stated in words — "left", "exactly on budget",
/// "over" — so status never depends on the bar's colour alone.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.status, required this.profile});
  final BudgetStatus status;
  final Profile profile;

  String get _editPath => '/budget/${status.periodType}/edit';

  @override
  Widget build(BuildContext context) =>
      status.hasCap ? _progress(context) : _invitation(context);

  Widget _invitation(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: Brand.forest,
              size: Brand.iconSize,
            ),
            const SizedBox(width: Brand.sm),
            Expanded(
              child: Text(status.title, style: context.text.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: Brand.xs),
        Text(
          'No ${status.adjective} limit set yet.',
          style: context.text.bodyMedium?.copyWith(color: Brand.muted),
        ),
        const SizedBox(height: Brand.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () => context.push(_editPath),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, Brand.compactButtonHeight),
              padding: const EdgeInsets.symmetric(horizontal: Brand.xl),
            ),
            child: const Text('Set budget'),
          ),
        ),
      ],
    ),
  );

  Widget _progress(BuildContext context) {
    final accent = status.over ? Brand.cherry : Brand.forest;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status.title, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      profile.formatRange(status.range),
                      style: context.text.labelMedium?.copyWith(
                        color: Brand.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Brand.sm),
              // Compact, consistently placed edit affordance in place of the
              // former full-width button.
              IconButton(
                tooltip: 'Edit ${status.adjective} cap',
                onPressed: () => context.push(_editPath),
                iconSize: Brand.iconSize,
                constraints: const BoxConstraints.tightFor(
                  width: Brand.minTouchTarget,
                  height: Brand.minTouchTarget,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          const SizedBox(height: Brand.md),
          AmountText(
            money: status.remainingMoney,
            style: context.text.headlineSmall,
            color: accent,
          ),
          Text(
            _statusLine,
            style: context.text.labelLarge?.copyWith(color: accent),
          ),
          const SizedBox(height: Brand.md),
          ProgressBar(
            percent: status.percentUsed,
            color: accent,
            track: context.tokens.track,
            label: '${status.title} used',
            height: 8,
          ),
          const SizedBox(height: Brand.sm),
          Text(
            '${status.spentMoney.display} of ${status.capMoney!.display} · ${status.percentUsedLabel} used',
            style: context.text.bodyMedium?.copyWith(color: Brand.muted),
          ),
        ],
      ),
    );
  }

  /// Covers all four states the brief requires: no cap (handled above),
  /// under, exactly on, and over.
  String get _statusLine {
    if (status.over) return 'over your limit';
    if (status.remaining == 0) return 'exactly on budget';
    return 'left to spend';
  }
}
