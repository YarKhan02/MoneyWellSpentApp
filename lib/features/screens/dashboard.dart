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

/// Chart/accent colours cycled for categories.
const _chartColors = [
  Brand.forest,
  Brand.wheat,
  Brand.cherry,
  Brand.muted,
  Color(0xFF6B8F71),
  Color(0xFFE8A13A),
];

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

Widget homeScreen(BuildContext context, LedgerSnapshot data) {
  final p = data.profile!;
  final month = rangeFor(data, Period.month);
  final prevMonthEnd = month.start;
  final prevMonth = rangeFor(
    data,
    Period.month,
    month.start.subtract(const Duration(microseconds: 1)),
  );
  final monthTotal = data.total(month.start, month.end);
  final prevTotal = data.total(prevMonth.start, prevMonthEnd);
  final weekly = data.budgets.where((b) => b.period == 'week').firstOrNull;
  return PageBody(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONEY WELL SPENT',
            style: context.text.labelMedium?.copyWith(
              color: Brand.forest,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Brand.sm),
          Text('A little clarity.', style: context.text.headlineMedium),
          Text(
            'A lot more possibility.',
            style: context.text.headlineMedium?.copyWith(color: Brand.forest),
          ),
        ],
      ),
      _SpendingHero(
        data: data,
        total: monthTotal,
        previous: prevTotal,
        weekly: weekly,
      ),
      Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'Today',
              icon: Icons.calendar_today_outlined,
              iconColor: Brand.forest,
              value: Money(
                data.total(
                  rangeFor(data, Period.day).start,
                  rangeFor(data, Period.day).end,
                ),
                p.currency,
              ).formatted,
              onTap: () => context.go('/insights?period=day'),
            ),
          ),
          const SizedBox(width: Brand.md),
          Expanded(
            child: MetricCard(
              label: 'This week',
              icon: Icons.bar_chart_rounded,
              iconColor: Brand.cherry,
              value: Money(
                data.total(
                  rangeFor(data, Period.week).start,
                  rangeFor(data, Period.week).end,
                ),
                p.currency,
              ).formatted,
              onTap: () => context.go('/insights?period=week'),
            ),
          ),
        ],
      ),
      SectionHeader(
        title: 'Recent expenses',
        action: data.expenses.isEmpty
            ? null
            : TextButton(
                onPressed: () => context.go('/activity'),
                child: const Text('View all'),
              ),
      ),
      if (data.expenses.isEmpty)
        const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No expenses yet',
          message: 'Your spending history will appear here.',
        )
      else
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Brand.md,
            vertical: Brand.xs,
          ),
          child: Column(
            children: [
              for (final e in data.expenses.take(5))
                ExpenseTile(expense: e, data: data),
            ],
          ),
        ),
    ],
  );
}

class _SpendingHero extends StatelessWidget {
  const _SpendingHero({
    required this.data,
    required this.total,
    required this.previous,
    required this.weekly,
  });
  final LedgerSnapshot data;
  final int total, previous;
  final Budget? weekly;
  @override
  Widget build(BuildContext context) {
    final p = data.profile!;
    final change = previous > 0 ? (total - previous) * 100 / previous : null;
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Overview',
                  style: context.text.titleMedium?.copyWith(
                    color: context.tokens.onHero,
                  ),
                ),
              ),
              const _Pill(label: 'This month'),
            ],
          ),
          const SizedBox(height: Brand.xl),
          Text(
            'Total spending',
            style: context.text.bodyMedium?.copyWith(
              color: context.tokens.onHeroMuted,
            ),
          ),
          const SizedBox(height: Brand.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money(total, p.currency).formatted,
              style: context.text.displaySmall?.copyWith(color: Brand.hay),
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: Brand.sm),
            Text(
              '${change >= 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(0)}% vs last month',
              style: context.text.labelLarge?.copyWith(
                color: change > 0 ? Brand.wheat : const Color(0xFF8FD0A0),
              ),
            ),
          ],
          const SizedBox(height: Brand.xl),
          if (weekly != null)
            _WeeklyNested(data: data, weekly: weekly!)
          else
            _SetupBudgetCta(onHero: p.reduceTransparency),
          TextButton(
            onPressed: () => context.go('/insights?period=month'),
            style: TextButton.styleFrom(
              foregroundColor: Brand.wheat,
              padding: const EdgeInsets.only(top: Brand.sm),
            ),
            child: const Text('Explore your spending →'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Brand.md, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: context.text.labelMedium?.copyWith(color: Brand.hay),
    ),
  );
}

