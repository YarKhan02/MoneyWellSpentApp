import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/design/category_style.dart';
import '../../../core/design/chart_palette.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../ledger/category_share.dart';

/// Doughnut for two or more categories; a single full-width bar when all
/// spending in the period sits in one category (a one-slice pie reads as a
/// rendering bug).
///
/// The chart is sized from the width actually available rather than a fixed
/// height, so it shrinks on a narrow or short viewport instead of pushing
/// the breakdown below the fold. It carries no text of its own — every
/// figure is in the list underneath, which stays readable at any text size.
class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({
    super.key,
    required this.shares,
    required this.largestLabel,
  });

  final List<CategoryShare> shares;

  /// Name of the biggest slice, named in the chart's accessible summary.
  final String largestLabel;

  /// Diameter bounds on a typical phone; the actual value comes from the
  /// available width.
  static const minDiameter = 150.0;
  static const maxDiameter = 220.0;

  /// Share of the diameter taken by the hole.
  static const _holeRatio = .62;

  @override
  Widget build(BuildContext context) =>
      shares.length == 1 ? _single(context, shares.first) : _doughnut(context);

  Widget _single(BuildContext context, CategoryShare share) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CategoryAvatar(
              iconKey: share.category.icon,
              colorKey: share.category.color,
            ),
            const SizedBox(width: Brand.md),
            Expanded(
              child: Text(
                share.category.name,
                style: context.text.titleMedium,
              ),
            ),
            Text('100%', style: context.text.titleMedium),
          ],
        ),
        const SizedBox(height: Brand.md),
        ProgressBar(
          fraction: 1,
          color: categoryColor(share.category.color),
          track: context.tokens.track,
          label: '${share.category.name} share',
          value: '100%',
          height: 10,
        ),
        const SizedBox(height: Brand.sm),
        Text(
          'All spending this period is in ${share.category.name}.',
          style: context.text.bodyMedium?.copyWith(color: Brand.muted),
        ),
      ],
    ),
  );

  Widget _doughnut(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(Brand.lg),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.maxWidth.clamp(
          minDiameter,
          context.isShort ? minDiameter + 30 : maxDiameter,
        );
        return Center(
          child: Semantics(
            label:
                'Spending by category, largest share $largestLabel. '
                'Exact amounts are listed below the chart.',
            child: ExcludeSemantics(
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: diameter * _holeRatio / 2,
                    sectionsSpace: 3,
                    sections: [
                      for (var i = 0; i < shares.length; i++)
                        PieChartSectionData(
                          value: shares[i].amount.toDouble(),
                          color: chartColorAt(i),
                          radius: diameter * (1 - _holeRatio) / 2,
                          showTitle: false,
                        ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
