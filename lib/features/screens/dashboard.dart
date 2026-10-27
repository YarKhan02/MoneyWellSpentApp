import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../app/app.dart';
import '../../core/design/theme.dart';
import '../../core/money/money.dart';
import '../../core/time/period.dart';
import '../ledger/models.dart';

String localDate(DateTime date, Profile p, {bool time = false}) => DateFormat(
  time ? 'd MMM y · HH:mm' : 'EEE, d MMM y',
).format(tz.TZDateTime.from(date, tz.getLocation(p.timezone)));
CalendarRange rangeFor(LedgerSnapshot d, Period period, [DateTime? anchor]) =>
    CalendarRange.containing(
      anchor ?? DateTime.now(),
      d.profile!.timezone,
      period,
      weekStart: d.profile!.weekStart,
    );
String rangeLabel(CalendarRange r, Profile p) =>
    '${localDate(r.start, p)} – ${localDate(r.end.subtract(const Duration(microseconds: 1)), p)}';

Widget homeScreen(BuildContext context, LedgerSnapshot data) {
  final p = data.profile!;
  final month = rangeFor(data, Period.month);
  final weekly = data.budgets.where((b) => b.period == 'week');
  return PageBody(
    children: [
      Text(
        'A little clarity.\nA lot more possibility.',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      GlassCard(
        opaque: p.reduceTransparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('THIS MONTH'),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Money(data.total(month.start, month.end), p.currency).formatted,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Every expense, a clearer picture.'),
            TextButton(
              onPressed: () => context.go('/insights?period=month'),
              child: const Text('Explore your spending →'),
            ),
          ],
        ),
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final period in [Period.day, Period.week])
            ActionChip(
              label: Text(
                '${period == Period.day ? 'Today' : 'This week'}  ${Money(data.total(rangeFor(data, period).start, rangeFor(data, period).end), p.currency).formatted}',
              ),
              onPressed: () => context.go('/insights?period=${period.name}'),
            ),
        ],
      ),
      if (weekly.isNotEmpty)
        BudgetCard(data: data, budget: weekly.single, period: 'week'),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Recent expenses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/activity'),
            child: const Text('See all'),
          ),
        ],
      ),
      if (data.expenses.isEmpty)
        EmptyState(
          title: 'Make room for the little things',
          message:
              'Add your first expense. Your spending stays on this device.',
          action: FilledButton.icon(
            onPressed: () => context.push('/expenses/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add your first expense'),
          ),
        )
      else
        ...data.expenses
            .take(5)
            .map((e) => ExpenseTile(expense: e, data: data)),
    ],
  );
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.data});
  final Expense expense;
  final LedgerSnapshot data;
  @override
  Widget build(BuildContext context) {
    final category = data.category(expense.categoryId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Brand.wheat.withValues(alpha: .3),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        child: Icon(categoryIcon(category.icon)),
      ),
      title: Text(category.name),
      subtitle: Text(
        expense.note.isEmpty
            ? localDate(expense.occurredAt, data.profile!, time: true)
            : expense.note,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(
          expense.amount.formatted,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      onTap: () => context.push('/expenses/${expense.id}'),
    );
  }
}

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
  State<ActivityScreen> createState() => _ActivityState();
}

class _ActivityState extends State<ActivityScreen> {
  String? category;
  DateTime? start, end;
  @override
  void initState() {
    super.initState();
    readFilters();
  }

  void readFilters() {
    category = widget.category;
    start = DateTime.tryParse(widget.start ?? '');
    end = DateTime.tryParse(widget.end ?? '');
  }

  @override
  void didUpdateWidget(ActivityScreen old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category ||
        old.start != widget.start ||
        old.end != widget.end) {
      readFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final entries = d.expenses
        .where(
          (e) =>
              (category == null || e.categoryId == category) &&
              (start == null || !e.occurredAt.isBefore(start!)) &&
              (end == null || e.occurredAt.isBefore(end!)),
        )
        .toList();
    String? lastDate;
    return PageBody(
      children: [
        Text('Your activity', style: Theme.of(context).textTheme.headlineSmall),
        DropdownButtonFormField<String>(
          initialValue: category ?? '',
          decoration: const InputDecoration(labelText: 'Category filter'),
          items: [
            const DropdownMenuItem(value: '', child: Text('All categories')),
            ...d.categories.map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: (value) =>
              setState(() => category = value == '' ? null : value),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                start == null
                    ? 'All dates'
                    : rangeLabel(CalendarRange(start!, end!), d.profile!),
              ),
              onPressed: () async {
                final selected = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2200),
                );
                if (selected != null) {
                  final loc = tz.getLocation(d.profile!.timezone);
                  setState(() {
                    start = tz.TZDateTime(
                      loc,
                      selected.start.year,
                      selected.start.month,
                      selected.start.day,
                    ).toUtc();
                    end = tz.TZDateTime(
                      loc,
                      selected.end.year,
                      selected.end.month,
                      selected.end.day + 1,
                    ).toUtc();
                  });
                }
              },
            ),
            if (start != null || category != null)
              TextButton(
                onPressed: () => setState(() {
                  start = null;
                  end = null;
                  category = null;
                }),
                child: const Text('Clear filters'),
              ),
          ],
        ),
        if (entries.isEmpty)
          EmptyState(
            title: d.expenses.isEmpty
                ? 'Your story starts here'
                : 'No matching expenses',
            message: d.expenses.isEmpty
                ? 'Add an expense to start your private ledger.'
                : 'Try another category or date range.',
          ),
        for (final e in entries) ...[
          if (lastDate != localDate(e.occurredAt, d.profile!))
            Text(
              lastDate = localDate(e.occurredAt, d.profile!),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ExpenseTile(expense: e, data: d),
        ],
      ],
    );
  }
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.data, this.initialPeriod});
  final LedgerSnapshot data;
  final String? initialPeriod;
  @override
  State<InsightsScreen> createState() => _InsightsState();
}

