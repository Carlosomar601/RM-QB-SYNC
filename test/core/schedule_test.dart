import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/core/schedule.dart';

void main() {
  const t = TimeOfDayHm(23, 0);

  group('nextRun daily', () {
    test('later today when still ahead', () {
      expect(
        ScheduleCalculator.nextRun(frequency: ScheduleFrequency.daily, timeOfDay: t, now: DateTime(2026, 11, 3, 10)),
        DateTime(2026, 11, 3, 23),
      );
    });
    test('tomorrow when passed or exactly now', () {
      expect(
        ScheduleCalculator.nextRun(frequency: ScheduleFrequency.daily, timeOfDay: t, now: DateTime(2026, 11, 3, 23)),
        DateTime(2026, 11, 4, 23),
      );
    });
    test('crosses month/year', () {
      expect(
        ScheduleCalculator.nextRun(frequency: ScheduleFrequency.daily, timeOfDay: t, now: DateTime(2026, 12, 31, 23, 30)),
        DateTime(2027, 1, 1, 23),
      );
    });
  });

  group('nextRun weekly (ISO 1=Mon..7=Sun)', () {
    // 2026-11-03 is a Tuesday.
    test('later this week', () {
      expect(
        ScheduleCalculator.nextRun(
            frequency: ScheduleFrequency.weekly, timeOfDay: t, dayOfWeek: 5, now: DateTime(2026, 11, 3, 10)),
        DateTime(2026, 11, 6, 23),
      );
    });
    test('same day still ahead', () {
      expect(
        ScheduleCalculator.nextRun(
            frequency: ScheduleFrequency.weekly, timeOfDay: t, dayOfWeek: 2, now: DateTime(2026, 11, 3, 10)),
        DateTime(2026, 11, 3, 23),
      );
    });
    test('same day already passed -> next week', () {
      expect(
        ScheduleCalculator.nextRun(
            frequency: ScheduleFrequency.weekly, timeOfDay: t, dayOfWeek: 2, now: DateTime(2026, 11, 3, 23, 1)),
        DateTime(2026, 11, 10, 23),
      );
    });
    test('sunday = 7', () {
      expect(
        ScheduleCalculator.nextRun(
            frequency: ScheduleFrequency.weekly, timeOfDay: t, dayOfWeek: 7, now: DateTime(2026, 11, 3, 10)),
        DateTime(2026, 11, 8, 23),
      );
    });
  });

  group('nextRun monthly', () {
    test('later this month', () {
      expect(
        ScheduleCalculator.nextRun(
            frequency: ScheduleFrequency.monthly, timeOfDay: t, dayOfMonth: 15, now: DateTime(2026, 11, 3)),
        DateTime(2026, 11, 15, 23),
      );
    });
    test('passed -> next month, december rolls to january', () {
      expect(
        ScheduleCalculator.nextRun(
            frequency: ScheduleFrequency.monthly, timeOfDay: t, dayOfMonth: 1, now: DateTime(2026, 12, 5)),
        DateTime(2027, 1, 1, 23),
      );
    });
    test('day clamped to 28 and to month length', () {
      expect(
        ScheduleCalculator.nextRun(
            frequency: ScheduleFrequency.monthly, timeOfDay: t, dayOfMonth: 31, now: DateTime(2027, 2, 1)),
        DateTime(2027, 2, 28, 23),
      );
    });
  });

  group('rangeFor', () {
    final d = DateTime(2026, 3, 10, 23);
    test('daily', () {
      expect(ScheduleCalculator.rangeFor(ScheduleFrequency.daily, d), DateRange(DateTime(2026, 3, 10), DateTime(2026, 3, 10)));
    });
    test('weekly = today-6..today', () {
      expect(ScheduleCalculator.rangeFor(ScheduleFrequency.weekly, d), DateRange(DateTime(2026, 3, 4), DateTime(2026, 3, 10)));
    });
    test('monthly = full previous month (leap/non-leap Feb)', () {
      expect(ScheduleCalculator.rangeFor(ScheduleFrequency.monthly, d), DateRange(DateTime(2026, 2, 1), DateTime(2026, 2, 28)));
      expect(ScheduleCalculator.rangeFor(ScheduleFrequency.monthly, DateTime(2028, 3, 1)),
          DateRange(DateTime(2028, 2, 1), DateTime(2028, 2, 29)));
      expect(ScheduleCalculator.rangeFor(ScheduleFrequency.monthly, DateTime(2027, 1, 15)),
          DateRange(DateTime(2026, 12, 1), DateTime(2026, 12, 31)));
    });
  });
}
