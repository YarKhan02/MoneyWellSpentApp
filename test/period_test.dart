import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:money_well_spent/core/time/period.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  test('DST days use local calendar boundaries, not 24 hours', () {
    final spring = CalendarRange.containing(
      DateTime.utc(2026, 3, 8, 12),
      'America/New_York',
      Period.day,
    );
    final autumn = CalendarRange.containing(
      DateTime.utc(2026, 11, 1, 12),
      'America/New_York',
      Period.day,
    );
    expect(spring.end.difference(spring.start).inHours, 23);
    expect(autumn.end.difference(autumn.start).inHours, 25);
    expect(spring.contains(spring.start), isTrue);
    expect(spring.contains(spring.end), isFalse);
  });
  test('leap year, week rollover and configurable week start', () {
    final leap = CalendarRange.containing(
      DateTime.utc(2024, 2, 29),
      'UTC',
      Period.month,
    );
    expect(leap.end.difference(leap.start).inDays, 29);
    final week = CalendarRange.containing(
      DateTime.utc(2026, 1, 1),
      'UTC',
      Period.week,
    );
    expect(week.start, DateTime.utc(2025, 12, 29));
    final sunday = CalendarRange.containing(
      DateTime.utc(2026, 1, 1),
      'UTC',
      Period.week,
      weekStart: 7,
    );
    expect(sunday.start, DateTime.utc(2025, 12, 28));
  });
}
