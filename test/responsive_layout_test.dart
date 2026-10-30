import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/app/shell.dart';
import 'package:money_well_spent/features/expenses/widgets/expense_tile.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'responsive_harness.dart';

/// Every main screen, at every supported viewport and text scale, must lay
/// out without a render overflow and without scrolling sideways.
///
/// These assert behaviour the brief names — no clipped controls, no
/// horizontal scrolling, the last row reachable, amounts never truncated —
/// rather than incidental styling, so they keep their value when the visual
/// design moves on.
void main() {
  setUpAll(tz.initializeTimeZones);

  group('populated ledger lays out cleanly', () {
    for (final viewport in viewports) {
      for (final scale in textScales) {
        testWidgets('$viewport at ${scale}x text', (tester) async {
          useViewport(tester, viewport.size);
          final repository = await testRepository(
            tester,
            withBudgets: true,
            expenses: 6,
          );
          await pumpApp(tester, repository, scale: scale);
          expectNoOverflow(tester, 'Home on $viewport at ${scale}x');

          for (final tab in ['Activity', 'Insights', 'Budget']) {
            await openTab(tester, tab);
            expectNoOverflow(tester, '$tab on $viewport at ${scale}x');
          }
        });
      }
    }
  });

  group('empty ledger lays out cleanly', () {
    for (final viewport in viewports) {
      testWidgets('$viewport with no expenses', (tester) async {
        useViewport(tester, viewport.size);
        final repository = await testRepository(tester);
        await pumpApp(tester, repository, scale: 1.3);
        expectNoOverflow(tester, 'empty Home on $viewport');

        for (final tab in ['Activity', 'Insights', 'Budget']) {
          await openTab(tester, tab);
          expectNoOverflow(tester, 'empty $tab on $viewport');
        }
      });
    }
  });

  testWidgets('onboarding fits the smallest viewport at 2x text', (
    tester,
  ) async {
    useViewport(tester, viewports.first.size);
    final repository = await testRepository(tester, withProfile: false);
    await pumpApp(tester, repository, scale: 2);
    // At this size and text scale the button is well below the fold; the
    // point of the test is that it can be reached without the page
    // overflowing, not that it starts on screen.
    await scrollToInTopSheet(tester, find.text('Continue without account'));
    expect(find.text('Continue without account'), findsOneWidget);
    expectNoOverflow(tester, 'onboarding at 2x');
  });

  testWidgets('no screen scrolls horizontally', (tester) async {
    useViewport(tester, viewports.first.size);
    final repository = await testRepository(
      tester,
      withBudgets: true,
      expenses: 4,
    );
    await pumpApp(tester, repository, scale: 1.3);

    for (final tab in ['Activity', 'Insights', 'Budget']) {
      await openTab(tester, tab);
      final horizontal = tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .where(
            (s) =>
                s.axisDirection == AxisDirection.left ||
                s.axisDirection == AxisDirection.right,
          );
      expect(
        horizontal,
        isEmpty,
        reason: '$tab scrolls horizontally on a 320pt viewport',
      );
    }
  });

  testWidgets('overspent budget is stated in words, not colour alone', (
    tester,
  ) async {
    useViewport(tester, viewports[2].size);
    // The seeded spending deliberately exceeds the weekly cap.
    final repository = await testRepository(
      tester,
      withBudgets: true,
      expenses: 8,
      minor: 500000,
    );
    await pumpApp(tester, repository);
    await openTab(tester, 'Budget');
    expect(find.textContaining('over your limit'), findsWidgets);
    expectNoOverflow(tester, 'overspent Budget');
  });

  testWidgets('a long note is ellipsised but the amount keeps every digit', (
    tester,
  ) async {
    useViewport(tester, viewports.first.size);
    final repository = await testRepository(
      tester,
      expenses: 1,
      longNote: 'A very long note that will not fit on one line ' * 4,
      minor: 99999999,
    );
    await pumpApp(tester, repository);
    expectNoOverflow(tester, 'Home with a long note and a large amount');

    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.textSpan?.toPlainText() ?? t.data ?? '')
        .toList();
    expect(
      rendered.any((text) => text.contains('999,999.99')),
      isTrue,
      reason: 'the full grouped amount should be rendered somewhere on Home',
    );
  });

  testWidgets('the last expense row is reachable above the docked bars', (
    tester,
  ) async {
    useViewport(tester, viewports[1].size);
    final repository = await testRepository(tester, expenses: 12);
    await pumpApp(tester, repository);
    await openTab(tester, 'Activity');

    // Jump to the very end. A lazy ListView extends its scroll range as new
    // tiles build, so one jump clamps to a stale maxScrollExtent and stops
    // short; jump until the range stops growing.
    final position = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    for (var i = 0; i < 10 && position.pixels < position.maxScrollExtent; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }

    final rows = find.byType(ExpenseTile);
    expect(rows, findsWidgets);
    // The real claim: with the list scrolled to its end, the final row sits
    // entirely above the docked navigation, not behind it.
    expect(
      tester.getRect(rows.last).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(AppNavigationBar)).top),
      reason: 'the final row should clear the navigation when fully scrolled',
    );
    expectNoOverflow(tester, 'Activity scrolled to the end');
  });
}
