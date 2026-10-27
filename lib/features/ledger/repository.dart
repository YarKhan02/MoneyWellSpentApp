import 'dart:async';
import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../../core/money/money.dart';
import '../../core/storage/database.dart';
import '../../core/time/period.dart';
import 'models.dart';

class LedgerRepository {
  LedgerRepository(this.db, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() clock;
  final _changes = StreamController<void>.broadcast();
  static const _uuid = Uuid();
  String newId() => _uuid.v7();
  String get _now => utcStamp(clock());

  Stream<LedgerSnapshot> watch() async* {
    // Subscribe before the initial read so writes during bootstrap aren't lost.
    final pending = StreamController<void>();
    final subscription = _changes.stream.listen(pending.add);
    try {
      yield await snapshot();
      await for (final _ in pending.stream) {
        yield await snapshot();
      }
    } finally {
      await subscription.cancel();
      await pending.close();
    }
  }

  Future<List<QueryRow>> _rows(
    String sql, [
    List<Variable> variables = const [],
  ]) => db.customSelect(sql, variables: variables).get();

  Future<LedgerSnapshot> snapshot() => db.transaction(_readSnapshot);

  Future<LedgerSnapshot> _readSnapshot() async {
    final profiles = await _rows('SELECT * FROM local_profile');
    Profile? profile;
    if (profiles.isNotEmpty) {
      final p = profiles.single;
      profile = Profile(
        p.read<String>('base_currency'),
        p.read<String>('timezone'),
        p.read<int>('week_start'),
        reduceMotion: p.read<int>('reduce_motion') == 1,
        reduceTransparency: p.read<int>('reduce_transparency') == 1,
        budgetSignals: p.read<int>('notifications') == 1,
      );
    }
    final categories =
        (await _rows('SELECT * FROM categories ORDER BY is_system DESC, rowid'))
            .map(
              (r) => Category(
                r.read<String>('id'),
                r.read<String>('name'),
                r.read<String>('icon_key'),
                r.read<String>('color_key'),
                r.read<int>('is_system') == 1,
                r.read<int>('is_archived') == 1,
              ),
            )
            .toList();
    final expenses =
        (await _rows(
              'SELECT * FROM expenses WHERE deleted_at_utc IS NULL ORDER BY occurred_at_utc DESC, id DESC',
            ))
            .map(
              (r) => Expense(
                id: r.read<String>('id'),
                amount: Money(
                  r.read<int>('amount_minor'),
                  r.read<String>('currency_code'),
                ),
                categoryId: r.read<String>('category_id'),
                note: r.read<String>('note'),
                occurredAt: DateTime.parse(r.read<String>('occurred_at_utc')),
                createdAt: DateTime.parse(r.read<String>('created_at_utc')),
                updatedAt: DateTime.parse(r.read<String>('updated_at_utc')),
              ),
            )
            .toList();
    final budgets =
        (await _rows('SELECT * FROM budgets WHERE deleted_at_utc IS NULL'))
            .map(
              (r) => Budget(
                r.read<String>('id'),
                r.read<String>('period_type'),
                Money(
                  r.read<int>('amount_minor'),
                  r.read<String>('currency_code'),
                ),
                DateTime.parse(r.read<String>('updated_at_utc')),
              ),
            )
            .toList();
    final alerts = <String>[];
    if (profile != null && profile.budgetSignals) {
      for (final b in budgets) {
        final range = CalendarRange.containing(
          clock(),
          profile.timezone,
          b.period == 'week' ? Period.week : Period.month,
          weekStart: profile.weekStart,
        );
        final delivered = await _rows(
          'SELECT threshold FROM alert_deliveries WHERE budget_id=? AND period_start=? ORDER BY threshold',
          [Variable(b.id), Variable(utcStamp(range.start))],
        );
        for (final r in delivered) {
          alerts.add(
            '${b.period == 'week' ? 'Weekly' : 'Monthly'} budget reached ${r.read<int>('threshold')}% this period.',
          );
        }
      }
    }
    return LedgerSnapshot(profile, categories, expenses, budgets, alerts);
  }

  Future<void> saveProfile(
    String currency,
    String timezone,
    int weekStart, {
    bool reduceMotion = false,
    bool reduceTransparency = false,
    bool budgetSignals = true,
  }) async {
    Money.exponent(currency);
    tz.getLocation(timezone);
    if (weekStart < 1 || weekStart > 7) {
      throw const FormatException('Choose a valid week start.');
    }
    await db.transaction(() async {
      final old = await _rows('SELECT base_currency FROM local_profile');
      if (old.isNotEmpty &&
          old.single.read<String>('base_currency') != currency) {
        final entries = await _rows('SELECT id FROM expenses LIMIT 1');
        final caps = await _rows(
          'SELECT id FROM budgets WHERE deleted_at_utc IS NULL LIMIT 1',
        );
        if (entries.isNotEmpty || caps.isNotEmpty) {
          throw const FormatException(
            'Currency is locked while expense history or budgets exist. Export and erase to start a new book.',
          );
        }
      }
      await db.customStatement(
        '''INSERT INTO local_profile(id,base_currency,timezone,week_start,reduce_motion,reduce_transparency,notifications,created_at_utc)
        VALUES('local',?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET base_currency=excluded.base_currency,
        timezone=excluded.timezone,week_start=excluded.week_start,reduce_motion=excluded.reduce_motion,
        reduce_transparency=excluded.reduce_transparency, notifications=excluded.notifications''',
        [
          currency,
          timezone,
          weekStart,
          reduceMotion ? 1 : 0,
          reduceTransparency ? 1 : 0,
          budgetSignals ? 1 : 0,
          _now,
        ],
      );
      await _checkThresholds();
    });
    _changes.add(null);
  }

  Future<void> saveExpense({
    required String id,
    required Money amount,
    required String categoryId,
    required String note,
    required DateTime occurredAt,
    bool editing = false,
  }) async {
    if (amount.minor <= 0 || amount.minor > Money.maxMinor) {
      throw const FormatException('Enter a valid positive amount.');
    }
    final cleanNote = note
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .trim();
    if (cleanNote.runes.length > 280) {
      throw const FormatException('Notes are limited to 280 characters.');
    }
    await db.transaction(() async {
      final profile = await _rows('SELECT base_currency FROM local_profile');
      if (profile.isEmpty ||
          profile.single.read<String>('base_currency') != amount.currency) {
        throw const FormatException('Expense currency must match your book.');
      }
      final category = await _rows(
        'SELECT is_archived FROM categories WHERE id=?',
        [Variable(categoryId)],
      );
      final existing = await _rows(
        'SELECT category_id,deleted_at_utc FROM expenses WHERE id=?',
        [Variable(id)],
      );
      if (category.isEmpty ||
          (category.single.read<int>('is_archived') == 1 &&
              (!editing ||
                  existing.isEmpty ||
                  existing.single.read<String>('category_id') != categoryId))) {
        throw const FormatException('Choose an active category.');
      }
      if (editing) {
        if (existing.isEmpty ||
            existing.single.readNullable<String>('deleted_at_utc') != null) {
          throw const FormatException('This expense no longer exists.');
        }
        await db.customStatement(
          'UPDATE expenses SET amount_minor=?,category_id=?,note=?,occurred_at_utc=?,updated_at_utc=? WHERE id=? AND deleted_at_utc IS NULL',
          [amount.minor, categoryId, cleanNote, utcStamp(occurredAt), _now, id],
        );
      } else {
        // A repeated submission retains the original financial record.
        await db.customStatement(
          '''INSERT INTO expenses(id,amount_minor,currency_code,category_id,note,occurred_at_utc,created_at_utc,updated_at_utc)
          VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(id) DO NOTHING''',
          [
            id,
            amount.minor,
            amount.currency,
            categoryId,
            cleanNote,
            utcStamp(occurredAt),
            _now,
            _now,
          ],
        );
      }
      await _checkThresholds();
    });
    _changes.add(null);
  }

  Future<void> deleteExpense(String id) => _mutate(() async {
    await db.customStatement(
      'UPDATE expenses SET deleted_at_utc=?,updated_at_utc=? WHERE id=? AND deleted_at_utc IS NULL',
      [_now, _now, id],
    );
  });
  Future<void> undoDelete(String id) => _mutate(() async {
    await db.customStatement(
      'UPDATE expenses SET deleted_at_utc=NULL,updated_at_utc=? WHERE id=?',
      [_now, id],
    );
  });

  Future<void> saveCategory({
    String? id,
    required String name,
    String icon = '7',
    String color = 'forest',
  }) async {
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.runes.length > 40) {
      throw const FormatException('Use a category name of 1–40 characters.');
    }
    await _mutate(() async {
      final all = await _rows('SELECT * FROM categories');
      if (all.any(
        (c) =>
            c.read<String>('id') != id &&
            c.read<String>('name').toLowerCase() == normalized.toLowerCase(),
      )) {
        throw const FormatException(
          'A category with that name already exists.',
        );
      }
      if (id == null) {
        await db.customStatement(
          'INSERT INTO categories(id,name,icon_key,color_key) VALUES(?,?,?,?)',
          [newId(), normalized, icon, color],
        );
      } else {
        final found = all.where((c) => c.read<String>('id') == id);
        if (found.isEmpty || found.single.read<int>('is_system') == 1) {
          throw const FormatException('System categories cannot be renamed.');
        }
        await db.customStatement(
          'UPDATE categories SET name=?,icon_key=?,color_key=? WHERE id=?',
          [normalized, icon, color, id],
        );
      }
    });
  }

