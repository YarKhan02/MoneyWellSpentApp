import 'package:drift/drift.dart';

/// Schema is explicit SQL; all user values are passed as bound parameters.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      for (final sql in schema) {
        await customStatement(sql);
      }
      const names = [
        'Food & Drinks',
        'Groceries',
        'Transport',
        'Shopping',
        'Bills',
        'Health',
        'Entertainment',
        'Other',
      ];
      for (var i = 0; i < names.length; i++) {
        await customStatement(
          'INSERT INTO categories(id,name,icon_key,color_key,is_system) VALUES(?,?,?,?,1)',
          ['system-$i', names[i], '$i', 'forest'],
        );
      }
    },
    onUpgrade: (m, from, to) async {
      throw StateError(
        'No migration from schema $from to $to is available. Data retained.',
      );
    },
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  static const schema = [
    '''CREATE TABLE local_profile (
      id TEXT PRIMARY KEY, base_currency TEXT NOT NULL,
      timezone TEXT NOT NULL, week_start INTEGER NOT NULL CHECK(week_start BETWEEN 1 AND 7),
      reduce_motion INTEGER NOT NULL DEFAULT 0,
      reduce_transparency INTEGER NOT NULL DEFAULT 0,
      notifications INTEGER NOT NULL DEFAULT 1,
      created_at_utc TEXT NOT NULL)''',
    '''CREATE TABLE categories (
      id TEXT PRIMARY KEY, name TEXT NOT NULL,
      icon_key TEXT NOT NULL, color_key TEXT NOT NULL,
      is_system INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0)''',
    '''CREATE TABLE expenses (
      id TEXT PRIMARY KEY,
      amount_minor INTEGER NOT NULL CHECK(amount_minor > 0 AND amount_minor <= 900000000000000),
      currency_code TEXT NOT NULL,
      category_id TEXT NOT NULL REFERENCES categories(id),
      note TEXT NOT NULL CHECK(length(note)<=280),
      occurred_at_utc TEXT NOT NULL, created_at_utc TEXT NOT NULL,
      updated_at_utc TEXT NOT NULL, deleted_at_utc TEXT)''',
    'CREATE INDEX expenses_active_time ON expenses(deleted_at_utc,occurred_at_utc)',
    'CREATE INDEX expenses_category_time ON expenses(category_id,occurred_at_utc)',
    '''CREATE TABLE budgets (
      id TEXT PRIMARY KEY, period_type TEXT NOT NULL CHECK(period_type IN ('week','month')),
      amount_minor INTEGER NOT NULL CHECK(amount_minor > 0 AND amount_minor <= 900000000000000),
      currency_code TEXT NOT NULL, updated_at_utc TEXT NOT NULL, deleted_at_utc TEXT)''',
    'CREATE UNIQUE INDEX budget_active_period ON budgets(period_type) WHERE deleted_at_utc IS NULL',
    '''CREATE TABLE alert_deliveries (
      budget_id TEXT NOT NULL REFERENCES budgets(id), period_start TEXT NOT NULL,
      threshold INTEGER NOT NULL CHECK(threshold IN (75,90,100)),
      delivered_at_utc TEXT NOT NULL,
      PRIMARY KEY(budget_id,period_start,threshold))''',
  ];
}
