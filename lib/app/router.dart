import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/activity/activity_screen.dart';
import '../features/budget/budget_form_screen.dart';
import '../features/budget/budget_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/expenses/expense_detail_screen.dart';
import '../features/expenses/expense_form_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/settings/settings_screen.dart';
import 'ledger_view.dart';
import 'shell.dart';

/// All routes in the app.
///
/// The four shell branches keep their own navigation stacks, so switching
/// tabs never loses where you were. Everything outside the shell — forms,
/// detail, settings — is pushed on top of it.
GoRouter buildRouter({
  List<NavigatorObserver> observers = const [],
}) => GoRouter(
  observers: observers,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) =>
                  LedgerView(builder: (_, d) => HomeScreen(data: d)),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              builder: (_, state) => LedgerView(
                builder: (_, d) => ActivityScreen(
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
                builder: (_, d) => InsightsScreen(
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
              builder: (_, _) =>
                  LedgerView(builder: (_, d) => BudgetScreen(data: d)),
            ),
          ],
        ),
      ],
    ),
    // Adding an expense is a sheet over the ledger, not a page change, so the
    // route stays transparent and skips the default transition.
    GoRoute(
      path: '/expenses/new',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        transitionsBuilder: (_, _, _, child) => child,
        child: LedgerView(builder: (_, d) => ExpenseFormScreen(data: d)),
      ),
    ),
    GoRoute(
      path: '/expenses/:id',
      builder: (_, state) => LedgerView(
        builder: (_, d) =>
            ExpenseDetailScreen(data: d, id: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/expenses/:id/edit',
      builder: (_, state) => LedgerView(
        builder: (_, d) =>
            ExpenseFormScreen(data: d, id: state.pathParameters['id']),
      ),
    ),
    GoRoute(
      path: '/budget/:period/edit',
      builder: (_, state) => LedgerView(
        builder: (_, d) =>
            BudgetFormScreen(data: d, period: state.pathParameters['period']!),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => LedgerView(builder: (_, d) => SettingsScreen(data: d)),
    ),
    GoRoute(
      path: '/settings/categories',
      builder: (_, _) =>
          LedgerView(builder: (_, d) => CategoriesScreen(data: d)),
    ),
  ],
);
