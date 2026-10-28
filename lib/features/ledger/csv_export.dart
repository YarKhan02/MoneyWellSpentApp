import '../../core/time/period.dart';
import 'models.dart';

/// Column order of the v1 export. Changing it is a schema change for anyone
/// who has built a spreadsheet on top of an earlier export.
const csvHeader = [
  'schema_version',
  'id',
  'amount_minor',
  'amount',
  'currency',
  'category',
  'note',
  'occurred_at_utc',
  'created_at_utc',
  'updated_at_utc',
];

/// Renders active expenses as RFC-4180 CSV with CRLF line endings.
///
/// Exact minor units are exported alongside the decimal rendering so no
/// precision is lost, and timestamps stay UTC.
String buildExpenseCsv(LedgerSnapshot data) {
  final lines = <List<String>>[
    csvHeader,
    for (final e in data.expenses)
      [
        '1',
        e.id,
        '${e.amount.minor}',
        e.amount.decimal,
        e.amount.currency,
        data.category(e.categoryId).name,
        e.note,
        utcStamp(e.occurredAt),
        utcStamp(e.createdAt),
        utcStamp(e.updatedAt),
      ],
  ];
  return '${lines.map((row) => row.map(csvCell).join(',')).join('\r\n')}\r\n';
}

/// Quotes a value and neutralises spreadsheet formula injection: a leading
/// `=`, `+`, `@`, `-`, tab or CR is prefixed with an apostrophe so Excel and
/// Sheets treat the cell as text.
String csvCell(String value) {
  final protected = RegExp(r'^\s*[=+@\-\t\r]').hasMatch(value)
      ? "'$value"
      : value;
  return '"${protected.replaceAll('"', '""')}"';
}
