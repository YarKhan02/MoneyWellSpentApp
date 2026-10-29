import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/app/app.dart';
import 'package:money_well_spent/app/providers.dart';
import 'package:money_well_spent/core/money/money.dart';
import 'package:money_well_spent/core/storage/database.dart';
import 'package:money_well_spent/features/ledger/repository.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> settleDatabase(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder target, double delta) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

/// Chooses [option] from the selection sheet opened by the field labelled
/// [fieldLabel]. The app no longer uses dropdown menus anywhere.
///
/// Taps the field's tappable ancestor rather than the label text: once the
/// label floats above a filled value, its own glyphs no longer sit over the
/// field's hit area.
Future<void> chooseFromSheet(
  WidgetTester tester,
  String fieldLabel,
  String option,
) async {
  await tester.tap(
    find
        .ancestor(of: find.text(fieldLabel), matching: find.byType(InkWell))
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(tz.initializeTimeZones);
  testWidgets('first run saves explicit preferences and reaches Home', (
    tester,
  ) async {
    final repository = LedgerRepository(AppDatabase(NativeDatabase.memory()));
    await repository.snapshot();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const MoneyWellSpentApp(),
      ),
    );
    await settleDatabase(tester);
    await scrollTo(tester, find.text('Continue without account'), 250);
    await tester.tap(find.text('Continue without account'));
    await tester.pumpAndSettle();
    await chooseFromSheet(tester, 'Book currency', 'USD');
    await tester.enterText(
      find.widgetWithText(TextField, 'Timezone (IANA)'),
      'UTC',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Start my book'), 200);
    await tester.tap(find.text('Start my book'));
    await settleDatabase(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect((await repository.snapshot()).profile!.currency, 'USD');
    await tester.pumpWidget(const SizedBox());
    await repository.close();
  });

  testWidgets('capture, edit and delete flow updates the actual local ledger', (
    tester,
  ) async {
    final repository = LedgerRepository(AppDatabase(NativeDatabase.memory()));
    await repository.saveProfile('USD', 'UTC', 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const MoneyWellSpentApp(),
      ),
    );
    await settleDatabase(tester);
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '12.34');
    await tester.tap(find.text('Food & Drinks'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await scrollTo(tester, find.text('Save expense'), 250);
    await tester.tap(find.text('Save expense'));
    await settleDatabase(tester);
    expect((await repository.snapshot()).expenses.single.amount.minor, 1234);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD 12.34').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Edit expense'), 150);
    await tester.tap(find.text('Edit expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '14.50');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await scrollTo(tester, find.text('Save expense'), 250);
    await tester.tap(find.text('Save expense'));
    await settleDatabase(tester);
    expect((await repository.snapshot()).expenses.single.amount.minor, 1450);
    await scrollTo(tester, find.text('Delete expense'), 150);
    await tester.tap(find.text('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await settleDatabase(tester);
    expect((await repository.snapshot()).expenses, isEmpty);
    await tester.tap(find.text('Undo'));
    await settleDatabase(tester);
    expect((await repository.snapshot()).expenses.single.amount.minor, 1450);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await repository.close();
  });

  testWidgets(
    'render branded home preview from an explicitly seeded test ledger',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final repository = LedgerRepository(AppDatabase(NativeDatabase.memory()));
      await repository.saveProfile('PKR', 'Asia/Karachi', 1);
      await repository.saveBudget('week', const Money(2500000, 'PKR'));
      await repository.saveExpense(
        id: 'preview-only',
        amount: const Money(125000, 'PKR'),
        categoryId: 'system-0',
        note: 'Lunch with friends · preview data',
        occurredAt: DateTime.now(),
      );
      const key = ValueKey('preview');
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repository)],
            child: const MoneyWellSpentApp(),
          ),
        ),
      );
      await settleDatabase(tester);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      final image = (await tester.runAsync(() => boundary.toImage()))!;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(() async {
        final directory = Directory('docs/previews');
        await directory.create(recursive: true);
        await File(
          '${directory.path}/home.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      image.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repository.close();
    },
  );
}
