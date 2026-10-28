import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/core/time/period.dart';
import 'package:money_well_spent/features/ledger/category_share.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'ledger_fixtures.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  final range = CalendarRange(DateTime.utc(2026, 3, 2), DateTime.utc(2026, 3, 9));
  DateTime inRange(int day) => DateTime.utc(2026, 3, day, 12);

  test('orders categories by spend, largest first', () {
    final shares = CategoryShare.within(
      testSnapshot(
        expenses: [
          testExpense(
            id: '1',
            minor: 1000,
            categoryId: 'c1',
            occurredAt: inRange(3),
          ),
          testExpense(
            id: '2',
            minor: 4000,
            categoryId: 'c2',
            occurredAt: inRange(4),
          ),
        ],
      ),
      range,
    );
    expect(shares.map((s) => s.category.id), ['c2', 'c1']);
    expect(shares.map((s) => s.amount), [4000, 1000]);
  });

  test('omits categories with nothing spent', () {
    final shares = CategoryShare.within(
      testSnapshot(
        expenses: [
          testExpense(
            id: '1',
            minor: 1000,
            categoryId: 'c1',
            occurredAt: inRange(3),
          ),
        ],
      ),
      range,
    );
    expect(shares, hasLength(1));
    expect(shares.single.category.id, 'c1');
  });

  test('ignores spending outside the range', () {
    final shares = CategoryShare.within(
      testSnapshot(
        expenses: [
          testExpense(
            id: 'before',
            minor: 1000,
            categoryId: 'c1',
            occurredAt: DateTime.utc(2026, 3, 1, 23),
          ),
          testExpense(
            id: 'after',
            minor: 1000,
            categoryId: 'c2',
            occurredAt: DateTime.utc(2026, 3, 9),
          ),
        ],
      ),
      range,
    );
    expect(shares, isEmpty);
  });

  test('fractions and labels reflect the period total', () {
    final shares = CategoryShare.within(
      testSnapshot(
        expenses: [
          testExpense(
            id: '1',
            minor: 7500,
            categoryId: 'c1',
            occurredAt: inRange(3),
          ),
          testExpense(
            id: '2',
            minor: 2500,
            categoryId: 'c2',
            occurredAt: inRange(4),
          ),
        ],
      ),
      range,
    );
    expect(shares.first.fraction, 0.75);
    expect(shares.first.percentLabel, '75%');
    expect(shares.first.money.formatted, 'USD 75.00');
    expect(shares.last.percentLabel, '25%');
  });

  test('marks archived categories in the label', () {
    final shares = CategoryShare.within(
      testSnapshot(
        categories: [
          testCategory('c1', 'Old hobby', system: false, archived: true),
        ],
        expenses: [
          testExpense(
            id: '1',
            minor: 500,
            categoryId: 'c1',
            occurredAt: inRange(3),
          ),
        ],
      ),
      range,
    );
    expect(shares.single.label, 'Old hobby (archived)');
  });
}
