/// Date-only helpers (local calendar dates, time stripped).
abstract final class Dates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today([DateTime? now]) => dateOnly(now ?? DateTime.now());

  /// Adds calendar days (DST-safe because it rebuilds from Y/M/D).
  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// `yyyy-MM-dd`
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_2(d.month)}-${_2(d.day)}';

  /// `dd/MM/yyyy`
  static String dmy(DateTime d) => '${_2(d.day)}/${_2(d.month)}/${d.year}';

  /// `dd/MM/yyyy HH:mm`
  static String dmyHm(DateTime d) => '${dmy(d)} ${_2(d.hour)}:${_2(d.minute)}';

  /// Parses `yyyy-MM-dd` or an ISO timestamp, returning the date part.
  static DateTime? tryParseDate(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    final parsed = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
    return parsed == null ? null : dateOnly(parsed);
  }

  /// Inclusive day count between two dates.
  static int dayCount(DateTime from, DateTime to) =>
      dateOnly(to).difference(dateOnly(from)).inHours ~/ 24 + 1;

  static bool inRange(DateTime d, DateTime from, DateTime to) {
    final x = dateOnly(d);
    return !x.isBefore(dateOnly(from)) && !x.isAfter(dateOnly(to));
  }

  static String _2(int v) => v.toString().padLeft(2, '0');
}