  Future<void> archiveCategory(String id, bool archived) => _mutate(() async {
    await db.customStatement(
      'UPDATE categories SET is_archived=? WHERE id=? AND is_system=0',
      [archived ? 1 : 0, id],
    );
  });

  Future<void> saveBudget(String period, Money amount) async {
    if (!['week', 'month'].contains(period) ||
        amount.minor <= 0 ||
        amount.minor > Money.maxMinor) {
      throw const FormatException('Enter a valid weekly or monthly cap.');
    }
    await _mutate(() async {
      final p = await _rows('SELECT base_currency FROM local_profile');
      if (p.isEmpty ||
          p.single.read<String>('base_currency') != amount.currency) {
        throw const FormatException('Budget currency must match your book.');
      }
      final current = await _rows(
        'SELECT id FROM budgets WHERE period_type=? AND deleted_at_utc IS NULL',
        [Variable(period)],
      );
      if (current.isEmpty) {
        await db.customStatement(
          'INSERT INTO budgets(id,period_type,amount_minor,currency_code,updated_at_utc) VALUES(?,?,?,?,?)',
          [newId(), period, amount.minor, amount.currency, _now],
        );
      } else {
        await db.customStatement(
          'UPDATE budgets SET amount_minor=?,updated_at_utc=? WHERE id=?',
          [amount.minor, _now, current.single.read<String>('id')],
        );
      }
    });
  }

