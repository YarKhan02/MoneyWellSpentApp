import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'responsive_harness.dart';

/// With the keyboard open, the field being typed into, any validation
/// message and the submit action must all stay reachable.
void main() {
  setUpAll(tz.initializeTimeZones);

  /// Simulates a keyboard covering the bottom [height] of the viewport.
  void showKeyboard(WidgetTester tester, double height) {
    tester.view.viewInsets = FakeViewPadding(bottom: height);
    addTearDown(tester.view.resetViewInsets);
  }

  testWidgets('the add-expense sheet stays usable with the keyboard up', (
    tester,
  ) async {
    useViewport(tester, const Size(360, 640));
    final repository = await testRepository(tester);
    await pumpApp(tester, repository);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    showKeyboard(tester, 280);
    await tester.pump();
    expectNoOverflow(tester, 'add-expense sheet with the keyboard open');

    await tester.enterText(
      find.widgetWithText(TextField, 'Amount'),
      '12.34',
    );
    await tester.pumpAndSettle();

    // Save must be reachable by scrolling the sheet, not stranded under the
    // keyboard.
    await tester.scrollUntilVisible(find.text('Save expense'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Save expense'), findsOneWidget);
    expectNoOverflow(tester, 'add-expense sheet scrolled to Save');
  });

  testWidgets('a validation error stays visible with the keyboard up', (
    tester,
  ) async {
    useViewport(tester, const Size(360, 640));
    final repository = await testRepository(tester);
    await pumpApp(tester, repository);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    showKeyboard(tester, 280);
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '5.00');
    await tester.pumpAndSettle();
    // No category chosen yet, so saving must report that rather than fail
    // silently.
    await tester.scrollUntilVisible(find.text('Save expense'), 200);
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category.'), findsOneWidget);
    expectNoOverflow(tester, 'add-expense sheet showing a validation error');
  });

  testWidgets('the category editor sheet lifts above the keyboard', (
    tester,
  ) async {
    useViewport(tester, const Size(360, 640));
    final repository = await testRepository(tester);
    await pumpApp(tester, repository);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Manage categories'), 200);
    await tester.tap(find.text('Manage categories'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New category'));
    await tester.pumpAndSettle();

    showKeyboard(tester, 280);
    await tester.pump();
    expectNoOverflow(tester, 'category editor with the keyboard open');
    expect(find.text('Save category'), findsOneWidget);
  });
}
