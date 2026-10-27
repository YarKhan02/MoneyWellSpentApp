/// Exact minor-unit arithmetic. Currency support is explicit: unknown codes fail.
class Money {
  const Money(this.minor, this.currency);

  static const maxMinor = 900000000000000;
  static const exponents = <String, int>{
    'USD': 2,
    'EUR': 2,
    'GBP': 2,
    'PKR': 2,
    'INR': 2,
    'SAR': 2,
    'AED': 2,
    'CAD': 2,
    'AUD': 2,
    'CHF': 2,
    'CNY': 2,
    'SGD': 2,
    'JPY': 0,
    'KRW': 0,
    'VND': 0,
    'CLP': 0,
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
    'JOD': 3,
    'TND': 3,
  };
  final int minor;
  final String currency;

  static int exponent(String code) =>
      exponents[code] ??
      (throw const FormatException('Choose a supported currency.'));

  static Money parse(String text, String code) {
    final digits = exponent(code);
    final value = text.trim();
    final pattern = digits == 0
        ? RegExp(r'^\d+$')
        : RegExp('^\\d+(?:\\.\\d{1,$digits})?\$');
    if (!pattern.hasMatch(value)) {
      throw FormatException(
        'Enter a positive amount with up to $digits decimals.',
      );
    }
    final parts = value.split('.');
    final fraction = parts.length == 2
        ? parts[1].padRight(digits, '0')
        : '0' * digits;
    final amount = BigInt.parse('${parts[0]}$fraction');
    if (amount <= BigInt.zero || amount > BigInt.from(maxMinor)) {
      throw const FormatException(
        'Amount must be positive and within the supported limit.',
      );
    }
    return Money(amount.toInt(), code);
  }

  String get decimal {
    final digits = exponent(currency);
    final raw = minor.abs().toString().padLeft(digits + 1, '0');
    final sign = minor < 0 ? '-' : '';
    if (digits == 0) return '$sign$raw';
    return '$sign${raw.substring(0, raw.length - digits)}.${raw.substring(raw.length - digits)}';
  }

  String get formatted => '$currency $decimal';
}