  Future<void> removeBudget(String id) => _mutate(() async {
    await db.customStatement(
      'UPDATE budgets SET deleted_at_utc=?,updated_at_utc=? WHERE id=?',
      [_now, _now, id],
    );
  });

  Future<void> _mutate(Future<void> Function() operation) async {
    await db.transaction(() async {
      await operation();
      await _checkThresholds();
    });
    _changes.add(null);
  }

  Future<void> refreshCalendar() async {
    await db.transaction(_checkThresholds);
    _changes.add(null);
  }

  Future<void> _checkThresholds() async {
    final profiles = await _rows('SELECT * FROM local_profile');
    if (profiles.isEmpty) return;
    final p = profiles.single;
    if (p.read<int>('notifications') == 0) return;
    for (final b in await _rows(
      'SELECT * FROM budgets WHERE deleted_at_utc IS NULL',
    )) {
      final range = CalendarRange.containing(
        clock(),
        p.read<String>('timezone'),
        b.read<String>('period_type') == 'week' ? Period.week : Period.month,
        weekStart: p.read<int>('week_start'),
      );
      final rows = await _rows(
        '''SELECT amount_minor FROM expenses WHERE deleted_at_utc IS NULL
        AND occurred_at_utc>=? AND occurred_at_utc<? AND currency_code=?''',
        [
          Variable(utcStamp(range.start)),
          Variable(utcStamp(range.end)),
          Variable(p.read<String>('base_currency')),
        ],
      );
      // Dart integers avoid SQLite SUM overflow for large ledgers.
      final total = rows.fold<BigInt>(
        BigInt.zero,
        (sum, r) => sum + BigInt.from(r.read<int>('amount_minor')),
      );
      for (final threshold in [75, 90, 100]) {
        if (total * BigInt.from(100) >=
            BigInt.from(b.read<int>('amount_minor')) * BigInt.from(threshold)) {
          await db.customStatement(
            'INSERT OR IGNORE INTO alert_deliveries(budget_id,period_start,threshold,delivered_at_utc) VALUES(?,?,?,?)',
            [b.read<String>('id'), utcStamp(range.start), threshold, _now],
          );
        }
      }
    }
  }

  Future<String> exportCsv() async {
    final data = await snapshot();
    String cell(String value) {
      final protected = RegExp(r'^\s*[=+@\-\t\r]').hasMatch(value)
          ? "'$value"
          : value;
      return '"${protected.replaceAll('"', '""')}"';
    }

    final lines = <List<String>>[
      [
        'schema_version',
        'id',
        'amount_minor',
        'amount',
        'currency',
        'category',
        'note',
        'occurred_at_utc',
        'created_at_utc',
        'updated_at_utc',
      ],
      for (final e in data.expenses)
        [
          '1',
          e.id,
          '${e.amount.minor}',
          e.amount.decimal,
          e.amount.currency,
          data.category(e.categoryId).name,
          e.note,
          utcStamp(e.occurredAt),
          utcStamp(e.createdAt),
          utcStamp(e.updatedAt),
        ],
    ];
    return '${lines.map((row) => row.map(cell).join(',')).join('\r\n')}\r\n';
  }

  Future<void> erase(String confirmation) async {
    if (confirmation != 'ERASE') {
      throw const FormatException('Type ERASE to confirm.');
    }
    await db.transaction(() async {
      for (final table in [
        'alert_deliveries',
        'budgets',
        'expenses',
        'local_profile',
      ]) {
        await db.customStatement(
          'DELETE FROM $table',
        ); // Fixed table allowlist, never user input.
      }
      await db.customStatement('DELETE FROM categories WHERE is_system=0');
    });
    _changes.add(null);
  }

  Future<void> close() async {
    await _changes.close();
    await db.close();
  }
}
