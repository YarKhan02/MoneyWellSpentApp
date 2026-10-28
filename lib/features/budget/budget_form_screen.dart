import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/money/money.dart';
import '../../shared/dialogs.dart';
import '../../shared/errors.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/models.dart';

/// Set or remove the cap for one period. Removing a cap never touches the
/// expenses recorded against it.
class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({
    super.key,
    required this.data,
    required this.period,
  });
  final LedgerSnapshot data;

  /// `week` or `month`.
  final String period;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<BudgetFormScreen> {
  final amount = TextEditingController();
  bool busy = false;
  String? error;

  Budget? get budget =>
      widget.data.budgets.where((b) => b.period == widget.period).firstOrNull;
  String get title => widget.period == 'week' ? 'Weekly' : 'Monthly';

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
        HapticFeedback.lightImpact();
        context.pop();
      }
    } catch (e) {
      if (mounted) _fail(e);
    }
  }

  Future<void> remove() async {
    if (!await confirm(
      context,
      'Remove this cap?',
      'Your expenses will be kept.',
    )) {
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(repositoryProvider).removeBudget(budget!.id);
      if (context.mounted) context.pop();
    } catch (e) {
      if (mounted) _fail(e);
    }
  }

  void _fail(Object e) => setState(() {
    busy = false;
    error = friendlyError(e);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('$title cap')),
    body: SafeArea(
      child: PageBody(
        children: [
          Text(
            'Choose an amount that fits your life. You can adjust it anytime.',
            style: context.text.bodyLarge?.copyWith(color: Brand.muted),
          ),
          MoneyField(
            controller: amount,
            currency: widget.data.profile!.currency,
            label: 'Spending cap',
            textStyle: context.text.headlineMedium,
            autofocus: true,
          ),
          if (error != null)
            Text(error!, style: TextStyle(color: context.scheme.error)),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Saving…' : 'Save cap'),
          ),
          if (budget != null)
            TextButton(
              onPressed: busy ? null : remove,
              child: const Text('Remove budget'),
            ),
        ],
      ),
    ),
  );
}
