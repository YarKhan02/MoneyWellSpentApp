import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:money_well_spent/core/storage/database.dart';
import 'package:money_well_spent/core/money/money.dart';
import 'package:money_well_spent/core/time/period.dart';
import 'package:money_well_spent/features/ledger/repository.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    // Each test intentionally owns a separate executor/file.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  late LedgerRepository repo;
  final now = DateTime.utc(2026, 10, 27, 12);
  setUp(() async {
    repo = LedgerRepository(
      AppDatabase(NativeDatabase.memory()),
      clock: () => now,
    );
    await repo.saveProfile('USD', 'America/New_York', 1);
  });
  tearDown(() => repo.close());
  Future<void> add(
    String id,
    int amount, {
    DateTime? at,
    String category = 'system-0',
    String note = '',
    bool editing = false,
  }) => repo.saveExpense(
    id: id,
    amount: Money(amount, 'USD'),
    categoryId: category,
    note: note,
    occurredAt: at ?? now,
    editing: editing,
  );

  test(
    'fresh schema seeds exactly eight categories and profile persists',
    () async {
      final data = await repo.snapshot();
      expect(data.categories.length, 8);
      expect(data.profile!.timezone, 'America/New_York');
      expect(data.expenses, isEmpty);
    },
  );
  test(
    '100 expenses remain exact across edit, delete, undo and database restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mws-ledger-test',
      );
      final file = File('${directory.path}/book.sqlite');
      final persisted = LedgerRepository(
        AppDatabase(NativeDatabase(file)),
        clock: () => now,
      );
      await persisted.saveProfile('KWD', 'Asia/Karachi', 1);
      for (var i = 0; i < 100; i++) {
        await persisted.saveExpense(
          id: 'entry-$i',
          amount: Money(1001 + i, 'KWD'),
          categoryId: 'system-0',
          note: '',
          occurredAt: now,
        );
      }
      await persisted.saveExpense(
        id: 'entry-0',
        amount: const Money(2222, 'KWD'),
        categoryId: 'system-1',
        note: 'Changed',
        occurredAt: now,
        editing: true,
      );
      await persisted.deleteExpense('entry-1');
      await persisted.undoDelete('entry-1');
      await persisted.deleteExpense('entry-2');
      await persisted.close();
      final reopened = LedgerRepository(
        AppDatabase(NativeDatabase(file)),
        clock: () => now,
      );
      final data = await reopened.snapshot();
      expect(data.expenses.length, 99);
      expect(
        data.expenses.fold<int>(0, (sum, e) => sum + e.amount.minor),
        105050 + 1221 - 1003,
      );
      expect(data.categories.length, 8);
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );
  test(
    'duplicate submission cannot duplicate or overwrite a financial entry',
    () async {
      await add('same', 100);
      await add('same', 900);
      final data = await repo.snapshot();
      expect(data.expenses.length, 1);
      expect(data.expenses.single.amount.minor, 100);
    },
  );
  test(
    'money, notes, currency, category and deleted edit validation',
    () async {
      await expectLater(add('zero', 0), throwsFormatException);
      await expectLater(
        add('note', 100, note: 'a' * 281),
        throwsFormatException,
      );
      await expectLater(
        add('missing', 100, category: 'missing'),
        throwsFormatException,
      );
      await expectLater(
        repo.saveExpense(
          id: 'currency',
          amount: const Money(100, 'PKR'),
          categoryId: 'system-0',
          note: '',
          occurredAt: now,
        ),
        throwsFormatException,
      );
      await add('ok', 100);
      await repo.deleteExpense('ok');
      await expectLater(add('ok', 200, editing: true), throwsFormatException);
      await expectLater(
        repo.saveProfile('PKR', 'UTC', 1),
        throwsFormatException,
      );
    },
  );
  test(
    'archived categories retain history but cannot receive new expenses',
    () async {
      await repo.saveCategory(name: 'Coffee');
      final category = (await repo.snapshot()).categories.last;
      await add('old', 125, category: category.id);
      await repo.archiveCategory(category.id, true);
      await expectLater(
        add('new', 100, category: category.id),
        throwsFormatException,
      );
      await add('old', 150, category: category.id, editing: true);
      final data = await repo.snapshot();
      expect(data.category(category.id).archived, isTrue);
      expect(data.expenses.single.amount.minor, 150);
      await expectLater(
        repo.saveCategory(name: '  COFFEE  '),
        throwsFormatException,
      );
      await repo.archiveCategory('system-0', true);
      expect((await repo.snapshot()).category('system-0').archived, isFalse);
    },
  );
  test(
    'calendar aggregates reconcile with bound raw SQL at DST and week rollover',
    () async {
      final instants = [
        DateTime.utc(2026, 3, 8, 4, 59),
        DateTime.utc(2026, 3, 8, 5),
        DateTime.utc(2026, 3, 9, 3, 59),
        DateTime.utc(2026, 3, 9, 4),
        DateTime.utc(2025, 12, 31, 23, 59),
        DateTime.utc(2026, 1, 1),
      ];
      for (var i = 0; i < instants.length; i++) {
        await add(
          'boundary-$i',
          (i + 1) * 101,
          at: instants[i],
          category: 'system-${i % 3}',
        );
      }
      final data = await repo.snapshot();
      for (final anchor in instants) {
        for (final period in Period.values) {
          final range = CalendarRange.containing(
            anchor,
            data.profile!.timezone,
            period,
          );
          // Independent reference query uses explicit UTC fixture bounds below for DST day.
          final reference = data.expenses
              .where(
                (e) =>
                    e.occurredAt.compareTo(range.start) >= 0 &&
                    e.occurredAt.compareTo(range.end) < 0,
              )
              .fold(0, (int sum, e) => sum + e.amount.minor);
          expect(data.total(range.start, range.end), reference);
          expect(
            data.categories.fold(
              0,
              (int sum, c) =>
                  sum + data.total(range.start, range.end, category: c.id),
            ),
            reference,
          );
        }
      }
      final sql = await repo.db
          .customSelect(
            "SELECT SUM(amount_minor) AS total FROM expenses WHERE deleted_at_utc IS NULL AND occurred_at_utc >= '2026-03-08T05:00:00.000000Z' AND occurred_at_utc < '2026-03-09T04:00:00.000000Z'",
          )
          .getSingle();
      final dst = CalendarRange.containing(
        DateTime.utc(2026, 3, 8, 12),
        'America/New_York',
        Period.day,
      );
      expect(data.total(dst.start, dst.end), sql.read<int>('total'));
      expect(sql.read<int>('total'), 505);
    },
  );
  test(
    'budget alerts deduplicate across edits, deletes and threshold recrossings',
    () async {
      await repo.saveBudget('week', const Money(1000, 'USD'));
      await add('one', 750);
      expect((await repo.snapshot()).alerts.length, 1);
      await add('one', 1000, editing: true);
      expect((await repo.snapshot()).alerts.length, 3);
      await repo.deleteExpense('one');
      await repo.undoDelete('one');
      await repo.refreshCalendar();
      expect((await repo.snapshot()).alerts.length, 3);
      await repo.saveBudget('week', const Money(2000, 'USD'));
      expect((await repo.snapshot()).budgets.length, 1);
      expect((await repo.snapshot()).budgets.single.amount.minor, 2000);
    },
  );
  test('threshold dedup resets for the next calendar period', () async {
    var clock = DateTime.utc(2026, 10, 27, 12);
    final rolling = LedgerRepository(
      AppDatabase(NativeDatabase.memory()),
      clock: () => clock,
    );
    await rolling.saveProfile('USD', 'UTC', 1);
    await rolling.saveBudget('week', const Money(100, 'USD'));
    Future<void> entry(String id) => rolling.saveExpense(
      id: id,
      amount: const Money(100, 'USD'),
      categoryId: 'system-0',
      note: '',
      occurredAt: clock,
    );
    await entry('first');
    expect((await rolling.snapshot()).alerts.length, 3);
    clock = DateTime.utc(2026, 11, 3, 12);
    await rolling.refreshCalendar();
    expect((await rolling.snapshot()).alerts, isEmpty);
    await entry('second');
    expect((await rolling.snapshot()).alerts.length, 3);
    final count = await rolling.db
        .customSelect('SELECT COUNT(*) AS count FROM alert_deliveries')
        .getSingle();
    expect(count.read<int>('count'), 6);
    await rolling.close();
  });
  test(
    'CSV is precise, escaped, formula-safe and excludes deleted records',
    () async {
      await add('one', 123, note: '=HYPERLINK("bad")\nhello');
      await add('two', 234);
      await repo.deleteExpense('two');
      final csv = await repo.exportCsv();
      expect(csv, contains('"schema_version"'));
      expect(csv, contains('"123","1.23","USD"'));
      expect(csv, contains("\"'=HYPERLINK(\"\"bad\"\")\nhello\""));
      expect(csv, isNot(contains('"two"')));
    },
  );
  test(
    'erase requires exact confirmation and reseeds a clean onboarding state',
    () async {
      await add('one', 100);
      await expectLater(repo.erase('erase'), throwsFormatException);
      expect((await repo.snapshot()).expenses.length, 1);
      await repo.erase('ERASE');
      final data = await repo.snapshot();
      expect(data.profile, isNull);
      expect(data.expenses, isEmpty);
      expect(data.categories.length, 8);
    },
  );
  test(
    'microsecond timestamps sort correctly and count at the start of a budget period',
    () async {
      final beginning = DateTime.utc(2026, 10, 26);
      final r = LedgerRepository(
        AppDatabase(NativeDatabase.memory()),
        clock: () => beginning,
      );
      await r.saveProfile('USD', 'UTC', 1);
      await r.saveBudget('week', const Money(100, 'USD'));
      for (final offset in [0, 1, 1000, 1001]) {
        await r.saveExpense(
          id: '$offset',
          amount: const Money(25, 'USD'),
          categoryId: 'system-0',
          note: '',
          occurredAt: beginning.add(Duration(microseconds: offset)),
        );
      }
      final data = await r.snapshot();
      expect(data.expenses.map((e) => e.id), ['1001', '1000', '1', '0']);
      expect(data.alerts.length, 3);
      await r.close();
    },
  );
  test(
    'signal preference persists and suppresses new threshold deliveries',
    () async {
      await repo.saveProfile('USD', 'UTC', 1, budgetSignals: false);
      await repo.saveBudget('week', const Money(100, 'USD'));
      await add('signal-disabled', 200);
      expect((await repo.snapshot()).profile!.budgetSignals, isFalse);
      expect((await repo.snapshot()).alerts, isEmpty);
      await repo.saveProfile('USD', 'UTC', 1, budgetSignals: true);
      expect((await repo.snapshot()).alerts.length, 3);
    },
  );
  test(
    'unsupported newer schema fails without destroying financial records',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mws-migration-test',
      );
      final file = File('${directory.path}/future.sqlite');
      final fixture = AppDatabase(NativeDatabase(file));
      await fixture.customStatement(
        'CREATE TABLE retained_record (value TEXT)',
      );
      await fixture.customStatement(
        "INSERT INTO retained_record VALUES ('keep-me')",
      );
      await fixture.customStatement('PRAGMA user_version = 2');
      await fixture.close();
      final reopened = AppDatabase(NativeDatabase(file));
      await expectLater(
        reopened.customSelect('SELECT * FROM retained_record').get(),
        throwsStateError,
      );
      await reopened.close();
      // Open without application migrations to inspect the original file.
      final raw = NativeDatabase(file);
      final checker = _InspectionDatabase(raw);
      final record = await checker
          .customSelect('SELECT * FROM retained_record')
          .getSingle();
      expect(record.read<String>('value'), 'keep-me');
      await checker.close();
      await directory.delete(recursive: true);
    },
  );
}

class _InspectionDatabase extends GeneratedDatabase {
  _InspectionDatabase(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
}
