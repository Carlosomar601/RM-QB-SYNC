import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/pos/pos_dtos.dart';
import '../../data/pos/pos_providers.dart';
import '../../services/balance_diagnostic_service.dart';
import '../../services/service_providers.dart';
import '../../ui/guided/guided.dart';

String _m(num v) => Money.format(v);

/// "Diagnosticar Diferencia": per-day Ventas vs Pagos.
Future<void> showBalanceDiagnostic(BuildContext context, WidgetRef ref, DateTime from, DateTime to) => showDialog<void>(
      context: context,
      builder: (_) => _DiagnosticDialog(from: from, to: to),
    );

class _DiagnosticDialog extends ConsumerStatefulWidget {
  const _DiagnosticDialog({required this.from, required this.to});
  final DateTime from;
  final DateTime to;

  @override
  ConsumerState<_DiagnosticDialog> createState() => _DiagnosticDialogState();
}

class _DiagnosticDialogState extends ConsumerState<_DiagnosticDialog> {
  List<DayBalance>? _result;
  int _done = 0;
  int _total = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref
        .read(balanceDiagnosticProvider)
        .diagnose(widget.from, widget.to, onProgress: (d, t) {
          if (mounted) {
            setState(() {
              _done = d;
              _total = t;
            });
          }
        })
        .then((r) => mounted ? setState(() => _result = r) : null)
        .catchError((Object e) => mounted ? setState(() => _error = '$e') : null);
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return AlertDialog(
      title: const Text('Diagnóstico de diferencia por día'),
      content: SizedBox(
        width: 900,
        child: r == null
            ? (_error != null
                ? GuidanceBanner(kind: GuidanceKind.error, title: 'Error', message: _error)
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    LinearProgressIndicator(value: _done / _total),
                    const SizedBox(height: 8),
                    Text('Consultando el POS: $_done de $_total días…'),
                  ]))
            : SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Diferencia = Ventas − Pagos. "Sin explicar" = diferencia − descuentos + cobros cruzados. '
                      'Los días con mayor diferencia aparecen primero.'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(columns: const [
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Ventas'), numeric: true),
                      DataColumn(label: Text('Pagos'), numeric: true),
                      DataColumn(label: Text('Diferencia'), numeric: true),
                      DataColumn(label: Text('Descuentos'), numeric: true),
                      DataColumn(label: Text('Cobros cruzados'), numeric: true),
                      DataColumn(label: Text('Sin explicar'), numeric: true),
                      DataColumn(label: Text('')),
                    ], rows: [
                      for (final d in r)
                        DataRow(cells: [
                          DataCell(Text(Dates.dmy(d.date))),
                          DataCell(Text(d.error != null ? '—' : _m(d.ventas))),
                          DataCell(Text(d.error != null ? '—' : _m(d.pagos))),
                          DataCell(Text(d.error != null ? 'Error' : _m(d.difference),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: d.isBalanced ? null : context.rm.dangerText))),
                          DataCell(Text(_m(d.totalDiscounts))),
                          DataCell(Text(_m(d.crossDayCollections))),
                          DataCell(Text(_m(d.unexplained))),
                          DataCell(TextButton(
                            onPressed: () => showDayDrillDown(context, d.date),
                            child: const Text('Ver detalle'),
                          )),
                        ]),
                    ]),
                  ),
                ]),
              ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
    );
  }
}

/// "Ver Detalle": raw POS rows for one day.
Future<void> showDayDrillDown(BuildContext context, DateTime day) =>
    showDialog<void>(context: context, builder: (_) => _DrillDownDialog(day: day));

class _DrillDownDialog extends ConsumerWidget {
  const _DrillDownDialog({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Detalle del POS – ${Dates.dmy(day)}'),
      content: SizedBox(
        width: 900,
        child: FutureBuilder<DayDrillDown>(
          future: ref.read(posClientProvider).getDayDrillDown(day),
          builder: (context, snap) {
            if (snap.hasError) return GuidanceBanner(kind: GuidanceKind.error, title: 'Error', message: '${snap.error}');
            if (!snap.hasData) return const LoadingBox(message: 'Consultando el POS…');
            final d = snap.data!;
            final t = Theme.of(context).textTheme;
            return SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ventas por forma de pago (SalesByMethod)', style: t.titleSmall),
                if (d.salesRows.isEmpty) const Text('Sin ventas este día.'),
                for (final r in d.salesRows)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(columns: const [
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('Subtotal'), numeric: true),
                      DataColumn(label: Text('Desc.'), numeric: true),
                      DataColumn(label: Text('IVU mun.'), numeric: true),
                      DataColumn(label: Text('IVU est.'), numeric: true),
                      DataColumn(label: Text('Efectivo'), numeric: true),
                      DataColumn(label: Text('T. crédito'), numeric: true),
                      DataColumn(label: Text('T. débito'), numeric: true),
                      DataColumn(label: Text('Cheques'), numeric: true),
                      DataColumn(label: Text('ATH'), numeric: true),
                    ], rows: [
                      DataRow(cells: [
                        for (final v in [
                          r.totalSales,
                          r.subtotal,
                          r.totalDiscounts,
                          r.totalCityTax,
                          r.totalStateTax,
                          r.cashPayments,
                          r.creditCardPayments,
                          r.debitCardPayments,
                          r.checkPayments,
                          r.athMovilPayments
                        ])
                          DataCell(Text(_m(v))),
                      ]),
                    ]),
                  ),
                const SizedBox(height: 16),
                Text('Facturas del día (${d.invoices.length})', style: t.titleSmall),
                for (final i in d.invoices)
                  ListTile(
                    dense: true,
                    title: Text('${i.invoiceNumber} · ${i.customerName ?? ''} · \$${_m(i.invoiceTotal)}'),
                    subtitle: Text('${i.creditSale ? 'Venta a crédito' : 'Contado'} · ${i.status ?? ''}'
                        '${i.remainingBalance != null ? ' · Balance \$${_m(i.remainingBalance!)}' : ''}'),
                  ),
                const SizedBox(height: 16),
                Text('Cobros cruzados (pagos hoy de facturas anteriores): \$${_m(d.crossDayCollectionsTotal)}', style: t.titleSmall),
                for (final c in d.crossDayCollections)
                  ListTile(
                    dense: true,
                    title: Text('${c.invoice.invoiceNumber} (${c.invoice.invoiceDate == null ? '' : Dates.dmy(c.invoice.invoiceDate!)}) · '
                        '${c.invoice.customerName ?? ''}'),
                    trailing: Text('\$${_m(c.payment.amount)}'),
                  ),
              ]),
            );
          },
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
    );
  }
}
