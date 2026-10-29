import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/app/app.dart';
import 'package:money_well_spent/app/providers.dart';
import 'package:money_well_spent/core/money/money.dart';
import 'package:money_well_spent/core/storage/database.dart';
import 'package:money_well_spent/features/ledger/repository.dart';

/// Logical viewport sizes the UI must survive, from the smallest phone still
/// in use to a short landscape window.
class Viewport {
  const Viewport(this.name, this.size);
  final String name;
  final Size size;

  @override
  String toString() => '$name (${size.width.toInt()}x${size.height.toInt()})';
}

const viewports = [
  Viewport('small phone', Size(320, 568)),
  Viewport('compact phone', Size(360, 640)),
  Viewport('modern phone', Size(390, 844)),
  Viewport('large phone', Size(412, 915)),
  Viewport('largest phone', Size(430, 932)),
  Viewport('landscape', Size(844, 390)),
];

/// Accessibility text scales to exercise. 2.0 with a 320pt viewport is the
/// hardest combination and is deliberately included.
const textScales = [1.0, 1.3, 2.0];

/// Applies a viewport and tears it down again.
void useViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// A repository backed by an in-memory database, torn down automatically.
Future<LedgerRepository> testRepository(
  WidgetTester tester, {
  bool withProfile = true,
  bool withBudgets = false,
  int expenses = 0,
  String currency = 'PKR',
  String? longNote,
  int minor = 125000,
}) async {
  final repository = LedgerRepository(AppDatabase(NativeDatabase.memory()));
  addTearDown(repository.close);
  if (withProfile) {
    await repository.saveProfile(currency, 'Asia/Karachi', DateTime.monday);
  }
  if (withBudgets) {
    await repository.saveBudget('week', Money(minor * 4, currency));
    await repository.saveBudget('month', Money(minor * 10, currency));
  }
  for (var i = 0; i < expenses; i++) {
    await repository.saveExpense(
      id: 'seed-$i',
      amount: Money(minor + i, currency),
      categoryId: 'system-${i % 8}',
      note: longNote ?? 'Seeded expense $i',
      occurredAt: DateTime.now().subtract(Duration(hours: i * 7)),
    );
  }
  return repository;
}

/// Pumps the whole app at [scale], waiting for the database stream.
///
/// The scale is set on the platform dispatcher rather than by wrapping the
/// app in a [MediaQuery], so it reaches the app the same way a real system
/// text-size setting would — and so the viewport set by [useViewport] is
/// not overwritten.
Future<void> pumpApp(
  WidgetTester tester,
  LedgerRepository repository, {
  double scale = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repository)],
      child: const MoneyWellSpentApp(),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

/// Fails with a readable message if the frame produced any layout overflow
/// or other render exception.
///
/// `takeException` returns the first error Flutter recorded while building
/// or painting — a RenderFlex overflow shows up here.
void expectNoOverflow(WidgetTester tester, String context) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Layout error in $context: $error');
}

/// Scrolls [target] into view inside the most recently pushed scrolling
/// page, rather than whichever `Scrollable` happens to come first in the
/// tree — with a sheet open, the first one is the page behind it.
Future<void> scrollToInTopSheet(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// Moves to a tab by its navigation label and settles.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
