import '../../core/dates.dart';

double _num(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
}

bool _bool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí';
}

/// Reads a key trying PascalCase, camelCase and snake_case variants.
Object? _pick(Map<String, dynamic> j, String pascal) {
  if (j.containsKey(pascal)) return j[pascal];
  final camel = pascal[0].toLowerCase() + pascal.substring(1);
  if (j.containsKey(camel)) return j[camel];
  final snake = pascal.replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (m) => '_${m[1]}').toLowerCase();
  return j[snake];
}

/// One row of `/cse.api.v1/SalesByMethod` (one per day with sales).
class SalesByMethodRow {
  const SalesByMethodRow({
    this.date,
    this.totalSales = 0,
    this.subtotal = 0,
    this.totalDiscounts = 0,
    this.totalCityTax = 0,
    this.totalStateTax = 0,
    this.cashPayments = 0,
    this.creditCardPayments = 0,
    this.debitCardPayments = 0,
    this.checkPayments = 0,
    this.athMovilPayments = 0,
    this.raw = const {},
  });

  final DateTime? date;
  final double totalSales;
  final double subtotal;
  final double totalDiscounts;
  final double totalCityTax;
  final double totalStateTax;
  final double cashPayments;
  final double creditCardPayments;
  final double debitCardPayments;
  final double checkPayments;
  final double athMovilPayments;
  final Map<String, dynamic> raw;

  factory SalesByMethodRow.fromJson(Map<String, dynamic> j) => SalesByMethodRow(
        date: Dates.tryParseDate(_pick(j, 'Date') ?? _pick(j, 'SaleDate') ?? _pick(j, 'Fecha')),
        totalSales: _num(_pick(j, 'TotalSales')),
        subtotal: _num(_pick(j, 'Subtotal')),
        totalDiscounts: _num(_pick(j, 'TotalDiscounts')),
        totalCityTax: _num(_pick(j, 'TotalCityTax')),
        totalStateTax: _num(_pick(j, 'TotalStateTax')),
        cashPayments: _num(_pick(j, 'CashPayments')),
        creditCardPayments: _num(_pick(j, 'CreditCardPayments')),
        debitCardPayments: _num(_pick(j, 'DebitCardPayments')),
        checkPayments: _num(_pick(j, 'CheckPayments')),
        athMovilPayments: _num(_pick(j, 'AthMovilPayments')),
        raw: j,
      );
}

class ArPayment {
  const ArPayment({required this.postingDate, required this.amount});
  final DateTime? postingDate;
  final double amount;

  factory ArPayment.fromJson(Map<String, dynamic> j) => ArPayment(
        postingDate: Dates.tryParseDate(j['posting_date'] ?? j['PostingDate']),
        amount: _num(j['amount'] ?? j['Amount']),
      );
}

class ArInvoice {
  const ArInvoice({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.invoiceTotal,
    required this.creditSale,
    this.customerName,
    this.status,
    this.remainingBalance,
    this.payments = const [],
  });

  final String invoiceNumber;
  final DateTime? invoiceDate;
  final double invoiceTotal;
  final bool creditSale;
  final String? customerName;
  final String? status;
  final double? remainingBalance;
  final List<ArPayment> payments;

  factory ArInvoice.fromJson(Map<String, dynamic> j) => ArInvoice(
        invoiceNumber: (j['invoice_number'] ?? j['InvoiceNumber'] ?? '').toString(),
        invoiceDate: Dates.tryParseDate(j['invoice_date'] ?? j['InvoiceDate']),
        invoiceTotal: _num(j['invoice_total'] ?? j['InvoiceTotal']),
        creditSale: _bool(j['credit_sale'] ?? j['CreditSale']),
        customerName: (j['customer_name'] ?? j['CustomerName'])?.toString(),
        status: (j['status'] ?? j['Status'])?.toString(),
        remainingBalance: (j['remaining_balance'] ?? j['RemainingBalance']) == null
            ? null
            : _num(j['remaining_balance'] ?? j['RemainingBalance']),
        payments: ((j['payments'] ?? j['Payments']) as List? ?? const [])
            .whereType<Map>()
            .map((p) => ArPayment.fromJson(p.cast<String, dynamic>()))
            .toList(),
      );
}

class ArInvoicePage {
  const ArInvoicePage({required this.success, required this.page, required this.totalPages, required this.data});
  final bool success;
  final int page;
  final int totalPages;
  final List<ArInvoice> data;

  factory ArInvoicePage.fromJson(Map<String, dynamic> j) => ArInvoicePage(
        success: j['success'] == null ? true : _bool(j['success']),
        page: _num(j['page']).toInt(),
        totalPages: _num(j['total_pages']).toInt(),
        data: (j['data'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ArInvoice.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

/// A payment received on [date] for an invoice dated earlier.
class CrossDayCollection {
  const CrossDayCollection({required this.invoice, required this.payment});
  final ArInvoice invoice;
  final ArPayment payment;
}

/// Raw data behind one day's totals ("Ver Detalle").
class DayDrillDown {
  const DayDrillDown({
    required this.date,
    required this.salesRows,
    required this.invoices,
    required this.crossDayCollections,
  });

  final DateTime date;
  final List<SalesByMethodRow> salesRows;
  final List<ArInvoice> invoices;
  final List<CrossDayCollection> crossDayCollections;

  double get totalDiscounts => salesRows.fold(0, (a, r) => a + r.totalDiscounts);
  double get crossDayCollectionsTotal => crossDayCollections.fold(0, (a, c) => a + c.payment.amount);
}

class PosConnectionTestResult {
  const PosConnectionTestResult({
    required this.ok,
    required this.message,
    this.latency,
    this.rowCount,
    this.statusCode,
  });

  final bool ok;
  final String message;
  final Duration? latency;
  final int? rowCount;
  final int? statusCode;
}
