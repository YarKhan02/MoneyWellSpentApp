import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// Milestones already reached in the current period.
///
/// A signal is recorded once and never withdrawn, so the card says plainly
/// that live usage, not this list, reflects later edits and deletions.
class BudgetSignalsCard extends StatelessWidget {
  const BudgetSignalsCard({super.key, required this.signals});
  final List<String> signals;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This period’s signals', style: context.text.titleMedium),
        const SizedBox(height: Brand.xs),
        Text(
          'Reached this period. Live usage above reflects later edits.',
          style: context.text.bodyMedium?.copyWith(color: Brand.muted),
        ),
        const SizedBox(height: Brand.sm),
        for (final signal in signals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Brand.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  size: Brand.smallIconSize,
                  color: Brand.forest,
                ),
                const SizedBox(width: Brand.md),
                Expanded(child: Text(signal)),
              ],
            ),
          ),
      ],
    ),
  );
}
