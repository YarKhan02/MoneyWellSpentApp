import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/shell.dart' show SettingsAction;
import '../../core/design/chart_palette.dart';
import '../../core/design/tokens.dart';
import '../../core/time/period.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/category_share.dart';
import '../ledger/formatting.dart';
import '../ledger/models.dart';
import 'widgets/category_breakdown_chart.dart';
import 'widgets/category_row.dart';
import 'widgets/insights_summary.dart';
import 'widgets/period_selector.dart';

/// Spending broken down by category for a chosen period, with navigation
/// backwards and forwards through periods.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.data, this.initialPeriod});
  final LedgerSnapshot data;

  /// `day` / `week` / `month` / `year`, from the route's query string.
  final String? initialPeriod;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Period period = Period.month;
  DateTime anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    _readPeriod();
  }

  @override
  void didUpdateWidget(InsightsScreen old) {
    super.didUpdateWidget(old);
    if (old.initialPeriod != widget.initialPeriod) {
      _readPeriod();
      anchor = DateTime.now();
    }
  }

  void _readPeriod() => period =
      Period.values.where((p) => p.name == widget.initialPeriod).firstOrNull ??
      Period.month;

  /// Steps the anchor to the instant just before, or just after, the window
  /// currently shown.
  void _step(int direction) {
    final r = widget.data.profile!.range(period, anchor);
    setState(
      () => anchor = direction < 0
          ? r.start.subtract(const Duration(microseconds: 1))
          : r.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final p = data.profile!;
    final range = p.range(period, anchor);
    final total = data.total(range.start, range.end);
    final shares = CategoryShare.within(data, range);
    return PageBody(
      gap: Brand.lg,
      children: [
        const AppHeader(
          title: 'Insights',
          subtitle: 'See where your money goes.',
          action: SettingsAction(),
        ),
        PeriodSelector(
          period: period,
          onChanged: (value) => setState(() => period = value),
        ),
        _PeriodStepper(
          label: p.periodLabel(range, period),
          // The exact boundaries stay available to assistive technology and
          // on long press, even though the label is shortened.
          exactRange: p.formatRange(range),
          onStep: _step,
        ),
        InsightsSummary(
          period: period,
          total: p.money(total),
          count: data.expenses
              .where(
                (e) =>
                    !e.occurredAt.isBefore(range.start) &&
                    e.occurredAt.isBefore(range.end),
              )
              .length,
        ),
        if (total == 0)
          const EmptyState(
            title: 'A fresh page',
            message: 'There are no expenses in this period.',
          )
        else ...[
          CategoryBreakdownChart(
            shares: shares,
            largestLabel: shares.first.label,
          ),
          ListSurface(
            children: [
              for (var i = 0; i < shares.length; i++)
                InkWell(
                  onTap: () => context.go(_activityLink(shares[i], range)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Brand.lg,
                      vertical: Brand.md,
                    ),
                    child: CategoryRow(
                      share: shares[i],
                      chartColor: chartColorAt(i),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Deep link into Activity, pre-filtered to this category and period.
  String _activityLink(CategoryShare share, CalendarRange range) => Uri(
    path: '/activity',
    queryParameters: {
      'category': share.category.id,
      'start': range.start.toIso8601String(),
      'end': range.end.toIso8601String(),
    },
  ).toString();
}

/// Previous / next arrows around the current period's name. The arrows are
/// visually small but keep full-size touch targets.
class _PeriodStepper extends StatelessWidget {
  const _PeriodStepper({
    required this.label,
    required this.exactRange,
    required this.onStep,
  });
  final String label, exactRange;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StepButton(
        tooltip: 'Previous period',
        icon: Icons.chevron_left,
        onPressed: () => onStep(-1),
      ),
      Expanded(
        child: Tooltip(
          message: exactRange,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
            semanticsLabel: '$label. $exactRange',
          ),
        ),
      ),
      _StepButton(
        tooltip: 'Next period',
        icon: Icons.chevron_right,
        onPressed: () => onStep(1),
      ),
    ],
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: Brand.iconSize,
    constraints: const BoxConstraints.tightFor(
      width: Brand.minTouchTarget,
      height: Brand.minTouchTarget,
    ),
    padding: EdgeInsets.zero,
    icon: Icon(icon),
  );
}
