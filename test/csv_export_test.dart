import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/features/ledger/csv_export.dart';

import 'ledger_fixtures.dart';

void main() {
  test('neutralises spreadsheet formula injection', () {
    expect(csvCell('=SUM(A1:A9)'), '"\'=SUM(A1:A9)"');
    expect(csvCell('+1'), '"\'+1"');
    expect(csvCell('@cmd'), '"\'@cmd"');
    expect(csvCell('-5'), '"\'-5"');
  });

  test('escapes embedded quotes by doubling them', () {
    expect(csvCell('say "hi"'), '"say ""hi"""');
  });

  test('leaves ordinary values alone apart from quoting', () {
    expect(csvCell('Lunch'), '"Lunch"');
  });

  test('writes a header row and CRLF line endings', () {
    final csv = buildExpenseCsv(testSnapshot());
    expect(csv, '"${csvHeader.join('","')}"\r\n');
  });

  test('exports exact minor units alongside the decimal rendering', () {
    final csv = buildExpenseCsv(
      testSnapshot(
        expenses: [
          testExpense(
            id: 'e1',
            minor: 125000,
            categoryId: 'c1',
            occurredAt: DateTime.utc(2026, 3, 4, 9, 30),
            note: 'Lunch',
          ),
        ],
      ),
    );
    final row = csv.split('\r\n')[1];
    expect(row, contains('"125000"'));
    expect(row, contains('"1250.00"'));
    expect(row, contains('"USD"'));
    expect(row, contains('"Food"'));
    expect(row, contains('"Lunch"'));
    expect(row, contains('"2026-03-04T09:30:00.000000Z"'));
  });
}
