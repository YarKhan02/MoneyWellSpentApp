import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ledger/repository.dart';
import '../features/ledger/models.dart';

final repositoryProvider = Provider<LedgerRepository>(
  (ref) => throw UnimplementedError('Repository must be injected at bootstrap'),
);
final ledgerProvider = StreamProvider<LedgerSnapshot>(
  (ref) => ref.watch(repositoryProvider).watch(),
);
