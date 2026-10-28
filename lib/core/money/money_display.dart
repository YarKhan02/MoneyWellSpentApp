import 'money.dart';

/// Display-only formatting for [Money].
///
/// Kept apart from [Money] itself on purpose: `Money.decimal` is the exact,
/// machine-readable rendering that the forms put into text controllers and
/// `Money.parse` reads back, and the CSV export writes. Adding grouping
/// separators there would break round-tripping. These helpers are for the
/// screen only.
extension MoneyDisplay on Money {
  /// `1250.00` → `1,250.00`.
  ///
  /// Works on the digit string, never on a double, so no precision is lost
  /// and no rounding is introduced.
  String get groupedDecimal {
    final raw = decimal;
    final negative = raw.startsWith('-');
    final body = negative ? raw.substring(1) : raw;
    final dot = body.indexOf('.');
    final whole = dot == -1 ? body : body.substring(0, dot);
    final fraction = dot == -1 ? '' : body.substring(dot);
    final grouped = whole.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '${negative ? '-' : ''}$grouped$fraction';
  }

  /// `PKR 1,250.00` — what a person reads.
  String get display => '$currency $groupedDecimal';
}
