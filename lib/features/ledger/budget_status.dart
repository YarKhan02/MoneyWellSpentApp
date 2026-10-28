import '../../core/money/money.dart';
import '../../core/time/period.dart';
import 'formatting.dart';
import 'models.dart';

/// Everything a screen needs to render one budget period, computed once.
///
/// This used to be recalculated inline in three different `build` methods;
/// keeping it here makes the arithmetic unit-testable and guarantees the
/// home, budget and hero surfaces can never disagree.
class BudgetStatus {
  const BudgetStatus({
    required this.periodType,
    required this.range,
    required this.spent,
    required this.cap,
    required this.currency,
  });

  /// Reads the active budget for [periodType] (`week` or `month`) out of
  /// [data] and totals the spending that falls inside the current window.
  factory BudgetStatus.of(LedgerSnapshot data, String periodType) {
    final profile = data.profile!;
    final window = profile.range(
      periodType == 'week' ? Period.week : Period.month,
    );
    final budget = data.budgets
        .where((b) => b.period == periodType)
        .firstOrNull;
    return BudgetStatus(
      periodType: periodType,
      range: window,
      spent: data.total(window.start, window.end),
      cap: budget?.amount.minor,
      currency: profile.currency,
    );
  }

  /// `week` or `month`.
  final String periodType;
  final CalendarRange range;
  final int spent;

  /// Null when no cap has been set for this period.
  final int? cap;
  final String currency;

  bool get hasCap => cap != null;

  /// `Weekly budget` / `Monthly budget`.
  String get title => periodType == 'week' ? 'Weekly budget' : 'Monthly budget';

  /// `weekly` / `monthly`, for mid-sentence use.
  String get adjective => periodType == 'week' ? 'weekly' : 'monthly';

  /// Negative once spending passes the cap.
  int get remaining => (cap ?? 0) - spent;
  bool get over => hasCap && remaining < 0;

  /// 0–1, for progress bars. Zero when there is no cap.
  double get fraction =>
      (cap == null || cap == 0) ? 0 : (spent / cap!).clamp(0, 1).toDouble();

  /// Uncapped percentage — can exceed 100 when over budget.
  double get percentUsed => (cap == null || cap == 0) ? 0 : spent * 100 / cap!;

  /// Clamped 0–100 share of the cap still available.
  double get percentRemaining => (cap == null || cap == 0)
      ? 0
      : (remaining * 100 / cap!).clamp(0, 100).toDouble();

  String get percentUsedLabel => '${percentUsed.toStringAsFixed(0)}%';
  String get percentRemainingLabel =>
      '${percentRemaining.toStringAsFixed(0)}% left';

  Money get spentMoney => Money(spent, currency);

  /// Absolute distance from the cap — read as "left" or "over" by the caller.
  Money get remainingMoney => Money(remaining.abs(), currency);
  Money? get capMoney => cap == null ? null : Money(cap!, currency);
}
