import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../core/exceptions.dart';
import '../../services/app_logger.dart';
import '../db/repositories.dart';
import '../secrets/secret_store.dart';
import 'qbo_models.dart';
import 'token_manager.dart';

class OAuthConnectResult {
  const OAuthConnectResult({required this.realmId, this.companyName});
  final String realmId;
  final String? companyName;
}

class _Attempt {
  _Attempt(this.createdAt);
  final DateTime createdAt;
  final Completer<OAuthConnectResult> completer = Completer();
}

/// Desktop OAuth2 authorization-code flow with a loopback listener on
/// 127.0.0.1:5177/oauth/callback (same redirect URI already registered with
/// Intuit). Each attempt has its own random `state`.
class QboOAuthService {
  QboOAuthService({
    required this.tokens,
    required this.secrets,
    required this.settings,
    required this.connections,
    required this.openBrowser,
    required this.fetchCompanyName,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TokenManager tokens;
  final SecretStore secrets;
  final SettingsRepository settings;
  final ConnectionRepository connections;
  final Future<bool> Function(Uri url) openBrowser;
  final Future<String?> Function() fetchCompanyName;
  final DateTime Function() _clock;

  static const attemptTtl = Duration(minutes: 10);
  final Map<String, _Attempt> _attempts = {};
  HttpServer? _server;

  static String newState() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(24, (_) => r.nextInt(256))).replaceAll('=', '');
  }

  Uri authorizeUrl(String clientId, String state) => Uri.parse(QboConstants.authorizeUrl).replace(queryParameters: {
        'client_id': clientId,
        'redirect_uri': QboConstants.redirectUri,
        'response_type': 'code',
        'scope': QboConstants.scope,
        'state': state,
      });

  /// Starts a connect attempt; completes when the browser callback arrives.
  Future<OAuthConnectResult> connect() async {
    final clientId = await secrets.read(SecretKeys.qboClientId);
    if ((clientId ?? '').isEmpty || !await secrets.has(SecretKeys.qboClientSecret)) {
      throw QboApiException('Primero guarde el Client ID y el Client Secret de Intuit en Configuración → Credenciales.');
    }
    _purgeExpired();
    await _ensureServer();
    final state = newState();
    final attempt = _Attempt(_clock());
    _attempts[state] = attempt;
    final ok = await openBrowser(authorizeUrl(clientId!, state));
    if (!ok) {
      _attempts.remove(state);
      throw QboApiException('No se pudo abrir el navegador para autorizar QuickBooks.');
    }
    return attempt.completer.future.timeout(attemptTtl, onTimeout: () {
      _attempts.remove(state);
      throw QboApiException('Se agotó el tiempo para autorizar QuickBooks (10 minutos). Intente nuevamente.');
    }).whenComplete(_maybeStopServer);
  }

  bool hasPending(String state) => _attempts.containsKey(state);

  /// Registers a state without opening a browser (tests).
  Future<OAuthConnectResult> registerAttemptForTest(String state) {
    final a = _Attempt(_clock());
    _attempts[state] = a;
    return a.completer.future;
  }

  void _purgeExpired() {
    final now = _clock();
    _attempts.removeWhere((_, a) {
      final expired = now.difference(a.createdAt) > attemptTtl;
      if (expired && !a.completer.isCompleted) {
        a.completer.completeError(QboApiException('Intento de conexión vencido.'));
      }
      return expired;
    });
  }

  Future<void> _ensureServer() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, QboConstants.loopbackPort);
    } on SocketException catch (e) {
      throw QboApiException(
        'No se pudo abrir el puerto ${QboConstants.loopbackPort} para recibir la autorización '
        '(¿otro programa o el servicio RMQBsync anterior lo está usando?). Detalle: ${e.message}',
      );
    }
    _server!.listen((req) async {
      final result = req.uri.path == QboConstants.callbackPath
          ? await handleCallback(req.uri)
          : (status: 404, html: _page('No encontrado', 'Ruta desconocida.', ok: false));
      req.response
        ..statusCode = result.status
        ..headers.contentType = ContentType.html
        ..write(result.html);
      await req.response.close();
    });
  }

  void _maybeStopServer() {
    if (_attempts.isEmpty) {
      _server?.close(force: true);
      _server = null;
    }
  }

  /// Handles `/oauth/callback?code&state&realmId` (public for tests).
  Future<({int status, String html})> handleCallback(Uri uri) async {
    final q = uri.queryParameters;
    final state = q['state'] ?? '';
    final attempt = _attempts.remove(state);
    if (attempt == null) {
      AppLogger.warning('Callback OAuth con state desconocido o vencido.');
      return (
        status: 400,
        html: _page('Solicitud no válida', 'El enlace de autorización no corresponde a un intento activo o ya venció. '
            'Vuelva a RMQBsync y presione "Conectar con QuickBooks" otra vez.', ok: false)
      );
    }
    if (q['error'] != null) {
      final ex = QboApiException('Intuit canceló o rechazó la autorización: ${q['error']}');
      attempt.completer.completeError(ex);
      return (status: 400, html: _page('Autorización cancelada', ex.message, ok: false));
    }
    final code = q['code'];
    final realmId = q['realmId'];
    if ((code ?? '').isEmpty || (realmId ?? '').isEmpty) {
      final ex = QboApiException('Respuesta de Intuit incompleta (falta code o realmId).');
      attempt.completer.completeError(ex);
      return (status: 400, html: _page('Error', ex.message, ok: false));
    }
    try {
      final t = await tokens.exchangeCode(code!, QboConstants.redirectUri);
      await connections.replace(
        realmId: realmId!,
        environment: await settings.getQboEnvironment(),
        accessExpiresAt: t.accessExpiresAt,
        refreshExpiresAt: t.refreshExpiresAt,
      );
      await tokens.saveTokens(t);
      String? name;
      try {
        name = await fetchCompanyName();
        if (name != null) await connections.setCompanyName(name);
      } catch (e) {
        AppLogger.warning('No se pudo obtener el nombre de la compañía: $e');
      }
      final result = OAuthConnectResult(realmId: realmId, companyName: name);
      attempt.completer.complete(result);
      return (
        status: 200,
        html: _page('¡Conectado!', 'RMQBsync quedó conectado a QuickBooks${name == null ? '' : ' ($name)'}. '
            'Ya puede cerrar esta ventana y volver a la aplicación.', ok: true)
      );
    } catch (e) {
      final ex = e is QboApiException ? e : QboApiException('Error al completar la conexión: $e');
      attempt.completer.completeError(ex);
      return (status: 500, html: _page('Error al conectar', ex.message, ok: false));
    }
  }

  static String _page(String title, String body, {required bool ok}) {
    const esc = HtmlEscape();
    final color = ok ? '#1b7f3b' : '#b3261e';
    return '<!doctype html><html lang="es"><head><meta charset="utf-8"><title>RMQBsync</title>'
        '<style>body{font-family:Segoe UI,Arial,sans-serif;background:#f5f5f5;display:flex;align-items:center;'
        'justify-content:center;height:100vh;margin:0}.c{background:#fff;padding:32px 40px;border-radius:12px;'
        'max-width:520px;box-shadow:0 2px 12px rgba(0,0,0,.1)}h1{color:$color;margin-top:0}</style></head>'
        '<body><div class="c"><h1>${esc.convert(title)}</h1><p>${esc.convert(body)}</p></div></body></html>';
  }

  Future<void> dispose() async {
    await _server?.close(force: true);
    _server = null;
  }
}
