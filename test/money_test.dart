import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/core/money/money.dart';

void main() {
  test('0, 2 and 3 decimal currencies are exact', () {
    expect(Money.parse('123', 'JPY').minor, 123);
    expect(Money.parse('0.29', 'USD').minor, 29);
    expect(Money.parse('12.345', 'KWD').minor, 12345);
    expect(Money.parse('12.3', 'KWD').decimal, '12.300');
    expect(const Money(-123, 'USD').decimal, '-1.23');
  });
  test('invalid, zero, negative, excess precision and overflow fail', () {
    for (final value in [
      '0',
      '-1',
      '1.001',
      '1e3',
      'NaN',
      '1,000',
      '.',
      '9000000000000.01',
    ]) {
      expect(() => Money.parse(value, 'USD'), throwsFormatException);
    }
    expect(() => Money.parse('1.0', 'JPY'), throwsFormatException);
    expect(() => Money.parse('1', 'XXX'), throwsFormatException);
    expect(Money.parse('9000000000000.00', 'USD').minor, Money.maxMinor);
  });
}
