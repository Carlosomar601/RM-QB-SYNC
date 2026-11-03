import 'dates.dart';

enum ScheduleFrequency {
  daily('Diaria'),
  weekly('Semanal'),
  monthly('Mensual');

  const ScheduleFrequency(this.label);
  final String label;

  static ScheduleFrequency parse(String v) =>
      values.firstWhere((f) => f.name.toLowerCase() == v.toLowerCase(), orElse: () => daily);
}

/// Time of day in local time.
class TimeOfDayHm {
  const TimeOfDayHm(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  final int hour;
  final int minute;

  /// Parses `HH:mm`.
  static TimeOfDayHm parse(String s) {
    final parts = s.split(':');
    return TimeOfDayHm(int.parse(parts[0]), int.parse(parts[1]));
  }

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) => other is TimeOfDayHm && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Spanish weekday names, ISO (1 = lunes … 7 = domingo).
const Map<int, String> weekdayNames = {
  1: 'Lunes',
  2: 'Martes',
  3: 'Miércoles',
  4: 'Jueves',
  5: 'Viernes',
  6: 'Sábado',
  7: 'Domingo',
};

class DateRange {
  const DateRange(this.from, this.to);
  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) => other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => '${Dates.iso(from)}..${Dates.iso(to)}';
}

/// Pure schedule math (ported from SyncScheduleCalculator).
abstract final class ScheduleCalculator {
  /// Next time strictly after [now] at which the schedule should fire.
  static DateTime nextRun({
    required ScheduleFrequency frequency,
    required TimeOfDayHm timeOfDay,
    int? dayOfWeek,
    int? dayOfMonth,
    required DateTime now,
  }) {
    DateTime at(DateTime d) => DateTime(d.year, d.month, d.day, timeOfDay.hour, timeOfDay.minute);
    final today = Dates.dateOnly(now);

    switch (frequency) {
      case ScheduleFrequency.daily:
        final candidate = at(today);
        return candidate.isAfter(now) ? candidate : at(Dates.addDays(today, 1));

      case ScheduleFrequency.weekly:
        final target = (dayOfWeek ?? 1).clamp(1, 7);
        final current = now.weekday; // ISO: Monday=1..Sunday=7
        var candidate = at(Dates.addDays(today, (target - current + 7) % 7));
        if (!candidate.isAfter(now)) candidate = at(Dates.addDays(Dates.dateOnly(candidate), 7));
        return candidate;

      case ScheduleFrequency.monthly:
        final dom = (dayOfMonth ?? 1).clamp(1, 28);
        DateTime forMonth(int year, int month) {
          final day = dom.clamp(1, Dates.daysInMonth(year, month));
          return at(DateTime(year, month, day));
        }

        final candidate = forMonth(now.year, now.month);
        if (candidate.isAfter(now)) return candidate;
        final next = DateTime(now.year, now.month + 1, 1);
        return forMonth(next.year, next.month);
    }
  }

  /// Date range a run fired on [runDate] should sync.
  /// Daily = today; Weekly = today−6..today; Monthly = full previous month.
  static DateRange rangeFor(ScheduleFrequency frequency, DateTime runDate) {
    final today = Dates.dateOnly(runDate);
    switch (frequency) {
      case ScheduleFrequency.daily:
        return DateRange(today, today);
      case ScheduleFrequency.weekly:
        return DateRange(Dates.addDays(today, -6), today);
      case ScheduleFrequency.monthly:
        final firstThisMonth = DateTime(today.year, today.month, 1);
        final lastPrev = Dates.addDays(firstThisMonth, -1);
        return DateRange(DateTime(lastPrev.year, lastPrev.month, 1), lastPrev);
    }
  }

  /// Human readable Spanish description of a schedule.
  static String describe({
    required ScheduleFrequency frequency,
    required TimeOfDayHm timeOfDay,
    int? dayOfWeek,
    int? dayOfMonth,
  }) {
    switch (frequency) {
      case ScheduleFrequency.daily:
        return 'Todos los días a las $timeOfDay (sincroniza el día actual)';
      case ScheduleFrequency.weekly:
        return 'Cada ${weekdayNames[dayOfWeek ?? 1]!.toLowerCase()} a las $timeOfDay '
            '(sincroniza los últimos 7 días)';
      case ScheduleFrequency.monthly:
        return 'El día ${dayOfMonth ?? 1} de cada mes a las $timeOfDay '
            '(sincroniza el mes anterior completo)';
    }
  }
}