/// Nested weekly budget + available-to-spend row inside the hero.
class _WeeklyNested extends StatelessWidget {
  const _WeeklyNested({required this.data, required this.weekly});
  final LedgerSnapshot data;
  final Budget weekly;
  @override
  Widget build(BuildContext context) {
    final p = data.profile!;
    final range = rangeFor(data, Period.week);
    final spent = data.total(range.start, range.end);
    final cap = weekly.amount.minor;
    final remaining = cap - spent;
    final fraction = cap == 0 ? 0.0 : (spent / cap).clamp(0, 1).toDouble();
    final pct = cap == 0 ? 0.0 : spent * 100 / cap;
    return Row(
      children: [
        Expanded(
          child: _NestedCard(
            opaque: p.reduceTransparency,
            children: [
              Text(
                'Weekly budget',
                style: context.text.labelLarge?.copyWith(color: Brand.hay),
              ),
              const SizedBox(height: Brand.sm),
              Text(
                '${Money(spent, p.currency).formatted} / ${weekly.amount.formatted}',
                style: context.text.bodyMedium?.copyWith(
                  color: context.tokens.onHeroMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Brand.md),
              _ProgressBar(
                fraction: fraction,
                color: remaining < 0 ? Brand.cherry : Brand.wheat,
                track: Colors.white.withValues(alpha: .14),
                label: 'Weekly budget used',
                value: '${pct.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
        const SizedBox(width: Brand.md),
        Expanded(
          child: _NestedCard(
            opaque: p.reduceTransparency,
            children: [
              Text(
                remaining < 0 ? 'Over budget' : 'Available',
                style: context.text.labelLarge?.copyWith(color: Brand.hay),
              ),
              const SizedBox(height: Brand.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Money(remaining.abs(), p.currency).formatted,
                  style: context.text.titleLarge?.copyWith(color: Brand.wheat),
                ),
              ),
              const SizedBox(height: Brand.xs),
              Text(
                cap == 0
                    ? ''
                    : '${(remaining * 100 / cap).clamp(0, 100).toStringAsFixed(0)}% left',
                style: context.text.labelMedium?.copyWith(
                  color: context.tokens.onHeroMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NestedCard extends StatelessWidget {
  const _NestedCard({required this.children, this.opaque = false});
  final List<Widget> children;
  final bool opaque;
  @override
  Widget build(BuildContext context) => GlassCard(
    opaque: opaque,
    onHero: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}

class _SetupBudgetCta extends StatelessWidget {
  const _SetupBudgetCta({required this.onHero});
  final bool onHero;
  @override
  Widget build(BuildContext context) => _NestedCard(
    opaque: onHero,
    children: [
      Text(
        'Set a weekly budget',
        style: context.text.titleMedium?.copyWith(color: Brand.hay),
      ),
      const SizedBox(height: Brand.xs),
      Text(
        'Give yourself a comfortable spending limit.',
        style: context.text.bodyMedium?.copyWith(
          color: context.tokens.onHeroMuted,
        ),
      ),
      const SizedBox(height: Brand.md),
      FilledButton(
        onPressed: () => context.push('/budget/week/edit'),
        style: FilledButton.styleFrom(
          backgroundColor: Brand.wheat,
          foregroundColor: Brand.earth,
        ),
        child: const Text('Set budget'),
      ),
    ],
  );
}

/// Rounded progress bar with accessible semantics.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.fraction,
    required this.color,
    required this.track,
    required this.label,
    required this.value,
    this.height = 10,
  });
  final double fraction, height;
  final Color color, track;
  final String label, value;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      value: fraction,
      minHeight: height,
      color: color,
      backgroundColor: track,
      semanticsLabel: label,
      semanticsValue: value,
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared expense row
// ---------------------------------------------------------------------------

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.data});
  final Expense expense;
  final LedgerSnapshot data;
  @override
  Widget build(BuildContext context) {
    final category = data.category(expense.categoryId);
    final subtitle = expense.note.isEmpty
        ? localDate(expense.occurredAt, data.profile!, time: true)
        : expense.note;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Brand.smallRadius),
        onTap: () => context.push('/expenses/${expense.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Brand.md,
            horizontal: Brand.xs,
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
              const SizedBox(width: Brand.sm),
              Text(
                expense.amount.formatted,
                textAlign: TextAlign.end,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity
// ---------------------------------------------------------------------------

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
    final p = d.profile!;
    final entries = d.expenses
        .where(
          (e) =>
              (category == null || e.categoryId == category) &&
              (start == null || !e.occurredAt.isBefore(start!)) &&
              (end == null || e.occurredAt.isBefore(end!)),
        )
        .toList();
    final shownTotal = entries.fold(0, (t, e) => t + e.amount.minor);
    String? lastDate;
    return PageBody(
      children: [
        Text('Activity', style: context.text.headlineMedium),
        _ActivitySummary(
          count: entries.length,
          total: Money(shownTotal, p.currency).formatted,
        ),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  start == null
                      ? 'All dates'
                      : rangeLabel(CalendarRange(start!, end!), p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () async {
                  final selected = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1970),
                    lastDate: DateTime(2200),
                  );
                  if (selected != null) {
                    final loc = tz.getLocation(p.timezone);
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
            ),
            if (start != null || category != null) ...[
              const SizedBox(width: Brand.sm),
              TextButton(
                onPressed: () => setState(() {
                  start = null;
                  end = null;
                  category = null;
                }),
                child: const Text('Clear'),
              ),
            ],
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
            action: d.expenses.isEmpty
                ? FilledButton.icon(
                    onPressed: () => context.push('/expenses/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add expense'),
                  )
                : null,
          )
        else
          for (final e in entries) ...[
            if (lastDate != localDate(e.occurredAt, p))
              Padding(
                padding: const EdgeInsets.only(top: Brand.sm, bottom: Brand.xs),
                child: Text(
                  lastDate = localDate(e.occurredAt, p),
                  style: context.text.labelLarge?.copyWith(color: Brand.muted),
                ),
              ),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Brand.md,
                vertical: Brand.xs,
              ),
              child: ExpenseTile(expense: e, data: d),
            ),
          ],
      ],
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.count, required this.total});
  final int count;
  final String total;
  @override
  Widget build(BuildContext context) => HeroCard(
    // Compact single-row summary — deliberately not the full Home hero.
    padding: const EdgeInsets.symmetric(
      horizontal: Brand.xl,
      vertical: Brand.lg,
    ),
    child: Row(
      children: [
        const Icon(Icons.receipt_long, color: Brand.wheat, size: 24),
        const SizedBox(width: Brand.md),
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'expense' : 'expenses'} shown',
            style: context.text.bodyMedium?.copyWith(
              color: context.tokens.onHeroMuted,
            ),
          ),
        ),
        const SizedBox(width: Brand.sm),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              total,
              style: context.text.titleLarge?.copyWith(color: Brand.hay),
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Insights
// ---------------------------------------------------------------------------

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
    final p = d.profile!;
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
        Text('Spending insights', style: context.text.headlineMedium),
        Text(
          'See where your money goes.',
          style: context.text.bodyLarge?.copyWith(color: Brand.muted),
        ),
        _PeriodSelector(
          period: period,
          onChanged: (p) => setState(() => period = p),
        ),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Previous period',
              onPressed: () => navigate(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                rangeLabel(r, p),
                textAlign: TextAlign.center,
                style: context.text.labelLarge,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Next period',
              onPressed: () => navigate(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        _InsightsSummary(
          period: period,
          total: Money(total, p.currency).formatted,
          count: d.expenses
              .where(
                (e) =>
                    !e.occurredAt.isBefore(r.start) &&
                    e.occurredAt.isBefore(r.end),
              )
              .length,
        ),
        if (total == 0)
          const EmptyState(
            title: 'A fresh page',
            message: 'There are no expenses in this period.',
          )
        else
          _CategoryVisual(shares: shares, total: total, currency: p.currency),
        for (var i = 0; i < shares.length; i++)
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Brand.lg,
              vertical: Brand.md,
            ),
            onTap: () => context.go(
              Uri(
                path: '/activity',
                queryParameters: {
                  'category': shares[i].category.id,
                  'start': r.start.toIso8601String(),
                  'end': r.end.toIso8601String(),
                },
              ).toString(),
            ),
            child: _CategoryRow(
              name:
                  '${shares[i].category.name}${shares[i].category.archived ? ' (archived)' : ''}',
              iconKey: shares[i].category.icon,
              colorKey: shares[i].category.color,
              chartColor: _chartColors[i % _chartColors.length],
              amount: Money(shares[i].amount, p.currency).formatted,
              fraction: shares[i].amount / total,
            ),
          ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});
  final Period period;
  final ValueChanged<Period> onChanged;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(Brand.xs),
    child: Row(
      children: [
        for (final pr in Period.values)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(pr),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: Brand.md),
                decoration: BoxDecoration(
                  color: pr == period ? Brand.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(Brand.md),
                ),
                child: Text(
                  '${pr.name[0].toUpperCase()}${pr.name.substring(1)}',
                  textAlign: TextAlign.center,
                  style: context.text.labelLarge?.copyWith(
                    color: pr == period
                        ? Colors.white
                        : context.scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _InsightsSummary extends StatelessWidget {
  const _InsightsSummary({
    required this.period,
    required this.total,
    required this.count,
  });
  final Period period;
  final String total;
  final int count;
  @override
  Widget build(BuildContext context) => HeroCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${period.name[0].toUpperCase()}${period.name.substring(1)} · $count ${count == 1 ? 'transaction' : 'transactions'}',
          style: context.text.bodyMedium?.copyWith(
            color: context.tokens.onHeroMuted,
          ),
        ),
        const SizedBox(height: Brand.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            total,
            style: context.text.displaySmall?.copyWith(color: Brand.hay),
          ),
        ),
      ],
    ),
  );
}

/// Doughnut for 2+ categories; a single horizontal bar for one category.
class _CategoryVisual extends StatelessWidget {
  const _CategoryVisual({
    required this.shares,
    required this.total,
    required this.currency,
  });
  final List<({Category category, int amount})> shares;
  final int total;
  final String currency;
  @override
  Widget build(BuildContext context) {
    if (shares.length == 1) {
      final s = shares.first;
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryAvatar(
                  iconKey: s.category.icon,
                  colorKey: s.category.color,
                ),
                const SizedBox(width: Brand.md),
                Expanded(
                  child: Text(s.category.name, style: context.text.titleMedium),
                ),
                Text('100%', style: context.text.titleMedium),
              ],
            ),
            const SizedBox(height: Brand.lg),
            _ProgressBar(
              fraction: 1,
              color: categoryColor(s.category.color),
              track: context.tokens.track,
              label: '${s.category.name} share',
              value: '100%',
              height: 14,
            ),
            const SizedBox(height: Brand.md),
            Text(
              'All spending this period is in ${s.category.name}.',
              style: context.text.bodyMedium?.copyWith(color: Brand.muted),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Semantics(
              label: 'Spending by category. Exact amounts are listed below.',
              child: ExcludeSemantics(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 62,
                    sectionsSpace: 3,
                    sections: [
                      for (var i = 0; i < shares.length; i++)
                        PieChartSectionData(
                          value: shares[i].amount.toDouble(),
                          color: _chartColors[i % _chartColors.length],
                          radius: 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: context.text.labelMedium?.copyWith(color: Brand.muted),
                ),
                Text(
                  Money(total, currency).formatted,
                  style: context.text.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.iconKey,
    required this.colorKey,
    required this.chartColor,
    required this.amount,
    required this.fraction,
  });
  final String name, iconKey, colorKey, amount;
  final Color chartColor;
  final double fraction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CategoryAvatar(iconKey: iconKey, colorKey: colorKey, size: 40),
      const SizedBox(width: Brand.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(amount, style: context.text.bodyLarge),
              ],
            ),
            const SizedBox(height: Brand.sm),
            Row(
              children: [
                Expanded(
                  child: _ProgressBar(
                    fraction: fraction,
                    color: chartColor,
                    track: context.tokens.track,
                    label: '$name share',
                    value: '${(fraction * 100).toStringAsFixed(0)}%',
                    height: 8,
                  ),
                ),
                const SizedBox(width: Brand.sm),
                Text(
                  '${(fraction * 100).toStringAsFixed(0)}%',
                  style: context.text.labelMedium?.copyWith(color: Brand.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Budget
// ---------------------------------------------------------------------------

Widget budgetScreen(BuildContext context, LedgerSnapshot d) => PageBody(
  children: [
    Text('Your budgets', style: context.text.headlineMedium),
    Text(
      'Stay on top of your spending. Weekly and monthly caps work independently.',
      style: context.text.bodyLarge?.copyWith(color: Brand.muted),
    ),
    for (final period in ['week', 'month'])
      BudgetCard(
        data: d,
        period: period,
        budget: d.budgets.where((b) => b.period == period).firstOrNull,
      ),
    if (d.alerts.isNotEmpty)
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This period’s signals', style: context.text.titleLarge),
            const SizedBox(height: Brand.xs),
            Text(
              'Milestones reached this period. Current usage reflects edits and deletions.',
              style: context.text.bodyMedium?.copyWith(color: Brand.muted),
            ),
            const SizedBox(height: Brand.sm),
            for (final a in d.alerts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Brand.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: Brand.forest,
                    ),
                    const SizedBox(width: Brand.md),
                    Expanded(child: Text(a)),
                  ],
                ),
              ),
          ],
        ),
      ),
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
    final p = data.profile!;
    final range = rangeFor(data, period == 'week' ? Period.week : Period.month);
    final spent = data.total(range.start, range.end);
    final cap = budget?.amount.minor;
    final remaining = (cap ?? 0) - spent;
    final pct = (cap == null || cap == 0) ? 0.0 : spent * 100 / cap;
    final over = remaining < 0;
    final title = period == 'week' ? 'Weekly budget' : 'Monthly budget';

    if (cap == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Brand.forest,
                ),
                const SizedBox(width: Brand.sm),
                Expanded(child: Text(title, style: context.text.titleMedium)),
              ],
            ),
            const SizedBox(height: Brand.sm),
            Text(
              'Set your ${period == 'week' ? 'weekly' : 'monthly'} budget — give yourself a comfortable limit.',
              style: context.text.bodyMedium?.copyWith(color: Brand.muted),
            ),
            const SizedBox(height: Brand.lg),
            FilledButton(
              onPressed: () => context.push('/budget/$period/edit'),
              child: const Text('Set budget'),
            ),
          ],
        ),
      );
    }

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleMedium?.copyWith(color: Brand.hay),
                ),
              ),
              _Pill(label: rangeLabelShort(range, p)),
            ],
          ),
          const SizedBox(height: Brand.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${Money(remaining.abs(), p.currency).formatted} ${over ? 'over' : 'left'}',
              style: context.text.headlineMedium?.copyWith(color: Brand.wheat),
            ),
          ),
          const SizedBox(height: Brand.lg),
          _ProgressBar(
            fraction: (pct / 100).clamp(0, 1).toDouble(),
            color: over ? Brand.cherry : Brand.wheat,
            track: Colors.white.withValues(alpha: .14),
            label: 'Budget used',
            value: '${pct.toStringAsFixed(0)}%',
            height: 12,
          ),
          const SizedBox(height: Brand.md),
          Text(
            '${Money(spent, p.currency).formatted} of ${budget!.amount.formatted} · ${pct.toStringAsFixed(0)}% used',
            style: context.text.bodyMedium?.copyWith(
              color: context.tokens.onHeroMuted,
            ),
          ),
          if (over) ...[
            const SizedBox(height: Brand.xs),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Brand.cherry,
                  size: 18,
                ),
                const SizedBox(width: Brand.sm),
                Expanded(
                  child: Text(
                    'Over budget by ${Money(remaining.abs(), p.currency).formatted}.',
                    style: context.text.labelLarge?.copyWith(
                      color: Brand.wheat,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Brand.lg),
          OutlinedButton(
            onPressed: () => context.push('/budget/$period/edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Brand.hay,
              side: BorderSide(color: Colors.white.withValues(alpha: .24)),
            ),
            child: const Text('Edit cap'),
          ),
        ],
      ),
    );
  }
}

String rangeLabelShort(CalendarRange r, Profile p) => DateFormat(
  'd MMM',
).format(tz.TZDateTime.from(r.start, tz.getLocation(p.timezone)));
