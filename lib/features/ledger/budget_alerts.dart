import 'package:drift/drift.dart' show Variable;
import '../../core/storage/database.dart';
import '../../core/time/period.dart';
import 'models.dart';
import 'sql_access.dart';

/// Milestones a budget period can cross. Mirrors the CHECK constraint on
/// `alert_deliveries.threshold`.
const alertThresholds = [75, 90, 100];

/// Records and reads the in-app budget signals shown at 75%, 90% and 100%.
///
/// A milestone is recorded once per budget per period (the table's primary key
/// enforces it), so later edits or deletions never re-fire a signal.
class BudgetAlerts {
  const BudgetAlerts(this.db, this.clock);
  final AppDatabase db;
  final DateTime Function() clock;

  /// Re-evaluates every active budget and records any newly crossed
  /// milestone. Must run inside the caller's transaction.
  Future<void> record() async {
    final profiles = await db.rows('SELECT * FROM local_profile');
    if (profiles.isEmpty) return;
    final p = profiles.single;
    if (p.read<int>('notifications') == 0) return;

    for (final b in await db.rows(
      'SELECT * FROM budgets WHERE deleted_at_utc IS NULL',
    )) {
      final range = CalendarRange.containing(
        clock(),
        p.read<String>('timezone'),
        b.read<String>('period_type') == 'week' ? Period.week : Period.month,
        weekStart: p.read<int>('week_start'),
      );
      final rows = await db.rows(
        '''SELECT amount_minor FROM expenses WHERE deleted_at_utc IS NULL
        AND occurred_at_utc>=? AND occurred_at_utc<? AND currency_code=?''',
        [
          Variable(utcStamp(range.start)),
          Variable(utcStamp(range.end)),
          Variable(p.read<String>('base_currency')),
        ],
      );
      // Dart integers avoid SQLite SUM overflow for large ledgers.
      final total = rows.fold<BigInt>(
        BigInt.zero,
        (sum, r) => sum + BigInt.from(r.read<int>('amount_minor')),
      );
      final cap = BigInt.from(b.read<int>('amount_minor'));
      for (final threshold in alertThresholds) {
        if (total * BigInt.from(100) >= cap * BigInt.from(threshold)) {
          await db.customStatement(
            'INSERT OR IGNORE INTO alert_deliveries(budget_id,period_start,threshold,delivered_at_utc) VALUES(?,?,?,?)',
            [
              b.read<String>('id'),
              utcStamp(range.start),
              threshold,
              utcStamp(clock()),
            ],
          );
        }
      }
    }
  }

  /// Human-readable signals already recorded for the current period of each
  /// budget. Returns empty when the person has turned budget signals off.
  Future<List<String>> describe(Profile profile, List<Budget> budgets) async {
    if (!profile.budgetSignals) return const [];
    final messages = <String>[];
    for (final b in budgets) {
      final range = CalendarRange.containing(
        clock(),
        profile.timezone,
        b.period == 'week' ? Period.week : Period.month,
        weekStart: profile.weekStart,
      );
      final delivered = await db.rows(
        'SELECT threshold FROM alert_deliveries WHERE budget_id=? AND period_start=? ORDER BY threshold',
        [Variable(b.id), Variable(utcStamp(range.start))],
      );
      for (final r in delivered) {
        messages.add(
          '${b.period == 'week' ? 'Weekly' : 'Monthly'} budget reached ${r.read<int>('threshold')}% this period.',
        );
      }
    }
    return messages;
  }
}
