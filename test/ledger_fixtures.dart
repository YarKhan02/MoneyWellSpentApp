import 'package:money_well_spent/core/money/money.dart';
import 'package:money_well_spent/features/ledger/models.dart';

/// Builders for in-memory ledger snapshots, so the pure-logic tests do not
/// need a database.

Profile testProfile({
  String currency = 'USD',
  String timezone = 'UTC',
  int weekStart = DateTime.monday,
  bool budgetSignals = true,
}) => Profile(
  currency,
  timezone,
  weekStart,
  budgetSignals: budgetSignals,
);

Category testCategory(
  String id,
  String name, {
  bool system = true,
  bool archived = false,
}) => Category(id, name, '0', 'forest', system, archived);

Expense testExpense({
  required String id,
  required int minor,
  required String categoryId,
  required DateTime occurredAt,
  String currency = 'USD',
  String note = '',
}) => Expense(
  id: id,
  amount: Money(minor, currency),
  categoryId: categoryId,
  note: note,
  occurredAt: occurredAt,
  createdAt: occurredAt,
  updatedAt: occurredAt,
);

LedgerSnapshot testSnapshot({
  Profile? profile,
  List<Category>? categories,
  List<Expense> expenses = const [],
  List<Budget> budgets = const [],
  List<String> alerts = const [],
}) => LedgerSnapshot(
  profile ?? testProfile(),
  categories ?? [testCategory('c1', 'Food'), testCategory('c2', 'Transport')],
  expenses,
  budgets,
  alerts,
);
