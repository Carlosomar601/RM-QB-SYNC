import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../services/app_logger.dart';
import '../db/app_database.dart';
import '../secrets/secret_store.dart';
import 'qbo_api_client.dart';
import 'qbo_models.dart';
import 'qbo_oauth_service.dart';
import 'token_manager.dart';

/// Optional sleep override so tests don't wait for real backoff.
final retrySleepProvider = Provider<Future<void> Function(Duration)?>((ref) => null);

final tokenManagerProvider = Provider<TokenManager>((ref) {
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(seconds: 30)));
  final adapter = ref.watch(httpAdapterProvider);
  if (adapter != null) dio.httpClientAdapter = adapter;
  final tm = TokenManager(
    secrets: ref.watch(secretStoreProvider),
    connections: ref.watch(connectionRepositoryProvider),
    tokenDio: dio,
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(tm.dispose);
  return tm;
});

final qboApiClientProvider = Provider<QboApiClient>((ref) => QboApiClient.create(
      tokens: ref.watch(tokenManagerProvider),
      connections: ref.watch(connectionRepositoryProvider),
      adapter: ref.watch(httpAdapterProvider),
      sleep: ref.watch(retrySleepProvider),
    ));

final qboOAuthServiceProvider = Provider<QboOAuthService>((ref) {
  final api = ref.watch(qboApiClientProvider);
  final s = QboOAuthService(
    tokens: ref.watch(tokenManagerProvider),
    secrets: ref.watch(secretStoreProvider),
    settings: ref.watch(settingsRepositoryProvider),
    connections: ref.watch(connectionRepositoryProvider),
    openBrowser: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
    fetchCompanyName: api.companyName,
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(s.dispose);
  return s;
});

/// Current QuickBooks connection row (null when disconnected).
final qboConnectionProvider = StreamProvider<OAuthConnectionRow?>(
  (ref) => ref.watch(connectionRepositoryProvider).watchCurrent(),
);

/// Whether Intuit client credentials are stored.
final qboCredentialsProvider = FutureProvider<({bool hasClientId, bool hasSecret, String? clientId, String environment})>((ref) async {
  final secrets = ref.watch(secretStoreProvider);
  final id = await secrets.read(SecretKeys.qboClientId);
  return (
    hasClientId: (id ?? '').isNotEmpty,
    hasSecret: await secrets.has(SecretKeys.qboClientSecret),
    clientId: id,
    environment: await ref.watch(settingsRepositoryProvider).getQboEnvironment(),
  );
});

/// Cached chart of accounts / customers / vendors (refresh via invalidate).
final qboAccountsProvider = FutureProvider<List<QboAccount>>((ref) => ref.watch(qboApiClientProvider).accounts());
final qboCustomersProvider = FutureProvider<List<QboEntity>>((ref) => ref.watch(qboApiClientProvider).customers());
final qboVendorsProvider = FutureProvider<List<QboEntity>>((ref) => ref.watch(qboApiClientProvider).vendors());

/// Connect / disconnect operations used by the UI.
class QboConnectionService {
  QboConnectionService(this._ref);
  final Ref _ref;

  Future<OAuthConnectResult> connect(String username) async {
    final r = await _ref.read(qboOAuthServiceProvider).connect();
    await _ref.read(auditRepositoryProvider).log(username, 'QuickBooksConectado',
        'Compañía: ${r.companyName ?? '-'} (realm ${r.realmId})');
    _ref.invalidate(qboAccountsProvider);
    _ref.invalidate(qboCustomersProvider);
    _ref.invalidate(qboVendorsProvider);
    return r;
  }

  /// Best-effort revoke at Intuit, then clears tokens and the connection row.
  Future<void> disconnect(String username) async {
    final tm = _ref.read(tokenManagerProvider);
    final secrets = _ref.read(secretStoreProvider);
    try {
      final rt = await secrets.read(SecretKeys.qboRefreshToken);
      if ((rt ?? '').isNotEmpty) {
        final dio = Dio();
        final adapter = _ref.read(httpAdapterProvider);
        if (adapter != null) dio.httpClientAdapter = adapter;
        await dio.post<void>(QboConstants.revokeUrl,
            data: {'token': rt},
            options: Options(headers: {'Authorization': await tm.basicAuthHeader(), 'Accept': 'application/json'}));
      }
    } catch (e) {
      AppLogger.warning('No se pudo revocar el token en Intuit (se desconecta localmente): $e');
    }
    await tm.clear();
    await _ref.read(connectionRepositoryProvider).clear();
    await _ref.read(auditRepositoryProvider).log(username, 'QuickBooksDesconectado');
  }
}

final qboConnectionServiceProvider = Provider<QboConnectionService>(QboConnectionService.new);