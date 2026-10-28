import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/features/ledger/spending_comparison.dart';

void main() {
  test('reports no change when there is no prior spending', () {
    const fresh = SpendingComparison(current: 5000, previous: 0);
    expect(fresh.changePercent, isNull);
    expect(fresh.hasChange, isFalse);
    expect(fresh.label('last month'), '');
  });

  test('computes an increase', () {
    const up = SpendingComparison(current: 12000, previous: 10000);
    expect(up.changePercent, 20);
    expect(up.increased, isTrue);
    expect(up.label('last month'), '▲ 20% vs last month');
  });

  test('computes a decrease', () {
    const down = SpendingComparison(current: 7500, previous: 10000);
    expect(down.changePercent, -25);
    expect(down.increased, isFalse);
    expect(down.label('last month'), '▼ 25% vs last month');
  });

  test('flat spending is shown as an unchanged up-arrow, not a drop', () {
    const flat = SpendingComparison(current: 10000, previous: 10000);
    expect(flat.increased, isFalse);
    expect(flat.label('last month'), '▲ 0% vs last month');
  });
}
