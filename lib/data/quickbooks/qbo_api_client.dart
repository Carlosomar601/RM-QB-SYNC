import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/exceptions.dart';
import '../../core/journal_entry.dart';
import '../db/repositories.dart';
import 'journal_entry_qbo_mapper.dart';
import 'qbo_models.dart';
import 'retry_interceptor.dart';
import 'token_manager.dart';

/// Adds the Bearer token; on 401 refreshes once and retries.
class QboAuthInterceptor extends QueuedInterceptor {
  QboAuthInterceptor(this.tokens, this.dio);
  final TokenManager tokens;
  final Dio dio;

  static const _retriedKey = 'rmqb.authRetried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      options.headers['Authorization'] = 'Bearer ${await tokens.getValidAccessToken()}';
      handler.next(options);
    } on Exception catch (e) {
      handler.reject(DioException(requestOptions: options, error: e, type: DioExceptionType.unknown));
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && err.requestOptions.extra[_retriedKey] != true) {
      try {
        final t = await tokens.getValidAccessToken(forceRefresh: true);
        final opts = err.requestOptions
          ..extra[_retriedKey] = true
          ..headers['Authorization'] = 'Bearer $t';
        return handler.resolve(await dio.fetch<dynamic>(opts));
      } on DioException catch (e) {
        return handler.next(e);
      } on Exception catch (e) {
        return handler.next(DioException(requestOptions: err.requestOptions, error: e, response: err.response));
      }
    }
    handler.next(err);
  }
}

class QboApiClient {
  QboApiClient({
    required this.dio,
    required this.tokens,
    required this.connections,
  });

  /// Builds the client with auth + retry interceptors.
  factory QboApiClient.create({
    required TokenManager tokens,
    required ConnectionRepository connections,
    HttpClientAdapter? adapter,
    Future<void> Function(Duration)? sleep,
  }) {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Accept': 'application/json'},
      responseType: ResponseType.json,
    ));
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(QboAuthInterceptor(tokens, dio));
    dio.interceptors.add(RetryInterceptor(dio, sleep: sleep));
    return QboApiClient(dio: dio, tokens: tokens, connections: connections);
  }

  final Dio dio;
  final TokenManager tokens;
  final ConnectionRepository connections;

  Future<String> _companyBase() async {
    final c = await connections.current();
    if (c == null) throw QboNotConnectedException();
    return '${QboConstants.apiBase(c.environment)}/v3/company/${c.realmId}';
  }

  Future<T> _wrap<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      if (e.error is QboApiException) throw e.error as QboApiException;
      if (e.response != null) throw QboFaultParser.parse(e.response!.statusCode, e.response!.data);
      throw QboApiException('No se pudo comunicar con QuickBooks: ${e.error ?? e.message}. Verifique la conexión a Internet.');
    }
  }

  /// `select * from {entity} where Active = true`, paged 1000 at a time.
  Future<List<Map<String, dynamic>>> queryAll(String entity, {String where = 'Active = true'}) => _wrap(() async {
        final base = await _companyBase();
        final out = <Map<String, dynamic>>[];
        var start = 1;
        while (true) {
          final q = 'select * from $entity where $where STARTPOSITION $start MAXRESULTS ${QboConstants.pageSize}';
          final r = await dio.get<Map<String, dynamic>>('$base/query',
              queryParameters: {'query': q, 'minorversion': QboConstants.minorVersion});
          final rows = ((r.data?['QueryResponse'] as Map?)?[entity] as List?) ?? const [];
          out.addAll(rows.whereType<Map>().map((e) => e.cast<String, dynamic>()));
          if (rows.length < QboConstants.pageSize) break;
          start += QboConstants.pageSize;
        }
        return out;
      });

  Future<List<QboAccount>> accounts() async =>
      (await queryAll('Account')).map(QboAccount.fromJson).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

  Future<List<QboEntity>> customers() async =>
      (await queryAll('Customer')).map(QboEntity.fromJson).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

  Future<List<QboEntity>> vendors() async =>
      (await queryAll('Vendor')).map(QboEntity.fromJson).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

  Future<String?> companyName() => _wrap(() async {
        final c = await connections.current();
        if (c == null) throw QboNotConnectedException();
        final r = await dio.get<Map<String, dynamic>>('${await _companyBase()}/companyinfo/${c.realmId}',
            queryParameters: {'minorversion': QboConstants.minorVersion});
        return (r.data?['CompanyInfo'] as Map?)?['CompanyName']?.toString();
      });

  /// Posts the entry. [requestId] makes retries idempotent.
  Future<QboJournalEntryResult> createJournalEntry(JournalEntryDraft draft, {required String requestId}) {
    if (!draft.isBalanced) {
      throw QboApiException('El asiento no está balanceado; no se envió a QuickBooks.');
    }
    final body = JournalEntryQboMapper.toQbo(draft);
    final requestJson = const JsonEncoder.withIndent('  ').convert(body);
    return _wrap(() async {
      final r = await dio.post<Map<String, dynamic>>(
        '${await _companyBase()}/journalentry',
        data: body,
        queryParameters: {'minorversion': QboConstants.minorVersion, 'requestid': requestId},
        options: Options(contentType: Headers.jsonContentType),
      );
      final je = r.data?['JournalEntry'] as Map?;
      if (je == null) {
        throw QboFaultParser.parse(r.statusCode, r.data);
      }
      return QboJournalEntryResult(
        id: je['Id'].toString(),
        requestJson: requestJson,
        responseJson: const JsonEncoder.withIndent('  ').convert(r.data),
      );
    });
  }
}
