import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app/app.dart';
import 'app/providers.dart';
import 'core/storage/database.dart';
import 'features/ledger/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Plus Jakarta Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  try {
    final directory = await getApplicationSupportDirectory();
    if (Platform.isIOS) {
      await const MethodChannel(
        'com.shoukanlabs.moneywellspent/storage',
      ).invokeMethod<void>('excludeLocalBookFromBackup');
    }
    final database = AppDatabase(
      NativeDatabase.createInBackground(
        File(path.join(directory.path, 'money_well_spent.sqlite')),
      ),
    );
    final repository = LedgerRepository(database);
    runApp(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const MoneyWellSpentApp(),
      ),
    );
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Your local storage could not be opened. Your data has not been erased. Restart the app or contact support before changing any app files.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
