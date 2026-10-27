import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/app/app.dart';
import 'package:money_well_spent/app/providers.dart';
import 'package:money_well_spent/core/storage/database.dart';
import 'package:money_well_spent/features/ledger/repository.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);
  testWidgets('fresh install shows guest welcome and no account gate', (
    tester,
  ) async {
    final repo = LedgerRepository(AppDatabase(NativeDatabase.memory()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MoneyWellSpentApp(),
      ),
    );
    await tester.runAsync(() => repo.snapshot());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continue without account'), 250);
    expect(find.text('Continue without account'), findsOneWidget);
    expect(find.text('Skip introduction'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
  testWidgets(
    'empty home has four tabs, add action and accessible large text',
    (tester) async {
      final repo = LedgerRepository(AppDatabase(NativeDatabase.memory()));
      await repo.saveProfile('USD', 'UTC', 1);
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const MoneyWellSpentApp(),
        ),
      );
      await tester.runAsync(() => repo.snapshot());
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Add expense'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
}
