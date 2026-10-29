import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../shared/dialogs.dart';
import '../../shared/errors.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/formatting.dart';
import '../ledger/models.dart';
import 'widgets/detail_row.dart';

/// Read-only view of one expense, with edit and delete.
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.data, required this.id});
  final LedgerSnapshot data;
  final String id;

  /// How long the Undo action stays on screen after a delete.
  static const undoWindow = Duration(seconds: 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = data.expenses.where((e) => e.id == id).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Expense detail')),
      body: SafeArea(
        child: expense == null
            ? const Padding(
                padding: EdgeInsets.all(Brand.xl),
                child: EmptyState(
                  title: 'Expense not found',
                  message:
                      'It may have been deleted. Your other entries are safe.',
                ),
              )
            : PageBody(
                children: [
                  _SummaryHero(data: data, expense: expense),
                  _MetadataCard(data: data, expense: expense),
                  FilledButton.icon(
                    onPressed: () => context.push('/expenses/$id/edit'),
                    icon: const Icon(Icons.edit_outlined, size: Brand.iconSize),
                    label: const Text('Edit expense'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Brand.cherry,
                      side: const BorderSide(color: Brand.cherry),
                    ),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: Brand.iconSize,
                    ),
                    label: const Text('Delete expense'),
                    onPressed: () => _delete(context, ref),
                  ),
                ],
              ),
      ),
    );
  }

  /// Soft-deletes the expense and offers Undo. The record is never destroyed,
  /// so Undo simply clears the deletion timestamp.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirm(
      context,
      'Delete this expense?',
      'It will be removed from your totals. You can undo immediately afterward.',
    )) {
      return;
    }
    try {
      final repository = ref.read(repositoryProvider);
      await repository.deleteExpense(id);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.removeCurrentSnackBar();
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Expense deleted.'),
          duration: undoWindow,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await repository.undoDelete(id);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not undo. Please retry.'),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.data, required this.expense});
  final LedgerSnapshot data;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final category = data.category(expense.categoryId);
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(
                iconKey: category.icon,
                colorKey: category.color,
                onHero: true,
              ),
              const SizedBox(width: Brand.md),
              Expanded(
                child: Text(
                  category.name,
                  style: context.text.titleMedium?.copyWith(color: Brand.hay),
                ),
              ),
            ],
          ),
          const SizedBox(height: Brand.md),
          AmountText(
            money: expense.amount,
            style: context.text.displaySmall,
            color: Brand.hay,
            currencyColor: context.tokens.onHeroMuted,
          ),
          const SizedBox(height: Brand.xs),
          Text(
            data.profile!.formatDate(expense.occurredAt, time: true),
            style: context.text.bodyMedium?.copyWith(
              color: context.tokens.onHeroMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.data, required this.expense});
  final LedgerSnapshot data;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final profile = data.profile!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRow(label: 'Timezone', value: profile.timezone),
          DetailRow(
            label: 'Note',
            value: expense.note.isEmpty ? 'No note added.' : expense.note,
          ),
          DetailRow(
            label: 'Created',
            value: profile.formatDate(expense.createdAt, time: true),
          ),
          DetailRow(
            label: 'Updated',
            value: profile.formatDate(expense.updatedAt, time: true),
            last: true,
          ),
        ],
      ),
    );
  }
}
