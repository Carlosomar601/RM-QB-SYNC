import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/pos_sales_summary.dart';
import 'pos_dtos.dart';

/// Pure aggregation rules (ported exactly from the legacy client).
abstract final class PosAggregator {
  /// Builds the category summary.
  ///
  /// * [salesRows] – SalesByMethod rows for from..to (summed).
  /// * [rangeInvoices] – AR invoices for from..to (credit sales).
  /// * [lookbackInvoices] – AR invoices for (from−90)..to (collections).
  ///
  /// AR collections are reported as a Ventas category and are NOT added
  /// into the tender (Pagos) totals – that would double count them.
  /// TotalDiscounts is informational only.
  static PosSalesSummary summarize({
    required DateTime from,
    required DateTime to,
    required List<SalesByMethodRow> salesRows,
    required List<ArInvoice> rangeInvoices,
    required List<ArInvoice> lookbackInvoices,
  }) {
    double sum(double Function(SalesByMethodRow r) f) => Money.sum(salesRows.map(f));

    final collections = Money.sum(lookbackInvoices
        .expand((i) => i.payments)
        .where((p) => p.postingDate != null && Dates.inRange(p.postingDate!, from, to))
        .map((p) => p.amount));

    final pendiente = Money.sum(_dedupe(rangeInvoices)
        .where((i) => i.creditSale && i.invoiceDate != null && Dates.inRange(i.invoiceDate!, from, to))
        .map((i) => i.invoiceTotal));

    const v = PosGroups.ventas;
    const p = PosGroups.pagos;
    return PosSalesSummary(
      fromDate: from,
      toDate: to,
      totalDiscounts: sum((r) => r.totalDiscounts),
      categories: [
        PosCategoryAmount(v, PosCategories.ventaNeta, sum((r) => r.subtotal)),
        PosCategoryAmount(v, PosCategories.cityTax, sum((r) => r.totalCityTax)),
        PosCategoryAmount(v, PosCategories.stateTax, sum((r) => r.totalStateTax)),
        PosCategoryAmount(v, PosCategories.pagosAFacturasPendientes, collections),
        PosCategoryAmount(p, PosCategories.efectivo, sum((r) => r.cashPayments)),
        PosCategoryAmount(p, PosCategories.tarjetaCredito, sum((r) => r.creditCardPayments)),
        PosCategoryAmount(p, PosCategories.tarjetaDebito, sum((r) => r.debitCardPayments)),
        PosCategoryAmount(p, PosCategories.cheques, sum((r) => r.checkPayments)),
        PosCategoryAmount(p, PosCategories.athMovil, sum((r) => r.athMovilPayments)),
        PosCategoryAmount(p, PosCategories.pendienteDeCobro, pendiente),
      ],
    );
  }

  /// Payments posted on [day] for invoices dated before [day].
  static List<CrossDayCollection> crossDayCollections(DateTime day, List<ArInvoice> lookbackInvoices) {
    final d = Dates.dateOnly(day);
    return [
      for (final inv in _dedupe(lookbackInvoices))
        if (inv.invoiceDate != null && inv.invoiceDate!.isBefore(d))
          for (final pay in inv.payments)
            if (pay.postingDate != null && pay.postingDate == d) CrossDayCollection(invoice: inv, payment: pay),
    ];
  }

  /// Removes duplicate invoices that may appear on page boundaries.
  static List<ArInvoice> _dedupe(List<ArInvoice> list) {
    final seen = <String>{};
    return [
      for (final i in list)
        if (i.invoiceNumber.isEmpty || seen.add(i.invoiceNumber)) i,
    ];
  }
}
