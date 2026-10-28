import '../../../core/storage/database.dart';
import '../../../core/time/period.dart';

/// Shared base for the ledger's write paths.
///
/// A writer never opens its own transaction: [LedgerRepository] wraps each
/// call so the write and the budget-threshold pass commit together.
abstract class LedgerWriter {
  const LedgerWriter(this.db, this.clock);
  final AppDatabase db;
  final DateTime Function() clock;

  /// Current instant as a fixed-precision UTC string, so SQLite's TEXT
  /// ordering matches chronological ordering.
  String get now => utcStamp(clock());
}
