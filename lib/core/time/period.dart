import 'package:timezone/timezone.dart' as tz;

enum Period { day, week, month, year }

class CalendarRange {
  const CalendarRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  factory CalendarRange.containing(
    DateTime instant,
    String timezone,
    Period period, {
    int weekStart = DateTime.monday,
  }) {
    if (weekStart < 1 || weekStart > 7) {
      throw ArgumentError.value(weekStart, 'weekStart');
    }
    final location = tz.getLocation(timezone);
    final local = tz.TZDateTime.from(instant, location);
    tz.TZDateTime start;
    tz.TZDateTime end;
    switch (period) {
      case Period.day:
        start = tz.TZDateTime(location, local.year, local.month, local.day);
        end = tz.TZDateTime(location, local.year, local.month, local.day + 1);
      case Period.week:
        final day = local.day - (local.weekday - weekStart + 7) % 7;
        start = tz.TZDateTime(location, local.year, local.month, day);
        end = tz.TZDateTime(location, local.year, local.month, day + 7);
      case Period.month:
        start = tz.TZDateTime(location, local.year, local.month);
        end = tz.TZDateTime(location, local.year, local.month + 1);
      case Period.year:
        start = tz.TZDateTime(location, local.year);
        end = tz.TZDateTime(location, local.year + 1);
    }
    return CalendarRange(start.toUtc(), end.toUtc());
  }

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);
}

/// SQLite TEXT ordering requires one precision for every stored UTC timestamp.
String utcStamp(DateTime instant) =>
    instant.toUtc().toIso8601String().replaceFirstMapped(
      RegExp(r'\.(\d+)Z$'),
      (match) => '.${match[1]!.padRight(6, '0')}Z',
    );
