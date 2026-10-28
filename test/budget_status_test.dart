import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/core/money/money.dart';
import 'package:money_well_spent/core/time/period.dart';
import 'package:money_well_spent/features/ledger/budget_status.dart';
import 'package:money_well_spent/features/ledger/formatting.dart';
import 'package:money_well_spent/features/ledger/models.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'ledger_fixtures.dart';

BudgetStatus status({required int spent, int? cap}) => BudgetStatus(
  periodType: 'week',
  range: CalendarRange(DateTime.utc(2026, 3, 2), DateTime.utc(2026, 3, 9)),
  spent: spent,
  cap: cap,
  currency: 'USD',
);

void main() {
  setUpAll(tz.initializeTimeZones);

  group('without a cap', () {
    final none = status(spent: 5000);

    test('reports no cap and never counts as over budget', () {
      expect(none.hasCap, isFalse);
      expect(none.over, isFalse);
      expect(none.capMoney, isNull);
    });

    test('percentages stay at zero rather than dividing by null', () {
      expect(none.fraction, 0);
      expect(none.percentUsed, 0);
      expect(none.percentRemaining, 0);
    });
  });

  group('under a cap', () {
    final under = status(spent: 2500, cap: 10000);

    test('computes remaining, fraction and percentages', () {
      expect(under.remaining, 7500);
      expect(under.over, isFalse);
      expect(under.fraction, 0.25);
      expect(under.percentUsed, 25);
      expect(under.percentRemaining, 75);
    });

    test('formats money in the book currency', () {
      expect(under.spentMoney.formatted, 'USD 25.00');
      expect(under.remainingMoney.formatted, 'USD 75.00');
      expect(under.capMoney!.formatted, 'USD 100.00');
    });

    test('renders whole-number percentage labels', () {
      expect(under.percentUsedLabel, '25%');
      expect(under.percentRemainingLabel, '75% left');
    });
  });

  group('over a cap', () {
    final over = status(spent: 12000, cap: 10000);

    test('flags the overspend and reports it as a positive amount', () {
      expect(over.over, isTrue);
      expect(over.remaining, -2000);
      expect(over.remainingMoney.formatted, 'USD 20.00');
    });

    test('clamps the progress bar but not the reported percentage', () {
      expect(over.fraction, 1);
      expect(over.percentUsed, 120);
      expect(over.percentRemaining, 0);
    });
  });

  test('exactly at the cap is not over budget', () {
    final exact = status(spent: 10000, cap: 10000);
    expect(exact.over, isFalse);
    expect(exact.remaining, 0);
    expect(exact.fraction, 1);
    expect(exact.percentUsedLabel, '100%');
  });

  test('titles and adjectives match the period type', () {
    expect(status(spent: 0).title, 'Weekly budget');
    expect(status(spent: 0).adjective, 'weekly');
    final monthly = BudgetStatus(
      periodType: 'month',
      range: CalendarRange(DateTime.utc(2026, 3), DateTime.utc(2026, 4)),
      spent: 0,
      cap: null,
      currency: 'USD',
    );
    expect(monthly.title, 'Monthly budget');
    expect(monthly.adjective, 'monthly');
  });

  group('BudgetStatus.of', () {
    test('totals only spending inside the current week', () {
      final profile = testProfile();
      final week = profile.range(Period.week);
      final data = testSnapshot(
        profile: profile,
        expenses: [
          testExpense(
            id: 'in',
            minor: 3000,
            categoryId: 'c1',
            occurredAt: week.start.add(const Duration(hours: 1)),
          ),
          testExpense(
            id: 'before',
            minor: 9900,
            categoryId: 'c1',
            occurredAt: week.start.subtract(const Duration(hours: 1)),
          ),
          testExpense(
            id: 'after',
            minor: 9900,
            categoryId: 'c1',
            occurredAt: week.end.add(const Duration(hours: 1)),
          ),
        ],
        budgets: [
          Budget('b1', 'week', const Money(10000, 'USD'), DateTime.now()),
        ],
      );
      final weekly = BudgetStatus.of(data, 'week');
      expect(weekly.spent, 3000);
      expect(weekly.cap, 10000);
      expect(weekly.remaining, 7000);
    });

    test('reads no cap when the period has no budget', () {
      final weekly = BudgetStatus.of(testSnapshot(), 'week');
      expect(weekly.hasCap, isFalse);
      expect(weekly.spent, 0);
    });
  });
}
