import 'dart:io';

import 'package:dio/dio.dart';

import '../../services/app_logger.dart';

/// Retries transient failures: 3 retries with 2/4/8 s backoff on
/// 5xx, 408, 429 and network errors. Safe for POST journalentry because
/// every create carries a `requestid` idempotency key.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this.dio, {this.delays = const [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)], Future<void> Function(Duration)? sleep})
      : _sleep = sleep ?? Future.delayed;

  final Dio dio;
  final List<Duration> delays;
  final Future<void> Function(Duration) _sleep;

  static const _attemptKey = 'rmqb.retryAttempt';

  static bool isRetryable(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final s = e.response?.statusCode ?? 0;
        return s >= 500 || s == 408 || s == 429;
      case DioExceptionType.unknown:
        return e.error is SocketException || e.error is HttpException;
      default:
        return false;
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (!isRetryable(err) || attempt >= delays.length) {
      return handler.next(err);
    }
    var wait = delays[attempt];
    final retryAfter = int.tryParse(err.response?.headers.value('retry-after') ?? '');
    if (retryAfter != null && retryAfter > wait.inSeconds && retryAfter <= 60) wait = Duration(seconds: retryAfter);
    AppLogger.warning('Reintento ${attempt + 1}/${delays.length} de ${err.requestOptions.method} '
        '${err.requestOptions.uri.path} en ${wait.inSeconds}s (${err.response?.statusCode ?? err.type.name})');
    await _sleep(wait);
    final opts = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      final res = await dio.fetch<dynamic>(opts);
      handler.resolve(res);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
