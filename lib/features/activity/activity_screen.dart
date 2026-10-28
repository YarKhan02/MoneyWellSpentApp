import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/shell.dart' show SettingsAction;
import '../../core/design/tokens.dart';
import '../../shared/widgets/widgets.dart';
import '../expenses/widgets/expense_tile.dart';
import '../ledger/formatting.dart';
import '../ledger/models.dart';
import 'widgets/activity_filters.dart';
import 'widgets/activity_summary.dart';

/// The full expense history, filterable by category and date range.
///
/// Filters arrive as query parameters so an insights category can deep-link
/// straight into its own entries.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.data,
    this.category,
    this.start,
    this.end,
  });
  final LedgerSnapshot data;
  final String? category, start, end;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String? category;
  DateTime? start, end;

  @override
  void initState() {
    super.initState();
    _readFilters();
  }

  @override
  void didUpdateWidget(ActivityScreen old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category ||
        old.start != widget.start ||
        old.end != widget.end) {
      _readFilters();
    }
  }

  void _readFilters() {
    category = widget.category;
    start = DateTime.tryParse(widget.start ?? '');
    end = DateTime.tryParse(widget.end ?? '');
  }

  List<Expense> get _matching => widget.data.expenses
      .where(
        (e) =>
            (category == null || e.categoryId == category) &&
            (start == null || !e.occurredAt.isBefore(start!)) &&
            (end == null || e.occurredAt.isBefore(end!)),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final p = data.profile!;
    final entries = _matching;
    return PageBody(
      gap: Brand.lg,
      children: [
        const AppHeader(title: 'Activity', action: SettingsAction()),
        ActivitySummary(
          count: entries.length,
          total: p.money(entries.fold(0, (t, e) => t + e.amount.minor)),
        ),
        ActivityFilters(
          profile: p,
          categories: data.categories,
          category: category,
          start: start,
          end: end,
          onCategoryChanged: (value) => setState(() => category = value),
          onRangeChanged: (from, to) => setState(() {
            start = from;
            end = to;
          }),
          onCleared: () => setState(() {
            start = null;
            end = null;
            category = null;
          }),
        ),
        if (entries.isEmpty)
          _EmptyActivity(hasAnyExpenses: data.expenses.isNotEmpty)
        else
          ..._dayGroups(entries, p, data),
      ],
    );
  }

  /// A small heading per day, each followed by that day's entries as one
  /// surface, newest day first.
  List<Widget> _dayGroups(
    List<Expense> entries,
    Profile profile,
    LedgerSnapshot data,
  ) {
    final groups = <String, List<Expense>>{};
    for (final e in entries) {
      groups.putIfAbsent(profile.formatDate(e.occurredAt), () => []).add(e);
    }
    return [
      for (final entry in groups.entries)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: Brand.xs,
                bottom: Brand.sm,
              ),
              child: Text(
                entry.key,
                style: context.text.labelMedium?.copyWith(color: Brand.muted),
              ),
            ),
            ListSurface(
              children: [
                for (final e in entry.value)
                  ExpenseTile(expense: e, data: data),
              ],
            ),
          ],
        ),
    ];
  }
}

/// Distinguishes "you have no expenses at all" from "nothing matches this
/// filter" — the first needs a call to action, the second needs a hint.
class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.hasAnyExpenses});
  final bool hasAnyExpenses;

  @override
  Widget build(BuildContext context) => EmptyState(
    title: hasAnyExpenses ? 'No matching expenses' : 'Your story starts here',
    message: hasAnyExpenses
        ? 'Try another category or date range.'
        : 'Add an expense to start your private ledger.',
    action: hasAnyExpenses
        ? null
        : FilledButton.icon(
            onPressed: () => context.push('/expenses/new'),
            icon: const Icon(Icons.add, size: Brand.iconSize),
            label: const Text('Add expense'),
          ),
  );
}
