import 'dart:async';

import '../core/constants.dart';
import '../core/dates.dart';
import '../core/money.dart';
import '../data/pos/pos_client.dart';

class DayBalance {
  const DayBalance({
    required this.date,
    required this.ventas,
    required this.pagos,
    required this.totalDiscounts,
    required this.crossDayCollections,
    this.error,
  });

  final DateTime date;
  final double ventas;
  final double pagos;
  final double totalDiscounts;
  final double crossDayCollections;
  final String? error;

  /// Ventas − Pagos.
  double get difference => Money.round2(ventas - pagos);

  /// gap − totalDiscounts + crossDayCollections.
  double get unexplained => Money.round2(difference - totalDiscounts + crossDayCollections);

  bool get isBalanced => difference.abs() <= 0.005;
}

/// Per-day Ventas vs Pagos, ≤5 days in parallel, sorted by |difference|.
class BalanceDiagnosticService {
  BalanceDiagnosticService(this.pos, {this.maxParallel = 5});

  final PosClient pos;
  final int maxParallel;

  Future<List<DayBalance>> diagnose(DateTime from, DateTime to, {void Function(int done, int total)? onProgress}) async {
    final days = [
      for (var d = Dates.dateOnly(from); !d.isAfter(Dates.dateOnly(to)); d = Dates.addDays(d, 1)) d,
    ];
    final results = <DayBalance>[];
    var next = 0;
    var done = 0;

    Future<void> worker() async {
      while (next < days.length) {
        final d = days[next++];
        results.add(await _day(d));
        onProgress?.call(++done, days.length);
      }
    }

    await Future.wait([for (var i = 0; i < maxParallel && i < days.length; i++) worker()]);
    results.sort((a, b) {
      final c = b.difference.abs().compareTo(a.difference.abs());
      return c != 0 ? c : a.date.compareTo(b.date);
    });
    return results;
  }

  Future<DayBalance> _day(DateTime d) async {
    try {
      final summaryF = pos.getSalesSummary(d, d);
      final drillF = pos.getDayDrillDown(d);
      final s = await summaryF;
      final drill = await drillF;
      return DayBalance(
        date: d,
        ventas: s.totalByGroup(PosGroups.ventas),
        pagos: s.totalByGroup(PosGroups.pagos),
        totalDiscounts: Money.round2(s.totalDiscounts),
        crossDayCollections: Money.round2(drill.crossDayCollectionsTotal),
      );
    } catch (e) {
      return DayBalance(date: d, ventas: 0, pagos: 0, totalDiscounts: 0, crossDayCollections: 0, error: e.toString());
    }
  }
}
