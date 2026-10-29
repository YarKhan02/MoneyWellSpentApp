import '../../core/money/money.dart';
import '../../core/time/period.dart';
import 'models.dart';

/// One category's slice of spending within a period.
class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.amount,
    required this.total,
    required this.currency,
  });

  final Category category;
  final int amount;

  /// Period total across all categories — the denominator for [fraction].
  final int total;
  final String currency;

  double get fraction => total == 0 ? 0 : amount / total;
  String get percentLabel => '${(fraction * 100).toStringAsFixed(0)}%';
  Money get money => Money(amount, currency);

  /// Category name, flagged when the category has been archived.
  String get label =>
      '${category.name}${category.archived ? ' (archived)' : ''}';

  /// Every category with spending inside [range], largest first.
  /// Categories with nothing spent are omitted.
  static List<CategoryShare> within(LedgerSnapshot data, CalendarRange range) {
    final total = data.total(range.start, range.end);
    final shares = <CategoryShare>[];
    for (final category in data.categories) {
      final amount = data.total(range.start, range.end, category: category.id);
      if (amount > 0) {
        shares.add(
          CategoryShare(
            category: category,
            amount: amount,
            total: total,
            currency: data.profile!.currency,
          ),
        );
      }
    }
    shares.sort((a, b) => b.amount.compareTo(a.amount));
    return shares;
  }
}
