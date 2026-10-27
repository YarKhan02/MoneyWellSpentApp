import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../app/app.dart';
import '../../app/providers.dart';
import '../../core/design/theme.dart';
import '../../core/money/money.dart';
import '../ledger/models.dart';
import 'dashboard.dart';

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;
String friendlyError(Object error) => error is FormatException
    ? error.message
    : 'Could not save this change. Your existing data is retained. Please retry.';

Widget newExpenseScreen(BuildContext context, LedgerSnapshot data) =>
    ExpenseForm(data: data);

class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({super.key, required this.data, this.id});
  final LedgerSnapshot data;
  final String? id;
  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final amount = TextEditingController();
  final note = TextEditingController();
  late String id;
  String? category;
  late DateTime occurredAt;
  bool busy = false;
  String? error;
  Expense? get existing =>
      widget.data.expenses.where((e) => e.id == widget.id).firstOrNull;
  @override
  void initState() {
    super.initState();
    id = widget.id ?? ref.read(repositoryProvider).newId();
    occurredAt = existing?.occurredAt ?? DateTime.now().toUtc();
    amount.text = existing?.amount.decimal ?? '';
    note.text = existing?.note ?? '';
    category = existing?.categoryId;
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (category == null) throw const FormatException('Choose a category.');
      await ref
          .read(repositoryProvider)
          .saveExpense(
            id: id,
            amount: Money.parse(amount.text, widget.data.profile!.currency),
            categoryId: category!,
            note: note.text,
            occurredAt: occurredAt,
            editing: widget.id != null,
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved on this device.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = friendlyError(e);
          busy = false;
        });
      }
    }
  }

  Future<void> pickDate() async {
    final loc = tz.getLocation(widget.data.profile!.timezone);
    final local = tz.TZDateTime.from(occurredAt, loc);
    final date = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(1970),
      lastDate: DateTime(2200),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
    );
    if (time == null || !mounted) return;
    final chosen = tz.TZDateTime(
      loc,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (chosen.year != date.year ||
        chosen.month != date.month ||
        chosen.day != date.day ||
        chosen.hour != time.hour ||
        chosen.minute != time.minute) {
      setState(
        () => error =
            'That local time does not exist because clocks change. Choose another time.',
      );
      return;
    }
    setState(() {
      occurredAt = chosen.toUtc();
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id != null && existing == null) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            title: 'Expense not found',
            message: 'It may have been deleted.',
          ),
        ),
      );
    }
    final body = Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.id == null ? 'A little spent' : 'Edit expense'),
        actions: [
          IconButton(
            tooltip: 'Close',
            onPressed: busy ? null : () => context.pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            const Text('Make a note. Move on with your day.'),
            TextField(
              controller: amount,
              autofocus: widget.id == null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: Theme.of(context).textTheme.headlineLarge,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${widget.data.profile!.currency} ',
              ),
            ),
            Text(
              'Choose a category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.data.categories
                  .where((c) => !c.archived || c.id == existing?.categoryId)
                  .map(
                    (c) => ChoiceChip(
                      avatar: Icon(categoryIcon(c.icon), size: 18),
                      label: Text(c.name),
                      selected: c.id == category,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => category = c.id),
                    ),
                  )
                  .toList(),
            ),
            TextField(
              controller: note,
              maxLength: 280,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : pickDate,
              icon: const Icon(Icons.schedule),
              label: Text(
                '${localDate(occurredAt, widget.data.profile!, time: true)}\n${widget.data.profile!.timezone}',
              ),
            ),
            if (error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving…' : 'Save expense'),
            ),
          ],
        ),
      ),
    );
    if (widget.id != null) return body;
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: .94,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: body,
        ),
      ),
    );
  }
}

class ExpenseDetail extends ConsumerWidget {
  const ExpenseDetail({super.key, required this.data, required this.id});
  final LedgerSnapshot data;
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = data.expenses.where((e) => e.id == id).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Expense detail')),
      body: SafeArea(
        child: e == null
            ? const EmptyState(
                title: 'Expense not found',
                message:
                    'It may have been deleted. Your other entries are safe.',
              )
            : PageBody(
                children: [
                  Text(
                    e.amount.formatted,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    data.category(e.categoryId).name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(localDate(e.occurredAt, data.profile!, time: true)),
                  Text(data.profile!.timezone),
                  Text(e.note.isEmpty ? 'No note added.' : e.note),
                  Text(
                    'Created ${localDate(e.createdAt, data.profile!, time: true)}',
                  ),
                  Text(
                    'Updated ${localDate(e.updatedAt, data.profile!, time: true)}',
                  ),
                  FilledButton(
                    onPressed: () => context.push('/expenses/$id/edit'),
                    child: const Text('Edit expense'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete expense'),
                    onPressed: () async {
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
                            duration: const Duration(seconds: 8),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                try {
                                  await repository.undoDelete(id);
                                } catch (_) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not undo. Please retry.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyError(error))),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class BudgetForm extends ConsumerStatefulWidget {
  const BudgetForm({super.key, required this.data, required this.period});
  final LedgerSnapshot data;
  final String period;
  @override
  ConsumerState<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<BudgetForm> {
  final amount = TextEditingController();
  bool busy = false;
  String? error;
  Budget? get budget =>
      widget.data.budgets.where((b) => b.period == widget.period).firstOrNull;
  @override
  void initState() {
    super.initState();
    amount.text = budget?.amount.decimal ?? '';
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(repositoryProvider)
          .saveBudget(
            widget.period,
            Money.parse(amount.text, widget.data.profile!.currency),
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.period == 'week' ? 'Weekly' : 'Monthly'} cap'),
    ),
    body: PageBody(
      children: [
        const Text(
          'Choose an amount that fits your life. You can adjust it anytime.',
        ),
        TextField(
          controller: amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Spending cap',
            prefixText: '${widget.data.profile!.currency} ',
          ),
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Saving…' : 'Save cap'),
        ),
        if (budget != null)
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    if (!await confirm(
                      context,
                      'Remove this cap?',
                      'Your expenses will be kept.',
                    )) {
                      return;
                    }
                    setState(() => busy = true);
                    try {
                      await ref
                          .read(repositoryProvider)
                          .removeBudget(budget!.id);
                      if (context.mounted) context.pop();
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          busy = false;
                          error = friendlyError(e);
                        });
                      }
                    }
                  },
            child: const Text('Remove budget'),
          ),
      ],
    ),
  );
}
