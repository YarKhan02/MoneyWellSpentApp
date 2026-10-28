import '../sql_access.dart';
import 'ledger_writer.dart';

/// Create, rename and archive custom categories.
///
/// System categories are permanent: they cannot be renamed, archived or
/// deleted, so a book always has a usable set to file an expense under.
class CategoryWriter extends LedgerWriter {
  const CategoryWriter(super.db, super.clock);

  static const nameLimit = 40;

  Future<void> save({
    String? id,
    required String name,
    required String icon,
    required String color,
    required String Function() newId,
  }) async {
    final normalized = _normalize(name);
    final all = await db.rows('SELECT * FROM categories');
    if (all.any(
      (c) =>
          c.read<String>('id') != id &&
          c.read<String>('name').toLowerCase() == normalized.toLowerCase(),
    )) {
      throw const FormatException('A category with that name already exists.');
    }
    if (id == null) {
      await db.customStatement(
        'INSERT INTO categories(id,name,icon_key,color_key) VALUES(?,?,?,?)',
        [newId(), normalized, icon, color],
      );
      return;
    }
    final found = all.where((c) => c.read<String>('id') == id);
    if (found.isEmpty || found.single.read<int>('is_system') == 1) {
      throw const FormatException('System categories cannot be renamed.');
    }
    await db.customStatement(
      'UPDATE categories SET name=?,icon_key=?,color_key=? WHERE id=?',
      [normalized, icon, color, id],
    );
  }

  /// Archiving hides a category from new entries while keeping every past
  /// expense filed under it intact.
  Future<void> archive(String id, bool archived) => db.customStatement(
    'UPDATE categories SET is_archived=? WHERE id=? AND is_system=0',
    [archived ? 1 : 0, id],
  );

  String _normalize(String name) {
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.runes.length > nameLimit) {
      throw const FormatException('Use a category name of 1–40 characters.');
    }
    return normalized;
  }
}
