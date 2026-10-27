import '../../core/money/money.dart';

class Profile {
  const Profile(
    this.currency,
    this.timezone,
    this.weekStart, {
    this.reduceMotion = false,
    this.reduceTransparency = false,
    this.budgetSignals = true,
  });
  final String currency;
  final String timezone;
  final int weekStart;
  final bool reduceMotion;
  final bool reduceTransparency;
  final bool budgetSignals;
}

class Category {
  const Category(
    this.id,
    this.name,
    this.icon,
    this.color,
    this.system,
    this.archived,
  );
  final String id, name, icon, color;
  final bool system, archived;
}

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, categoryId, note;
  final Money amount;
  final DateTime occurredAt, createdAt, updatedAt;
}

class Budget {
  const Budget(this.id, this.period, this.amount, this.updatedAt);
  final String id, period;
  final Money amount;
  final DateTime updatedAt;
}

class LedgerSnapshot {
  const LedgerSnapshot(
    this.profile,
    this.categories,
    this.expenses,
    this.budgets,
    this.alerts,
  );
  final Profile? profile;
  final List<Category> categories;
  final List<Expense> expenses;
  final List<Budget> budgets;
  final List<String> alerts;
  Category category(String id) => categories.firstWhere((c) => c.id == id);
  int total(DateTime start, DateTime end, {String? category}) => expenses
      .where(
        (e) =>
            !e.occurredAt.isBefore(start) &&
            e.occurredAt.isBefore(end) &&
            (category == null || e.categoryId == category),
      )
      .fold(0, (total, e) => total + e.amount.minor);
}
