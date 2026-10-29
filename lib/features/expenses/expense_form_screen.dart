import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../app/providers.dart';
import '../../core/design/category_style.dart';
import '../../core/design/tokens.dart';
import '../../core/money/money.dart';
import '../../shared/errors.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/formatting.dart';
import '../ledger/models.dart';

/// Add or edit one expense.
///
/// Presented as a bottom sheet when adding (so the ledger stays visible
/// behind it) and as a full page when editing from the detail screen.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, required this.data, this.id});
  final LedgerSnapshot data;

  /// Null when adding; the expense id when editing.
  final String? id;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseFormScreen> {
  final amount = TextEditingController();
  final note = TextEditingController();

  /// Generated once so a double submit cannot create two records.
  late String id;
  String? category;
  late DateTime occurredAt;
  bool busy = false;
  String? error;

  bool get editing => widget.id != null;
  Expense? get existing =>
      widget.data.expenses.where((e) => e.id == widget.id).firstOrNull;
  Profile get profile => widget.data.profile!;

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
            amount: Money.parse(amount.text, profile.currency),
            categoryId: category!,
            note: note.text,
            occurredAt: occurredAt,
            editing: editing,
          );
      if (mounted) {
        HapticFeedback.lightImpact();
        context.pop();
        // Only confirm a brand-new entry. After an edit the detail screen
        // underneath already shows the new figure, so a toast would add
        // nothing — and it would land on top of that screen's own Delete
        // button for several seconds.
        if (!editing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense saved on this device.')),
          );
        }
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

  /// Date then time, both in the book's timezone. A local time that does not
  /// exist (the spring-forward gap) is rejected rather than silently shifted.
  Future<void> pickDate() async {
    final loc = tz.getLocation(profile.timezone);
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
    if (editing && existing == null) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            title: 'Expense not found',
            message: 'It may have been deleted.',
          ),
        ),
      );
    }
    // The ledger stays visible behind this sheet, so a light frosting here
    // is the one place in the app where translucency shows anything. It is
    // dropped entirely when the viewer prefers opaque surfaces, reduced
    // motion or high contrast.
    final media = MediaQuery.of(context);
    final solid =
        profile.reduceTransparency ||
        media.disableAnimations ||
        media.highContrast;
    final body = Scaffold(
      backgroundColor: context.scheme.surface.withValues(
        alpha: solid ? 1 : .94,
      ),
      // The sheet itself is lifted above the keyboard below, so the inner
      // Scaffold must not inset the body a second time.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(editing ? 'Edit expense' : 'A little spent'),
        actions: [
          IconButton(
            tooltip: 'Close',
            onPressed: busy ? null : () => context.pop(),
            icon: const Icon(Icons.close, size: Brand.iconSize),
          ),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            MoneyField(
              controller: amount,
              currency: profile.currency,
              label: 'Amount',
              autofocus: !editing,
            ),
            Text('Category', style: context.text.labelLarge),
            _CategoryPicker(
              categories: widget.data.categories,
              selected: category,
              keepArchived: existing?.categoryId,
              enabled: !busy,
              onSelected: (id) => setState(() => category = id),
            ),
            TextField(
              controller: note,
              maxLength: 280,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : pickDate,
              icon: const Icon(Icons.schedule, size: Brand.iconSize),
              label: Text(
                '${profile.formatDate(occurredAt, time: true)}\n${profile.timezone}',
              ),
            ),
            if (error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: TextStyle(color: context.scheme.error),
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
    if (editing) return body;
    // Adding is presented as a sheet over the ledger. The keyboard inset is
    // applied outside the sheet so the sheet shrinks rather than sliding
    // under the keyboard — the amount field, any error and Save all stay
    // reachable.
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: .94,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Brand.sheetRadius),
            ),
            child: solid
                ? body
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: body,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Chip row of selectable categories. An archived category is offered only
/// when the expense being edited already uses it.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.keepArchived,
    required this.enabled,
    required this.onSelected,
  });
  final List<Category> categories;
  final String? selected, keepArchived;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Brand.sm,
    runSpacing: Brand.sm,
    children: [
      for (final c in categories)
        if (!c.archived || c.id == keepArchived)
          ChoiceChip(
            avatar: Icon(
              categoryIcon(c.icon),
              size: 18,
              color: c.id == selected ? Colors.white : categoryColor(c.color),
            ),
            label: Text(c.name),
            selected: c.id == selected,
            onSelected: enabled ? (_) => onSelected(c.id) : null,
          ),
    ],
  );
}
