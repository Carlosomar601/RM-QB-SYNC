import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/exceptions.dart';
import '../../core/pos_sales_summary.dart';
import 'pos_aggregator.dart';
import 'pos_dtos.dart';

abstract class PosClient {
  Future<PosSalesSummary> getSalesSummary(DateTime from, DateTime to);
  Future<DayDrillDown> getDayDrillDown(DateTime day);
  Future<PosConnectionTestResult> testConnection();
}

/// Used while no POS address has been configured.
class UnconfiguredPosClient implements PosClient {
  const UnconfiguredPosClient();

  @override
  Future<PosSalesSummary> getSalesSummary(DateTime from, DateTime to) => Future.error(PosNotConfiguredException());

  @override
  Future<DayDrillDown> getDayDrillDown(DateTime day) => Future.error(PosNotConfiguredException());

  @override
  Future<PosConnectionTestResult> testConnection() async =>
      PosConnectionTestResult(ok: false, message: PosNotConfiguredException().message);
}

/// Retail Manager POS REST client.
class RetailManagerPosClient implements PosClient {
  RetailManagerPosClient(this._dio, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Dio _dio;
  final DateTime Function() _clock;

  static const salesByMethodPath = '/cse.api.v1/SalesByMethod';
  static const arInvoicesPath = '/cse.api.v1/ARReconciliationInvoices';

  @override
  Future<PosSalesSummary> getSalesSummary(DateTime from, DateTime to) async {
    if (to.isBefore(from)) {
      throw ArgumentError('La fecha final no puede ser anterior a la fecha inicial.');
    }
    final results = await Future.wait<Object>([
      fetchSalesByMethod(from, to),
      fetchArInvoices(from, to),
      fetchArInvoices(Dates.addDays(from, -PosConstants.arCollectionLookbackDays), to),
    ]);
    return PosAggregator.summarize(
      from: from,
      to: to,
      salesRows: results[0] as List<SalesByMethodRow>,
      rangeInvoices: results[1] as List<ArInvoice>,
      lookbackInvoices: results[2] as List<ArInvoice>,
    );
  }

  @override
  Future<DayDrillDown> getDayDrillDown(DateTime day) async {
    final d = Dates.dateOnly(day);
    final results = await Future.wait<Object>([
      fetchSalesByMethod(d, d),
      fetchArInvoices(d, d),
      fetchArInvoices(Dates.addDays(d, -PosConstants.crossDayLookbackDays), Dates.addDays(d, -1)),
    ]);
    return DayDrillDown(
      date: d,
      salesRows: results[0] as List<SalesByMethodRow>,
      invoices: results[1] as List<ArInvoice>,
      crossDayCollections: PosAggregator.crossDayCollections(d, results[2] as List<ArInvoice>),
    );
  }

  @override
  Future<PosConnectionTestResult> testConnection() async {
    final sw = Stopwatch()..start();
    try {
      final today = Dates.today(_clock());
      final rows = await fetchSalesByMethod(today, today);
      sw.stop();
      return PosConnectionTestResult(
        ok: true,
        latency: sw.elapsed,
        rowCount: rows.length,
        statusCode: 200,
        message: 'Conexión exitosa en ${sw.elapsedMilliseconds} ms. '
            '${rows.isEmpty ? 'Hoy todavía no hay ventas registradas.' : 'Se recibieron ${rows.length} fila(s) de ventas de hoy.'}',
      );
    } on PosApiException catch (e) {
      sw.stop();
      return PosConnectionTestResult(ok: false, message: e.message, latency: sw.elapsed, statusCode: e.statusCode);
    }
  }

  Future<List<SalesByMethodRow>> fetchSalesByMethod(DateTime from, DateTime to) async {
    final data = await _get(salesByMethodPath, {'DateFrom': Dates.iso(from), 'DateTo': Dates.iso(to)});
    final list = data is List ? data : (data is Map && data['data'] is List ? data['data'] as List : null);
    if (list == null) {
      throw PosApiException('El POS devolvió una respuesta inesperada para SalesByMethod (se esperaba una lista).',
          kind: PosErrorKind.badResponse);
    }
    return list.whereType<Map>().map((e) => SalesByMethodRow.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<List<ArInvoice>> fetchArInvoices(DateTime from, DateTime to) async {
    final all = <ArInvoice>[];
    var page = 1;
    while (page <= PosConstants.maxPages) {
      final data = await _get(arInvoicesPath, {'date_from': Dates.iso(from), 'date_to': Dates.iso(to), 'page': page});
      if (data is! Map) {
        throw PosApiException('El POS devolvió una respuesta inesperada para ARReconciliationInvoices.',
            kind: PosErrorKind.badResponse);
      }
      final p = ArInvoicePage.fromJson(data.cast<String, dynamic>());
      if (!p.success) {
        throw PosApiException('El POS respondió success=false para ARReconciliationInvoices (página $page).',
            kind: PosErrorKind.badResponse);
      }
      all.addAll(p.data);
      if (page >= p.totalPages || p.data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<Object?> _get(String path, Map<String, Object?> query) async {
    try {
      final r = await _dio.get<Object?>(path, queryParameters: query);
      return r.data;
    } on DioException catch (e) {
      throw classify(e);
    }
  }

  /// Converts a dio failure into a Spanish, actionable [PosApiException].
  static PosApiException classify(DioException e) {
    final url = e.requestOptions.uri.toString();
    final base = '${e.requestOptions.uri.host}:${e.requestOptions.uri.port}';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return PosApiException(
            'Tiempo de espera agotado al conectar con el POS ($base). Verifique que el equipo del POS esté encendido y en la misma red.',
            kind: PosErrorKind.timeout,
            url: url);
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return PosApiException(
            'El POS ($base) tardó demasiado en responder. Intente un rango de fechas más corto o aumente el tiempo de espera.',
            kind: PosErrorKind.timeout,
            url: url);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code != null && code >= 500) {
          return PosApiException(
              'La API del POS tuvo un error interno (HTTP $code) en ${e.requestOptions.uri.path}. '
              'La configuración de esta aplicación está bien; revise el servidor del POS '
              '(registro de eventos de Windows, origen RMApiV2) o contacte a soporte.',
              kind: PosErrorKind.http,
              statusCode: code,
              url: url);
        }
        return PosApiException(
            'El POS respondió con error HTTP $code en ${e.requestOptions.uri.path}. '
            '${code == 404 ? 'Revise la ruta base de la API.' : code == 401 || code == 403 ? 'Revise la clave de API.' : ''}'
                .trim(),
            kind: PosErrorKind.http,
            statusCode: code,
            url: url);
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final err = e.error;
        if (err is SocketException) {
          final code = err.osError?.errorCode;
          final msg = '${err.message} ${err.osError?.message ?? ''}'.toLowerCase();
          if (code == 11001 || code == 11004 || msg.contains('host lookup') || msg.contains('no such host')) {
            return PosApiException(
                'No se encontró el equipo "${e.requestOptions.uri.host}" (error DNS). Verifique el nombre o use la dirección IP.',
                kind: PosErrorKind.dns,
                url: url);
          }
          if (code == 10061 || code == 111 || msg.contains('refused')) {
            return PosApiException(
                'Conexión rechazada por $base. El equipo existe pero la API del POS no está escuchando en ese puerto.',
                kind: PosErrorKind.refused,
                url: url);
          }
          if (code == 10060 || code == 10065 || code == 10051 || msg.contains('timed out') || msg.contains('unreachable')) {
            return PosApiException(
                'No se pudo alcanzar $base (sin respuesta de la red). Verifique la IP y la conexión de red.',
                kind: PosErrorKind.timeout,
                url: url);
          }
        }
        if (err is HandshakeException || err is TlsException) {
          return PosApiException('Error de certificado TLS con $base. Si el POS no usa https, seleccione http.',
              kind: PosErrorKind.other, url: url);
        }
        return PosApiException('Error al consultar el POS ($base): ${err ?? e.message}', kind: PosErrorKind.other, url: url);
      case DioExceptionType.badCertificate:
        return PosApiException('Certificado TLS no válido en $base.', kind: PosErrorKind.other, url: url);
      case DioExceptionType.cancel:
        return PosApiException('Consulta al POS cancelada.', kind: PosErrorKind.other, url: url);
    }
  }
}
