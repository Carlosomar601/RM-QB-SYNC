import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/exceptions.dart';
import '../../services/app_logger.dart';
import '../db/repositories.dart';
import '../secrets/secret_store.dart';
import 'qbo_models.dart';

/// Owns QuickBooks tokens: storage, just-in-time refresh (≤5 min before
/// expiry), proactive refresh to keep the ~100-day refresh token alive, and
/// always persisting the rotated refresh token.
class TokenManager {
  TokenManager({
    required this.secrets,
    required this.connections,
    required Dio tokenDio,
    DateTime Function()? clock,
  })  : _dio = tokenDio,
        _clock = clock ?? DateTime.now;

  final SecretStore secrets;
  final ConnectionRepository connections;
  final Dio _dio;
  final DateTime Function() _clock;

  static const refreshMargin = Duration(minutes: 5);
  static const proactiveInterval = Duration(hours: 6);

  Future<QboTokens>? _inflight;
  Timer? _timer;

  Future<String> basicAuthHeader() async {
    final id = await secrets.read(SecretKeys.qboClientId);
    final secret = await secrets.read(SecretKeys.qboClientSecret);
    if ((id ?? '').isEmpty || (secret ?? '').isEmpty) {
      throw QboApiException('Faltan el Client ID / Client Secret de Intuit. Configúrelos en Configuración → Credenciales.');
    }
    return 'Basic ${base64Encode(utf8.encode('$id:$secret'))}';
  }

  /// Exchanges an authorization code for tokens.
  Future<QboTokens> exchangeCode(String code, String redirectUri) => _tokenRequest({
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      });

  Future<QboTokens> _tokenRequest(Map<String, String> form) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        QboConstants.tokenUrl,
        data: form,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': await basicAuthHeader(), 'Accept': 'application/json'},
        ),
      );
      return QboTokens.fromTokenResponse(r.data!, _clock());
    } on DioException catch (e) {
      throw QboFaultParser.parse(e.response?.statusCode, e.response?.data);
    }
  }

  Future<void> saveTokens(QboTokens t) async {
    await secrets.write(SecretKeys.qboAccessToken, t.accessToken);
    await secrets.write(SecretKeys.qboRefreshToken, t.refreshToken);
    await connections.updateTokens(accessExpiresAt: t.accessExpiresAt, refreshExpiresAt: t.refreshExpiresAt);
  }

  /// Returns a valid access token, refreshing if within [refreshMargin].
  Future<String> getValidAccessToken({bool forceRefresh = false}) async {
    final conn = await connections.current();
    final access = await secrets.read(SecretKeys.qboAccessToken);
    if (conn == null || (await secrets.read(SecretKeys.qboRefreshToken) ?? '').isEmpty) {
      throw QboNotConnectedException();
    }
    final exp = conn.accessTokenExpiresAt;
    final fresh = access != null && exp != null && exp.isAfter(_clock().add(refreshMargin));
    if (fresh && !forceRefresh) return access;
    return (await refresh()).accessToken;
  }

  /// Refreshes once even if called concurrently.
  Future<QboTokens> refresh() {
    final existing = _inflight;
    if (existing != null) return existing;
    final f = _doRefresh();
    _inflight = f;
    return f.whenComplete(() => _inflight = null);
  }

  Future<QboTokens> _doRefresh() async {
    final rt = await secrets.read(SecretKeys.qboRefreshToken);
    if ((rt ?? '').isEmpty) throw QboNotConnectedException();
    try {
      final t = await _tokenRequest({'grant_type': 'refresh_token', 'refresh_token': rt!});
      await saveTokens(t); // always persist the rotated refresh token
      AppLogger.info('Token de QuickBooks renovado; vence ${t.accessExpiresAt.toIso8601String()}.');
      return t;
    } on QboApiException catch (e) {
      AppLogger.error('Fallo al renovar el token de QuickBooks: ${e.message}');
      if (e.statusCode == 400 || e.statusCode == 401) {
        throw QboApiException(
          'La autorización de QuickBooks ya no es válida (token de renovación vencido o revocado). '
          'Vaya a Configuración y presione "Conectar con QuickBooks" nuevamente.',
          statusCode: e.statusCode,
        );
      }
      rethrow;
    }
  }

  /// Starts the proactive refresh timer (every 6 h).
  void startProactiveRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(proactiveInterval, (_) => proactiveTick());
    unawaited(proactiveTick());
  }

  Future<void> proactiveTick() async {
    try {
      final conn = await connections.current();
      if (conn == null) return;
      final last = conn.lastRefreshAt ?? conn.connectedAt;
      if (_clock().difference(last) >= proactiveInterval ||
          (conn.accessTokenExpiresAt?.isBefore(_clock().add(refreshMargin)) ?? true)) {
        await refresh();
      }
    } catch (e) {
      AppLogger.warning('Renovación proactiva de QuickBooks falló: $e');
    }
  }

  void dispose() => _timer?.cancel();

  Future<void> clear() async {
    await secrets.delete(SecretKeys.qboAccessToken);
    await secrets.delete(SecretKeys.qboRefreshToken);
  }
}
