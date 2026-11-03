import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/core/pos_sales_summary.dart';
import 'package:rmqbsync/data/pos/pos_client.dart';
import 'package:rmqbsync/data/pos/pos_dtos.dart';
import 'package:rmqbsync/services/balance_diagnostic_service.dart';

class _StubPos implements PosClient {
  int inFlight = 0;
  int maxInFlight = 0;

  // day → (ventas, pagos, discounts, crossDay)
  final data = <int, (double, double, double, double)>{
    1: (100, 100, 0, 0),
    2: (100, 70, 10, 0),
    3: (100, 95, 0, 5),
    4: (100, 140, 0, 0),
  };

  Future<T> _track<T>(T Function() f) async {
    inFlight++;
    maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    inFlight--;
    return f();
  }

  @override
  Future<PosSalesSummary> getSalesSummary(DateTime from, DateTime to) => _track(() {
        final d = data[from.day] ?? (0, 0, 0, 0);
        return PosSalesSummary(fromDate: from, toDate: to, totalDiscounts: d.$3, categories: [
          PosCategoryAmount('Ventas', 'VentaNeta', d.$1),
          PosCategoryAmount('Pagos', 'Efectivo', d.$2),
        ]);
      });

  @override
  Future<DayDrillDown> getDayDrillDown(DateTime day) => _track(() {
        final d = data[day.day] ?? (0, 0, 0, 0);
        return DayDrillDown(date: day, salesRows: const [], invoices: const [], crossDayCollections: [
          if (d.$4 != 0)
            CrossDayCollection(
              invoice: ArInvoice(invoiceNumber: 'X', invoiceDate: DateTime(2026, 1, 1), invoiceTotal: d.$4, creditSale: true),
              payment: ArPayment(postingDate: day, amount: d.$4),
            ),
        ]);
      });

  @override
  Future<PosConnectionTestResult> testConnection() => throw UnimplementedError();
}

void main() {
  test('per-day diff sorted by |diff|, unexplained gap, ≤5 parallel days', () async {
    final pos = _StubPos();
    final res = await BalanceDiagnosticService(pos).diagnose(DateTime(2026, 5, 1), DateTime(2026, 5, 12));
    expect(res, hasLength(12));
    expect(res.take(4).map((d) => d.date.day).toList(), [4, 2, 3, 1]);
    final d4 = res[0];
    expect(d4.difference, -40);
    final d2 = res[1];
    expect(d2.difference, 30);
    expect(d2.unexplained, 20); // 30 − 10 discounts + 0
    final d3 = res[2];
    expect(d3.difference, 5);
    expect(d3.unexplained, 10); // 5 − 0 + 5 cross-day
    // 5 days × 2 calls each in flight at most.
    expect(pos.maxInFlight, lessThanOrEqualTo(10));
  });
}
