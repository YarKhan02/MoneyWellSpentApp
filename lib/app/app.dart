import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/design/theme.dart';
import '../features/ledger/models.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../shared/widgets/widgets.dart';
import 'providers.dart';
import 'router.dart';

/// Root of the app.
///
/// Owns three things and delegates the rest: the router, the periodic
/// calendar refresh that keeps budget periods current while the app is open,
/// and the top-level loading / error / onboarding switch.
class MoneyWellSpentApp extends ConsumerStatefulWidget {
  const MoneyWellSpentApp({super.key});

  /// How often to re-check whether a budget period has rolled over.
  static const refreshInterval = Duration(minutes: 1);

  @override
  ConsumerState<MoneyWellSpentApp> createState() => _MoneyWellSpentAppState();
}

class _MoneyWellSpentAppState extends ConsumerState<MoneyWellSpentApp>
    with WidgetsBindingObserver {
  late final GoRouter _router = buildRouter();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      MoneyWellSpentApp.refreshInterval,
      (_) => _refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background may have crossed a period boundary.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref.read(repositoryProvider).refreshCalendar();
    } catch (_) {
      /* The ledger stream already surfaces read failures; financial data
         must never reach logs. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ledgerProvider);
    return MaterialApp.router(
      title: 'Money Well Spent',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
      builder: (context, child) => data.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => _StorageError(
          onRetry: () => ref.invalidate(ledgerProvider),
        ),
        data: (snapshot) => snapshot.profile == null
            ? _onboarding(snapshot)
            : _withMotionPreference(context, snapshot, child!),
      ),
    );
  }

  /// Before a profile exists there is nothing to route to, so onboarding is
  /// shown in its own navigator above the router.
  Widget _onboarding(LedgerSnapshot snapshot) => Navigator(
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (_) => OnboardingScreen(data: snapshot),
    ),
  );

  /// Honours the book's own "reduce motion" switch on top of the platform's.
  Widget _withMotionPreference(
    BuildContext context,
    LedgerSnapshot snapshot,
    Widget child,
  ) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        disableAnimations:
            media.disableAnimations || snapshot.profile!.reduceMotion,
      ),
      child: child,
    );
  }
}

class _StorageError extends StatelessWidget {
  const _StorageError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          title: 'Your data is still here',
          message:
              'We could not read local storage. Nothing was reset. Retry or contact support before changing app files.',
          action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ),
    ),
  );
}
