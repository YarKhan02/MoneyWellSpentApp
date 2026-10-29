import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/money/money.dart';
import '../../core/storage/database.dart';
import 'budget_alerts.dart';
import 'csv_export.dart';
import 'ledger_reader.dart';
import 'models.dart';
import 'writers/budget_writer.dart';
import 'writers/category_writer.dart';
import 'writers/expense_writer.dart';
import 'writers/profile_writer.dart';

/// The app's single entry point to local storage.
///
/// Reads go through [LedgerReader], writes through the `writers/`
/// collaborators, and budget milestones through [BudgetAlerts]. This class
/// owns only the two things those pieces must not: the transaction boundary
/// around every mutation, and the change stream the UI watches.
class LedgerRepository {
  LedgerRepository(this.db, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now {
    _reader = LedgerReader(db, this.clock);
    _alerts = BudgetAlerts(db, this.clock);
    _profiles = ProfileWriter(db, this.clock);
    _expenses = ExpenseWriter(db, this.clock);
    _categories = CategoryWriter(db, this.clock);
    _budgets = BudgetWriter(db, this.clock);
  }

  final AppDatabase db;
  final DateTime Function() clock;

  late final LedgerReader _reader;
  late final BudgetAlerts _alerts;
  late final ProfileWriter _profiles;
  late final ExpenseWriter _expenses;
  late final CategoryWriter _categories;
  late final BudgetWriter _budgets;

  final _changes = StreamController<void>.broadcast();
  static const _uuid = Uuid();

  /// Time-ordered v7 UUID, so inserts stay roughly sequential on disk.
  String newId() => _uuid.v7();

  // ---- Reading -----------------------------------------------------------

  /// A fresh snapshot on subscribe, then one after every mutation.
  Stream<LedgerSnapshot> watch() async* {
    // Subscribe before the initial read so writes during bootstrap aren't lost.
    final pending = StreamController<void>();
    final subscription = _changes.stream.listen(pending.add);
    try {
      yield await snapshot();
      await for (final _ in pending.stream) {
        yield await snapshot();
      }
    } finally {
      await subscription.cancel();
      await pending.close();
    }
  }

  Future<LedgerSnapshot> snapshot() => db.transaction(_reader.read);

  // ---- Writing -----------------------------------------------------------

  Future<void> saveProfile(
    String currency,
    String timezone,
    int weekStart, {
    bool reduceMotion = false,
    bool reduceTransparency = false,
    bool budgetSignals = true,
  }) => _mutate(
    () => _profiles.save(
      currency,
      timezone,
      weekStart,
      reduceMotion: reduceMotion,
      reduceTransparency: reduceTransparency,
      budgetSignals: budgetSignals,
    ),
  );

  Future<void> saveExpense({
    required String id,
    required Money amount,
    required String categoryId,
    required String note,
    required DateTime occurredAt,
    bool editing = false,
  }) => _mutate(
    () => _expenses.save(
      id: id,
      amount: amount,
      categoryId: categoryId,
      note: note,
      occurredAt: occurredAt,
      editing: editing,
    ),
  );

  Future<void> deleteExpense(String id) =>
      _mutate(() => _expenses.softDelete(id));

  Future<void> undoDelete(String id) => _mutate(() => _expenses.restore(id));

  Future<void> saveCategory({
    String? id,
    required String name,
    String icon = '7',
    String color = 'forest',
  }) => _mutate(
    () => _categories.save(
      id: id,
      name: name,
      icon: icon,
      color: color,
      newId: newId,
    ),
  );

  Future<void> archiveCategory(String id, bool archived) =>
      _mutate(() => _categories.archive(id, archived));

  Future<void> saveBudget(String period, Money amount) =>
      _mutate(() => _budgets.save(period, amount, newId: newId));

  Future<void> removeBudget(String id) => _mutate(() => _budgets.remove(id));

  /// Re-checks budget milestones after a period boundary has passed.
  Future<void> refreshCalendar() => _mutate(() async {});

  /// Runs [operation] and the threshold pass in one transaction, then tells
  /// watchers. If anything throws, nothing is committed.
  Future<void> _mutate(Future<void> Function() operation) async {
    await db.transaction(() async {
      await operation();
      await _alerts.record();
    });
    _changes.add(null);
  }

  // ---- Export and erase --------------------------------------------------

  /// Active expenses as CSV. An export, not a restorable backup.
  Future<String> exportCsv() async => buildExpenseCsv(await snapshot());

  /// Permanently clears the book. [confirmation] must be the literal `ERASE`.
  Future<void> erase(String confirmation) async {
    if (confirmation != 'ERASE') {
      throw const FormatException('Type ERASE to confirm.');
    }
    await db.transaction(() async {
      for (final table in [
        'alert_deliveries',
        'budgets',
        'expenses',
        'local_profile',
      ]) {
        // Fixed table allowlist, never user input.
        await db.customStatement('DELETE FROM $table');
      }
      await db.customStatement('DELETE FROM categories WHERE is_system=0');
    });
    _changes.add(null);
  }

  Future<void> close() async {
    await _changes.close();
    await db.close();
  }
}
