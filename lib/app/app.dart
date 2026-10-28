import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/design/theme.dart';
import '../features/ledger/models.dart';
import '../features/screens/dashboard.dart';
import '../features/screens/forms.dart';
import '../features/screens/settings.dart';
import 'providers.dart';

class MoneyWellSpentApp extends ConsumerStatefulWidget {
  const MoneyWellSpentApp({super.key});
  @override
  ConsumerState<MoneyWellSpentApp> createState() => _AppState();
}

class _AppState extends ConsumerState<MoneyWellSpentApp>
    with WidgetsBindingObserver {
  late final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const LedgerView(builder: homeScreen),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (_, state) => LedgerView(
                  builder: (c, d) => ActivityScreen(
                    data: d,
                    category: state.uri.queryParameters['category'],
                    start: state.uri.queryParameters['start'],
                    end: state.uri.queryParameters['end'],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (_, state) => LedgerView(
                  builder: (c, d) => InsightsScreen(
                    data: d,
                    initialPeriod: state.uri.queryParameters['period'],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budget',
                builder: (_, _) => const LedgerView(builder: budgetScreen),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/expenses/new',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          transitionsBuilder: (_, _, _, child) => child,
          child: const LedgerView(builder: newExpenseScreen),
        ),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (_, state) => LedgerView(
          builder: (c, d) =>
              ExpenseDetail(data: d, id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/expenses/:id/edit',
        builder: (_, state) => LedgerView(
          builder: (c, d) =>
              ExpenseForm(data: d, id: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/budget/:period/edit',
        builder: (_, state) => LedgerView(
          builder: (c, d) =>
              BudgetForm(data: d, period: state.pathParameters['period']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const LedgerView(builder: settingsScreen),
      ),
      GoRoute(
        path: '/settings/categories',
        builder: (_, _) => const LedgerView(builder: categoriesScreen),
      ),
    ],
  );
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      await ref.read(repositoryProvider).refreshCalendar();
    } catch (_) {
      /* Existing stream shows read failures; don't expose financial data in logs. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ledgerProvider);
    return MaterialApp.router(
      title: 'Money Well Spent',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme(),
      routerConfig: router,
      builder: (context, child) => data.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyState(
                title: 'Your data is still here',
                message:
                    'We could not read local storage. Nothing was reset. Retry or contact support before changing app files.',
                action: FilledButton(
                  onPressed: () => ref.invalidate(ledgerProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
          ),
        ),
        data: (snapshot) => snapshot.profile == null
            ? Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => OnboardingScreen(data: snapshot),
                ),
              )
            : MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations:
                      MediaQuery.of(context).disableAnimations ||
                      snapshot.profile!.reduceMotion,
                ),
                child: child!,
              ),
      ),
    );
  }
}

typedef LedgerBuilder = Widget Function(BuildContext, LedgerSnapshot);

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

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
    // Bars are docked (not extendBody) so the floating nav / Add bar never
    // overlap scrollable transaction content.
    appBar: const _TopBar(),
    body: SafeArea(bottom: false, child: shell),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Brand.lg, 0, Brand.lg, Brand.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Expense is a dedicated full-width bar on Home only, so it never
            // overlaps transaction content or the navigation (list clears it via
            // PageBody's bottom padding).
            if (shell.currentIndex == 0) ...[
              _AddExpenseBar(onTap: () => context.push('/expenses/new')),
              const SizedBox(height: Brand.sm),
            ],
            FloatingNav(shell: shell),
          ],
        ),
      ),
    ),
  );
}

/// Minimal transparent top bar: just a frosted circular settings button.
/// Each screen supplies its own heading in content.
class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar();
  @override
  Size get preferredSize => const Size.fromHeight(52);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 52,
    automaticallyImplyLeading: false,
    backgroundColor: Colors.transparent,
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: Brand.lg),
        child: Material(
          color: context.tokens.neutralCard,
          shape: const CircleBorder(side: BorderSide(color: Color(0x14133020))),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
        ),
      ),
    ],
  );
}

/// Full-width primary Add Expense bar (replaces the overlapping FAB).
class _AddExpenseBar extends StatelessWidget {
  const _AddExpenseBar({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.xl),
        ),
      ),
      icon: const Icon(Icons.add),
      label: const Text('Add expense'),
    ),
  );
}

/// Floating, lightweight glass navigation surface with clear active states.
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final solid =
        MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).highContrast;
    final nav = NavigationBar(
      backgroundColor: Colors.transparent,
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (i) => shell.goBranch(i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Activity',
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_outline_rounded),
          selectedIcon: Icon(Icons.pie_chart_rounded),
          label: 'Insights',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Budget',
        ),
      ],
    );
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: t.neutralCard.withValues(alpha: solid ? 1 : .82),
        borderRadius: BorderRadius.circular(Brand.section),
        border: Border.all(color: t.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A133020),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: nav,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(Brand.section),
      child: solid
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: surface,
            ),
    );
  }
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Brand.xl, Brand.md, Brand.xl, 96),
        children: [
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(bottom: Brand.xl),
              child: child,
            ),
        ],
      ),
    ),
  );
}
