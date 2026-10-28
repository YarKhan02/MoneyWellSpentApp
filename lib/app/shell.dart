import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design/tokens.dart';

/// The persistent frame around the four main branches: branch content above,
/// docked navigation below.
///
/// There is no app bar. Each tab opens with its own compact header row that
/// carries the title and the settings action, which saves a full bar of
/// chrome on every screen.
///
/// The bars are docked rather than overlaid (`extendBody` stays off), so
/// [Scaffold] lays the content out above them and nothing can be covered.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// Home is the only branch that gets the full-width Add expense bar.
  static const _homeBranch = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(bottom: false, child: shell),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Brand.screenPadding,
          0,
          Brand.screenPadding,
          Brand.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shell.currentIndex == _homeBranch) ...[
              AddExpenseBar(onTap: () => context.push('/expenses/new')),
              const SizedBox(height: Brand.sm),
            ],
            AppNavigationBar(shell: shell),
          ],
        ),
      ),
    ),
  );
}

/// Frosted circular settings button, placed by each screen in its header row.
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: context.tokens.neutralCard,
    shape: CircleBorder(side: BorderSide(color: context.tokens.cardBorder)),
    clipBehavior: Clip.antiAlias,
    child: IconButton(
      tooltip: 'Settings',
      onPressed: () => context.push('/settings'),
      // Visually compact, but still a full-size target.
      constraints: const BoxConstraints.tightFor(
        width: Brand.minTouchTarget,
        height: Brand.minTouchTarget,
      ),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.settings_outlined, size: Brand.iconSize),
    ),
  );
}

/// Full-width primary Add Expense bar (replaces the overlapping FAB).
class AddExpenseBar extends StatelessWidget {
  const AddExpenseBar({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Brand.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.buttonRadius),
        ),
      ),
      icon: const Icon(Icons.add, size: Brand.iconSize),
      label: const Text('Add expense'),
    ),
  );
}

/// Docked navigation surface with clear active states.
///
/// Its height grows with the viewer's text scale so labels are never
/// clipped, and it is a solid surface rather than a blurred one: docked over
/// a flat background there is nothing to blur, and the brand calls for
/// translucency to be used sparingly.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// Tallest the bar may grow before labels are left to wrap on their own.
  static const maxHeight = 96.0;

  static double heightFor(BuildContext context) =>
      (Brand.navBarHeight * context.textScale).clamp(
        Brand.navBarHeight,
        maxHeight,
      );

  static const _destinations = [
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
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.neutralCard,
        borderRadius: BorderRadius.circular(Brand.cardRadius),
        border: Border.all(color: t.cardBorder),
        boxShadow: t.shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Brand.cardRadius),
        child: NavigationBar(
          height: heightFor(context),
          backgroundColor: Colors.transparent,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goBranch,
          destinations: _destinations,
        ),
      ),
    );
  }
}
