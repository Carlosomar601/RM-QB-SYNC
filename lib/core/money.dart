/// Money helpers. Amounts are kept as `double` for JSON compatibility but
/// every sum is accumulated in integer cents to avoid floating point drift.
abstract final class Money {
  /// Converts an amount to integer cents (half away from zero).
  static int toCents(num amount) {
    final scaled = amount * 100;
    return scaled >= 0 ? (scaled + 0.5 + 1e-9).floor() : -((-scaled + 0.5 + 1e-9).floor());
  }

  static double fromCents(int cents) => cents / 100.0;

  /// Rounds to 2 decimals (half away from zero).
  static double round2(num amount) => fromCents(toCents(amount));

  /// Sums amounts exactly to the cent.
  static double sum(Iterable<num> amounts) =>
      fromCents(amounts.fold<int>(0, (acc, a) => acc + toCents(a)));

  /// Formats as `1,234.56` (en-US style, as QuickBooks shows it).
  static String format(num amount) {
    final cents = toCents(amount);
    final negative = cents < 0;
    final abs = cents.abs();
    final whole = (abs ~/ 100).toString();
    final frac = (abs % 100).toString().padLeft(2, '0');
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '${negative ? '-' : ''}$buf.$frac';
  }
}
