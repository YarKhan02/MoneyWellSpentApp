import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/money/money.dart';
import '../../core/time/period.dart';
import 'models.dart';

/// Profile-aware calendar and formatting helpers.
///
/// Every date shown to a person and every period boundary is derived from the
/// book's own timezone and week-start, never the device's — so these live on
/// [Profile] rather than as free functions callers could invoke without one.
extension ProfileCalendar on Profile {
  /// The [period] window containing [anchor] (now, when omitted).
  CalendarRange range(Period period, [DateTime? anchor]) =>
      CalendarRange.containing(
        anchor ?? DateTime.now(),
        timezone,
        period,
        weekStart: weekStart,
      );

  /// The period immediately before the one containing [anchor].
  CalendarRange previousRange(Period period, [DateTime? anchor]) {
    final current = range(period, anchor);
    return range(period, current.start.subtract(const Duration(microseconds: 1)));
  }

  /// `Mon, 4 Mar 2026`, or `4 Mar 2026 · 14:30` with [time].
  String formatDate(DateTime instant, {bool time = false}) => DateFormat(
    time ? 'd MMM y · HH:mm' : 'EEE, d MMM y',
  ).format(tz.TZDateTime.from(instant, tz.getLocation(timezone)));

  /// `Mon, 2 Mar 2026 – Sun, 8 Mar 2026`. The end is exclusive in the model,
  /// so the last inclusive instant is what gets shown.
  String formatRange(CalendarRange r) =>
      '${formatDate(r.start)} – ${formatDate(r.end.subtract(const Duration(microseconds: 1)))}';

  /// A short, contextual name for a period: `Mon, 4 Mar 2026` for a day,
  /// `2 – 8 Mar 2026` for a week, `October 2026` for a month, `2026` for a
  /// year. [formatRange] still gives the exact boundaries when they matter.
  String periodLabel(CalendarRange r, Period period) {
    final location = tz.getLocation(timezone);
    final start = tz.TZDateTime.from(r.start, location);
    final lastInstant = r.end.subtract(const Duration(microseconds: 1));
    final end = tz.TZDateTime.from(lastInstant, location);
    switch (period) {
      case Period.day:
        return DateFormat('EEE, d MMM y').format(start);
      case Period.week:
        final sameMonth = start.month == end.month && start.year == end.year;
        return sameMonth
            ? '${DateFormat('d').format(start)} – ${DateFormat('d MMM y').format(end)}'
            : '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM y').format(end)}';
      case Period.month:
        return DateFormat('MMMM y').format(start);
      case Period.year:
        return DateFormat('y').format(start);
    }
  }

  /// Just the start day, e.g. `2 Mar` — for compact pills.
  String formatRangeStart(CalendarRange r) => DateFormat(
    'd MMM',
  ).format(tz.TZDateTime.from(r.start, tz.getLocation(timezone)));

  /// Wraps [minor] units in the book's own currency.
  Money money(int minor) => Money(minor, currency);
}
