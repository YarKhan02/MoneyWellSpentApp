import 'package:drift/drift.dart';
import '../../core/storage/database.dart';

/// Thin query helper shared by the ledger's reader, writer and alert recorder.
/// Every user value is passed as a bound parameter — never interpolated.
extension LedgerQueries on AppDatabase {
  Future<List<QueryRow>> rows(
    String sql, [
    List<Variable> variables = const [],
  ]) => customSelect(sql, variables: variables).get();
}
