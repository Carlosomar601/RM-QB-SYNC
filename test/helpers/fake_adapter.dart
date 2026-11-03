import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeResponse {
  const FakeResponse(this.status, this.body, {this.headers = const {}});
  final int status;
  final Object? body;
  final Map<String, List<String>> headers;
}

/// Dio adapter that routes requests to a handler and records them.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<FakeResponse> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];
  final List<String> bodies = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>([], (a, b) => a..addAll(b));
      bodies.add(utf8.decode(bytes));
    } else {
      bodies.add(options.data is String ? options.data as String : (options.data == null ? '' : jsonEncode(options.data)));
    }
    final r = await handler(options);
    final text = r.body is String ? r.body as String : jsonEncode(r.body);
    return ResponseBody.fromString(
      text,
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...r.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
