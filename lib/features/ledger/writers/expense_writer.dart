import 'package:drift/drift.dart' show QueryRow, Variable;
import '../../../core/money/money.dart';
import '../../../core/time/period.dart';
import '../sql_access.dart';
import 'ledger_writer.dart';

/// Insert, update and soft-delete of expense records.
///
/// Nothing here ever hard-deletes: a removed expense keeps its row with
/// `deleted_at_utc` set, which is what makes Undo possible.
class ExpenseWriter extends LedgerWriter {
  const ExpenseWriter(super.db, super.clock);

  static const noteLimit = 280;

  Future<void> save({
    required String id,
    required Money amount,
    required String categoryId,
    required String note,
    required DateTime occurredAt,
    bool editing = false,
  }) async {
    if (amount.minor <= 0 || amount.minor > Money.maxMinor) {
      throw const FormatException('Enter a valid positive amount.');
    }
    final cleanNote = _sanitizeNote(note);
    await _guardCurrency(amount);
    final existing = await db.rows(
      'SELECT category_id,deleted_at_utc FROM expenses WHERE id=?',
      [Variable(id)],
    );
    await _guardCategory(categoryId, editing: editing, existing: existing);

    if (editing) {
      if (existing.isEmpty ||
          existing.single.readNullable<String>('deleted_at_utc') != null) {
        throw const FormatException('This expense no longer exists.');
      }
      await db.customStatement(
        'UPDATE expenses SET amount_minor=?,category_id=?,note=?,occurred_at_utc=?,updated_at_utc=? WHERE id=? AND deleted_at_utc IS NULL',
        [amount.minor, categoryId, cleanNote, utcStamp(occurredAt), now, id],
      );
    } else {
      // A repeated submission retains the original financial record.
      await db.customStatement(
        '''INSERT INTO expenses(id,amount_minor,currency_code,category_id,note,occurred_at_utc,created_at_utc,updated_at_utc)
        VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(id) DO NOTHING''',
        [
          id,
          amount.minor,
          amount.currency,
          categoryId,
          cleanNote,
          utcStamp(occurredAt),
          now,
          now,
        ],
      );
    }
  }

  Future<void> softDelete(String id) => db.customStatement(
    'UPDATE expenses SET deleted_at_utc=?,updated_at_utc=? WHERE id=? AND deleted_at_utc IS NULL',
    [now, now, id],
  );

  Future<void> restore(String id) => db.customStatement(
    'UPDATE expenses SET deleted_at_utc=NULL,updated_at_utc=? WHERE id=?',
    [now, id],
  );

  /// Strips control characters, trims, and enforces the stored length limit.
  String _sanitizeNote(String note) {
    final clean = note
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .trim();
    if (clean.runes.length > noteLimit) {
      throw const FormatException('Notes are limited to 280 characters.');
    }
    return clean;
  }

  Future<void> _guardCurrency(Money amount) async {
    final profile = await db.rows('SELECT base_currency FROM local_profile');
    if (profile.isEmpty ||
        profile.single.read<String>('base_currency') != amount.currency) {
      throw const FormatException('Expense currency must match your book.');
    }
  }

  /// An archived category stays selectable only for an expense that already
  /// used it, so historical entries keep their category on edit.
  Future<void> _guardCategory(
    String categoryId, {
    required bool editing,
    required List<QueryRow> existing,
  }) async {
    final category = await db.rows(
      'SELECT is_archived FROM categories WHERE id=?',
      [Variable(categoryId)],
    );
    final archived =
        category.isNotEmpty && category.single.read<int>('is_archived') == 1;
    final keepsOwnCategory =
        editing &&
        existing.isNotEmpty &&
        existing.single.read<String>('category_id') == categoryId;
    if (category.isEmpty || (archived && !keepsOwnCategory)) {
      throw const FormatException('Choose an active category.');
    }
  }
}
