import 'package:timezone/timezone.dart' as tz;
import '../../../core/money/money.dart';
import '../sql_access.dart';
import 'ledger_writer.dart';

/// Creates or updates the single local profile row.
class ProfileWriter extends LedgerWriter {
  const ProfileWriter(super.db, super.clock);

  Future<void> save(
    String currency,
    String timezone,
    int weekStart, {
    required bool reduceMotion,
    required bool reduceTransparency,
    required bool budgetSignals,
  }) async {
    Money.exponent(currency);
    tz.getLocation(timezone);
    if (weekStart < 1 || weekStart > 7) {
      throw const FormatException('Choose a valid week start.');
    }
    await _guardCurrencyLock(currency);
    await db.customStatement(
      '''INSERT INTO local_profile(id,base_currency,timezone,week_start,reduce_motion,reduce_transparency,notifications,created_at_utc)
      VALUES('local',?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET base_currency=excluded.base_currency,
      timezone=excluded.timezone,week_start=excluded.week_start,reduce_motion=excluded.reduce_motion,
      reduce_transparency=excluded.reduce_transparency, notifications=excluded.notifications''',
      [
        currency,
        timezone,
        weekStart,
        reduceMotion ? 1 : 0,
        reduceTransparency ? 1 : 0,
        budgetSignals ? 1 : 0,
        now,
      ],
    );
  }

  /// Amounts are never converted or relabelled, so the book's currency is
  /// frozen as soon as any expense or budget exists.
  Future<void> _guardCurrencyLock(String currency) async {
    final old = await db.rows('SELECT base_currency FROM local_profile');
    if (old.isEmpty || old.single.read<String>('base_currency') == currency) {
      return;
    }
    final entries = await db.rows('SELECT id FROM expenses LIMIT 1');
    final caps = await db.rows(
      'SELECT id FROM budgets WHERE deleted_at_utc IS NULL LIMIT 1',
    );
    if (entries.isNotEmpty || caps.isNotEmpty) {
      throw const FormatException(
        'Currency is locked while expense history or budgets exist. Export and erase to start a new book.',
      );
    }
  }
}
