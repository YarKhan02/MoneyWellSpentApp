import 'package:drift/drift.dart' show Variable;
import '../../../core/money/money.dart';
import '../sql_access.dart';
import 'ledger_writer.dart';

/// Sets and removes the weekly and monthly spending caps.
///
/// At most one active cap exists per period type — enforced by a partial
/// unique index — and removal is a soft delete, so expenses are untouched.
class BudgetWriter extends LedgerWriter {
  const BudgetWriter(super.db, super.clock);

  static const periods = ['week', 'month'];

  Future<void> save(
    String period,
    Money amount, {
    required String Function() newId,
  }) async {
    if (!periods.contains(period) ||
        amount.minor <= 0 ||
        amount.minor > Money.maxMinor) {
      throw const FormatException('Enter a valid weekly or monthly cap.');
    }
    final p = await db.rows('SELECT base_currency FROM local_profile');
    if (p.isEmpty ||
        p.single.read<String>('base_currency') != amount.currency) {
      throw const FormatException('Budget currency must match your book.');
    }
    final current = await db.rows(
      'SELECT id FROM budgets WHERE period_type=? AND deleted_at_utc IS NULL',
      [Variable(period)],
    );
    if (current.isEmpty) {
      await db.customStatement(
        'INSERT INTO budgets(id,period_type,amount_minor,currency_code,updated_at_utc) VALUES(?,?,?,?,?)',
        [newId(), period, amount.minor, amount.currency, now],
      );
    } else {
      await db.customStatement(
        'UPDATE budgets SET amount_minor=?,updated_at_utc=? WHERE id=?',
        [amount.minor, now, current.single.read<String>('id')],
      );
    }
  }

  Future<void> remove(String id) => db.customStatement(
    'UPDATE budgets SET deleted_at_utc=?,updated_at_utc=? WHERE id=?',
    [now, now, id],
  );
}
