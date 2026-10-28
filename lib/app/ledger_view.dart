import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ledger/models.dart';
import 'providers.dart';

typedef LedgerBuilder = Widget Function(BuildContext, LedgerSnapshot);

/// Wraps a route in the current ledger snapshot, so screens receive plain
/// data and never touch Riverpod's async states themselves.
///
/// A null profile means onboarding has not finished; the root widget is
/// already showing onboarding, so this renders nothing rather than flashing
/// a half-configured screen.
class LedgerView extends ConsumerWidget {
  const LedgerView({super.key, required this.builder});
  final LedgerBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(ledgerProvider)
      .when(
        data: (data) => data.profile == null
            ? const SizedBox.shrink()
            : builder(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Unable to read your local data. Please retry.'),
        ),
      );
}
