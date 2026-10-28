import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../ledger/formatting.dart';
import '../../ledger/models.dart';

/// One expense row: category avatar, name, note (or timestamp), amount.
/// Shared by the home list and the activity list.
///
/// It carries its own padding so the ink response fills the whole row when
/// it sits inside a [ListSurface]. At normal text size the row lands around
/// 64 logical pixels tall and grows from there as text scales.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.data});
  final Expense expense;
  final LedgerSnapshot data;

  @override
  Widget build(BuildContext context) {
    final category = data.category(expense.categoryId);
    // The note is the more useful second line when there is one; otherwise
    // fall back to when the expense happened.
    final subtitle = expense.note.isEmpty
        ? data.profile!.formatDate(expense.occurredAt, time: true)
        : expense.note;
    return InkWell(
      onTap: () => context.push('/expenses/${expense.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Brand.md,
          horizontal: Brand.lg,
        ),
        child: Row(
          children: [
            CategoryAvatar(iconKey: category.icon, colorKey: category.color),
            const SizedBox(width: Brand.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // A long note is ellipsised here; the full text is on the
                  // detail screen. Amounts are never treated this way.
                  Text(
                    subtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: Brand.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Brand.md),
            // Capped so a very long amount wraps within the row instead of
            // squeezing the category name to nothing.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: AmountText(
                money: expense.amount,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
