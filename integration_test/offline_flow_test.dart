import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_well_spent/main.dart' as app;

/// Run on a clean emulator/device in airplane mode. Never use a personal ledger.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('offline guest setup reaches the empty ledger', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continue without account'), 200);
    await tester.tap(find.text('Continue without account'));
    await tester.pumpAndSettle();
    // Currency is chosen from a bottom sheet, not a dropdown menu.
    await tester.tap(find.text('Book currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Timezone (IANA)'),
      'UTC',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.scrollUntilVisible(find.text('Start my book'), 200);
    await tester.tap(find.text('Start my book'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
  });
}
