import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/core/constants.dart';
import 'package:rmqbsync/core/exceptions.dart';
import 'package:rmqbsync/data/pos/pos_client.dart';

import '../helpers/fake_adapter.dart';

void main() {
  final sales = jsonDecode(File('test/fixtures/pos/sales_by_method.json').readAsStringSync());
  final ar = jsonDecode(File('test/fixtures/pos/ar_invoices.json').readAsStringSync()) as Map<String, dynamic>;

  Future<FakeResponse> handler(RequestOptions o) async {
    if (o.path.endsWith('SalesByMethod')) return FakeResponse(200, sales);
    if (o.path.endsWith('ARReconciliationInvoices')) {
      final from = o.queryParameters['date_from'];
      final page = o.queryParameters['page'];
      if (from == '2026-05-01') return FakeResponse(200, ar['range_page_$page']);
      return FakeResponse(200, ar['lookback_page_1']);
    }
    return const FakeResponse(404, {});
  }

  RetailManagerPosClient client(FakeAdapter a) =>
      RetailManagerPosClient(Dio(BaseOptions(baseUrl: 'http://pos.test:8180'))..httpClientAdapter = a);

  test('aggregates categories exactly (fixture)', () async {
    final a = FakeAdapter(handler);
    final s = await client(a).getSalesSummary(DateTime(2026, 5, 1), DateTime(2026, 5, 2));
    final byCat = {for (final c in s.categories) c.category: c.amount};

    expect(byCat[PosCategories.ventaNeta], 1960.31);
    expect(byCat[PosCategories.cityTax], 19.60);
    expect(byCat[PosCategories.stateTax], 205.83);
    expect(byCat[PosCategories.pagosAFacturasPendientes], 100.00); // 60 + 40 in range, 25 out of range
    expect(byCat[PosCategories.efectivo], 700.10);
    expect(byCat[PosCategories.tarjetaCredito], 630.25);
    expect(byCat[PosCategories.tarjetaDebito], 399.90);
    expect(byCat[PosCategories.cheques], 50.00);
    expect(byCat[PosCategories.athMovil], 179.63);
    expect(byCat[PosCategories.pendienteDeCobro], 195.50); // F-100 + F-102 (credit sales)
    expect(s.totalDiscounts, 15.00);
    expect(s.categories.map((c) => c.category), isNot(contains('TotalDiscounts')));

    // AR collections are Ventas, never added to tenders.
    expect(s.totalByGroup('Pagos'), 700.10 + 630.25 + 399.90 + 50.00 + 179.63 + 195.50);

    // Three logical calls; AR range paged twice.
    final arCalls = a.requests.where((r) => r.path.endsWith('ARReconciliationInvoices')).toList();
    expect(arCalls.where((r) => r.queryParameters['date_from'] == '2026-05-01'), hasLength(2));
    expect(arCalls.where((r) => r.queryParameters['date_from'] == '2026-01-31'), hasLength(1));
    final sbm = a.requests.firstWhere((r) => r.path.endsWith('SalesByMethod'));
    expect(sbm.queryParameters, {'DateFrom': '2026-05-01', 'DateTo': '2026-05-02'});
  });

  test('paging stops at MaxPages', () async {
    final a = FakeAdapter((o) async => const FakeResponse(200, {
          'success': true,
          'page': 1,
          'total_pages': 100000,
          'data': [
            {'invoice_number': 'X', 'invoice_date': '2026-05-01', 'invoice_total': 1, 'credit_sale': false, 'payments': []}
          ]
        }));
    final list = await client(a).fetchArInvoices(DateTime(2026, 5, 1), DateTime(2026, 5, 1));
    expect(a.requests, hasLength(PosConstants.maxPages));
    expect(list, hasLength(PosConstants.maxPages));
  });

  test('day drill-down finds cross-day collections', () async {
    final a = FakeAdapter((o) async {
      if (o.path.endsWith('SalesByMethod')) return FakeResponse(200, [(sales as List)[0]]);
      if (o.queryParameters['date_from'] == '2026-05-01') return FakeResponse(200, ar['range_page_1']..['total_pages'] = 1);
      return FakeResponse(200, ar['lookback_page_1']);
    });
    final d = await client(a).getDayDrillDown(DateTime(2026, 5, 1));
    expect(d.salesRows, hasLength(1));
    expect(d.crossDayCollections, hasLength(1));
    expect(d.crossDayCollections.single.invoice.invoiceNumber, 'F-050');
    expect(d.crossDayCollectionsTotal, 60.0);
    expect(d.totalDiscounts, 15.0);
  });

  test('HTTP errors become PosApiException', () async {
    final a = FakeAdapter((o) async => const FakeResponse(500, {'error': 'boom'}));
    expect(
      () => client(a).getSalesSummary(DateTime(2026, 5, 1), DateTime(2026, 5, 1)),
      throwsA(isA<PosApiException>().having((e) => e.statusCode, 'status', 500).having((e) => e.kind, 'kind', PosErrorKind.http)),
    );
  });

  test('connection refused is classified', () async {
    // Port 1 on loopback is closed on any normal machine.
    final c = RetailManagerPosClient(Dio(BaseOptions(baseUrl: 'http://127.0.0.1:1', connectTimeout: const Duration(seconds: 5))));
    final r = await c.testConnection();
    expect(r.ok, isFalse);
    expect(r.message, anyOf(contains('rechazada'), contains('alcanzar'), contains('Tiempo')));
  });

  test('testConnection success reports latency', () async {
    final a = FakeAdapter((o) async => const FakeResponse(200, []));
    final r = await client(a).testConnection();
    expect(r.ok, isTrue);
    expect(r.latency, isNotNull);
    expect(r.message, contains('Conexión exitosa'));
  });
}
