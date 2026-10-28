import 'package:drift/drift.dart' show QueryRow;
import '../../core/money/money.dart';
import 'models.dart';

/// Row → model mapping, kept in one place so the column names appear once.
/// A schema change touches this file and the schema, nothing else.

Profile profileFromRow(QueryRow r) => Profile(
  r.read<String>('base_currency'),
  r.read<String>('timezone'),
  r.read<int>('week_start'),
  reduceMotion: r.read<int>('reduce_motion') == 1,
  reduceTransparency: r.read<int>('reduce_transparency') == 1,
  budgetSignals: r.read<int>('notifications') == 1,
);

Category categoryFromRow(QueryRow r) => Category(
  r.read<String>('id'),
  r.read<String>('name'),
  r.read<String>('icon_key'),
  r.read<String>('color_key'),
  r.read<int>('is_system') == 1,
  r.read<int>('is_archived') == 1,
);

Expense expenseFromRow(QueryRow r) => Expense(
  id: r.read<String>('id'),
  amount: Money(r.read<int>('amount_minor'), r.read<String>('currency_code')),
  categoryId: r.read<String>('category_id'),
  note: r.read<String>('note'),
  occurredAt: DateTime.parse(r.read<String>('occurred_at_utc')),
  createdAt: DateTime.parse(r.read<String>('created_at_utc')),
  updatedAt: DateTime.parse(r.read<String>('updated_at_utc')),
);

Budget budgetFromRow(QueryRow r) => Budget(
  r.read<String>('id'),
  r.read<String>('period_type'),
  Money(r.read<int>('amount_minor'), r.read<String>('currency_code')),
  DateTime.parse(r.read<String>('updated_at_utc')),
);