class _InsightsState extends State<InsightsScreen> {
  Period period = Period.month;
  DateTime anchor = DateTime.now();
  @override
  void initState() {
    super.initState();
    parsePeriod();
  }

  void parsePeriod() {
    period =
        Period.values
            .where((p) => p.name == widget.initialPeriod)
            .firstOrNull ??
        Period.month;
  }

  @override
  void didUpdateWidget(InsightsScreen old) {
    super.didUpdateWidget(old);
    if (old.initialPeriod != widget.initialPeriod) {
      parsePeriod();
      anchor = DateTime.now();
    }
  }

  void navigate(int direction) {
    final r = rangeFor(widget.data, period, anchor);
    setState(
      () => anchor = direction < 0
          ? r.start.subtract(const Duration(microseconds: 1))
          : r.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final r = rangeFor(d, period, anchor);
    final total = d.total(r.start, r.end);
    final shares =
        [
            for (final c in d.categories)
              (category: c, amount: d.total(r.start, r.end, category: c.id)),
          ].where((s) => s.amount > 0).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    return PageBody(
      children: [
        Text(
          'See the bigger picture',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Wrap(
          spacing: 8,
          children: Period.values
              .map(
                (p) => ChoiceChip(
                  label: Text(
                    '${p.name[0].toUpperCase()}${p.name.substring(1)}',
                  ),
                  selected: p == period,
                  onSelected: (_) => setState(() => period = p),
                ),
              )
              .toList(),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous period',
              onPressed: () => navigate(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                rangeLabel(r, d.profile!),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Next period',
              onPressed: () => navigate(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Text(
          Money(total, d.profile!.currency).formatted,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        if (total == 0)
          const EmptyState(
            title: 'A fresh page',
            message: 'There are no expenses in this period.',
          )
        else ...[
          Semantics(
            label: 'Spending by category. Exact amounts are listed below.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 210,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 65,
                    sectionsSpace: 3,
                    sections: [
                      for (var i = 0; i < shares.length; i++)
                        PieChartSectionData(
                          value: shares[i].amount.toDouble(),
                          color: [
                            Brand.forest,
                            Brand.wheat,
                            Brand.cherry,
                            Brand.muted,
                          ][i % 4],
                          radius: 30,
                          showTitle: false,
                        ),
                    ],
                  ),
                  duration: Duration.zero,
                ),
              ),
            ),
          ),
          for (final s in shares)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(categoryIcon(s.category.icon)),
              title: Text(
                '${s.category.name}${s.category.archived ? ' (archived)' : ''}',
              ),
              subtitle: Text(
                '${(s.amount * 100 / total).toStringAsFixed(1)}% · ${Money(s.amount, d.profile!.currency).formatted}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(
                Uri(
                  path: '/activity',
                  queryParameters: {
                    'category': s.category.id,
                    'start': r.start.toIso8601String(),
                    'end': r.end.toIso8601String(),
                  },
                ).toString(),
              ),
            ),
        ],
      ],
    );
  }
}

Widget budgetScreen(BuildContext context, LedgerSnapshot d) => PageBody(
  children: [
    Text(
      'Give your money a little direction.',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const Text(
      'Set a comfortable cap. Weekly and monthly budgets work independently.',
    ),
    for (final period in ['week', 'month'])
      BudgetCard(
        data: d,
        period: period,
        budget: d.budgets.where((b) => b.period == period).firstOrNull,
      ),
    if (d.alerts.isNotEmpty) ...[
      Text(
        'This period’s signals',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Text(
        'Milestones reached this period. Current usage above reflects edits and deletions.',
      ),
      ...d.alerts.map(
        (a) => ListTile(
          leading: const Icon(Icons.notifications_none),
          title: Text(a),
        ),
      ),
    ],
  ],
);

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.data,
    required this.period,
    this.budget,
  });
  final LedgerSnapshot data;
  final String period;
  final Budget? budget;
  @override
  Widget build(BuildContext context) {
    final range = rangeFor(data, period == 'week' ? Period.week : Period.month);
    final spent = data.total(range.start, range.end);
    final cap = budget?.amount.minor;
    final remaining = (cap ?? 0) - spent;
    final percent = cap == null ? 0.0 : spent * 100 / cap;
    return GlassCard(
      opaque: data.profile!.reduceTransparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period == 'week' ? 'Weekly budget' : 'Monthly budget',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(rangeLabel(range, data.profile!)),
          const SizedBox(height: 20),
          if (cap == null)
            const Text(
              'A little intention goes a long way. Set your first cap.',
            )
          else ...[
            Text(
              '${Money(remaining.abs(), data.profile!.currency).formatted} ${remaining < 0 ? 'over budget' : 'remaining'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              minHeight: 8,
              color: remaining < 0 ? Brand.cherry : Brand.forest,
              backgroundColor: Brand.wheat.withValues(alpha: .3),
              semanticsLabel: 'Budget used',
              semanticsValue: '${percent.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            Text(
              '${Money(spent, data.profile!.currency).formatted} of ${budget!.amount.formatted} · ${percent.toStringAsFixed(1)}% used',
            ),
            const SizedBox(height: 8),
            Text(
              'Updated ${localDate(budget!.updatedAt, data.profile!, time: true)}',
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push('/budget/$period/edit'),
            child: Text(cap == null ? 'Set cap' : 'Edit cap'),
          ),
        ],
      ),
    );
  }
}
