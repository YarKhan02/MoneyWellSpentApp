/// Period-over-period change, used by the home hero.
class SpendingComparison {
  const SpendingComparison({required this.current, required this.previous});

  final int current, previous;

  /// Null when there is no prior spending to compare against — showing
  /// "+100%" against an empty first month would be misleading.
  double? get changePercent =>
      previous > 0 ? (current - previous) * 100 / previous : null;

  bool get hasChange => changePercent != null;
  bool get increased => (changePercent ?? 0) > 0;

  /// e.g. `▲ 12% vs last month`.
  String label(String comparedTo) {
    final change = changePercent;
    if (change == null) return '';
    return '${change >= 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(0)}% vs $comparedTo';
  }
}
