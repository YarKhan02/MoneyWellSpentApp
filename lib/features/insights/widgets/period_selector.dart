import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/time/period.dart';
import '../../../shared/widgets/widgets.dart';

/// Segmented Day / Week / Month / Year control.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.onChanged,
  });
  final Period period;
  final ValueChanged<Period> onChanged;

  static const _transition = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(Brand.xs),
    child: Row(
      children: [
        for (final option in Period.values)
          Expanded(
            child: Semantics(
              selected: option == period,
              inMutuallyExclusiveGroup: true,
              button: true,
              child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: _transition,
                padding: const EdgeInsets.symmetric(vertical: Brand.sm),
                constraints: const BoxConstraints(minHeight: 40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: option == period ? Brand.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(Brand.smallRadius),
                ),
                child: Text(
                  periodName(option),
                  textAlign: TextAlign.center,
                  style: context.text.labelLarge?.copyWith(
                    color: option == period
                        ? Colors.white
                        : context.scheme.onSurface,
                  ),
                ),
              ),
            ),
            ),
          ),
      ],
    ),
  );
}

/// The segmented control's name for a period: `Period.month` → `Month`.
/// Not to be confused with `ProfileCalendar.periodLabel`, which names the
/// specific window being viewed (`October 2026`).
String periodName(Period period) =>
    '${period.name[0].toUpperCase()}${period.name.substring(1)}';
