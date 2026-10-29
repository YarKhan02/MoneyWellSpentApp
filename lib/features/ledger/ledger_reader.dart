import '../../core/storage/database.dart';
import 'budget_alerts.dart';
import 'mappers.dart';
import 'models.dart';
import 'sql_access.dart';

/// The read half of the ledger: one consistent snapshot of everything the UI
/// needs. Runs inside the caller's transaction so the four tables can never be
/// read mid-write.
class LedgerReader {
  LedgerReader(this.db, this.clock) : _alerts = BudgetAlerts(db, clock);
  final AppDatabase db;
  final DateTime Function() clock;
  final BudgetAlerts _alerts;

  Future<LedgerSnapshot> read() async {
    final profile = await _profile();
    final categories = await _categories();
    final expenses = await _expenses();
    final budgets = await _budgets();
    final alerts = profile == null
        ? const <String>[]
        : await _alerts.describe(profile, budgets);
    return LedgerSnapshot(profile, categories, expenses, budgets, alerts);
  }

  /// Null before onboarding completes — the app shows onboarding instead.
  Future<Profile?> _profile() async {
    final rows = await db.rows('SELECT * FROM local_profile');
    return rows.isEmpty ? null : profileFromRow(rows.single);
  }

  Future<List<Category>> _categories() async => (await db.rows(
    'SELECT * FROM categories ORDER BY is_system DESC, rowid',
  )).map(categoryFromRow).toList();

  /// Newest first. Soft-deleted rows are excluded but never removed.
  Future<List<Expense>> _expenses() async => (await db.rows(
    'SELECT * FROM expenses WHERE deleted_at_utc IS NULL ORDER BY occurred_at_utc DESC, id DESC',
  )).map(expenseFromRow).toList();

  Future<List<Budget>> _budgets() async => (await db.rows(
    'SELECT * FROM budgets WHERE deleted_at_utc IS NULL',
  )).map(budgetFromRow).toList();
}
