import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/core/money.dart';

void main() {
  test('round2 half away from zero', () {
    expect(Money.round2(0.285), 0.29);
    expect(Money.round2(1.005), 1.01);
    expect(Money.round2(-1.005), -1.01);
    expect(Money.round2(2.344), 2.34);
  });

  test('sum is exact to the cent', () {
    expect(Money.sum(List.filled(10, 0.1)), 1.0);
    expect(Money.sum([0.1, 0.2]), 0.3);
  });

  test('format', () {
    expect(Money.format(1234567.5), '1,234,567.50');
    expect(Money.format(-12.3), '-12.30');
    expect(Money.format(0), '0.00');
  });
}
