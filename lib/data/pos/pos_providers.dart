import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/pos_address.dart';
import '../secrets/secret_store.dart';
import 'pos_client.dart';

/// Effective POS configuration (address + optional API key header).
class PosConfig {
  const PosConfig({this.address, this.apiKeyHeader, this.apiKeyValue, this.history = const []});

  final PosAddress? address;
  final String? apiKeyHeader;
  final String? apiKeyValue;
  final List<PosAddress> history;

  bool get isConfigured => address?.isConfigured ?? false;
  bool get hasApiKey => (apiKeyHeader ?? '').isNotEmpty && (apiKeyValue ?? '').isNotEmpty;
}

class PosConfigNotifier extends AsyncNotifier<PosConfig> {
  @override
  Future<PosConfig> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    final secrets = ref.watch(secretStoreProvider);
    return PosConfig(
      address: await settings.getPosAddress(),
      apiKeyHeader: await secrets.read(SecretKeys.posApiKeyHeader),
      apiKeyValue: await secrets.read(SecretKeys.posApiKeyValue),
      history: await settings.getPosHistory(),
    );
  }

  /// Persists and applies the new address immediately (no restart).
  ///
  /// [apiKeyValue] == null keeps the stored key; empty header disables it.
  Future<void> save({
    required PosAddress address,
    required String username,
    String? apiKeyHeader,
    String? apiKeyValue,
  }) async {
    final settings = ref.read(settingsRepositoryProvider);
    final secrets = ref.read(secretStoreProvider);
    final audit = ref.read(auditRepositoryProvider);
    final old = state.value?.address;

    await settings.setPosAddress(address);
    await settings.pushPosHistory(address);
    if (apiKeyHeader != null) {
      if (apiKeyHeader.trim().isEmpty) {
        await secrets.delete(SecretKeys.posApiKeyHeader);
        await secrets.delete(SecretKeys.posApiKeyValue);
      } else {
        await secrets.write(SecretKeys.posApiKeyHeader, apiKeyHeader.trim());
        if (apiKeyValue != null && apiKeyValue.isNotEmpty) {
          await secrets.write(SecretKeys.posApiKeyValue, apiKeyValue);
        }
      }
    }
    await audit.log(
      username,
      'ConfiguracionApiPosActualizada',
      jsonEncode({
        'anterior': old?.baseUrl,
        'nueva': address.baseUrl,
        'timeoutSegundos': address.timeoutSeconds,
        'claveApi': apiKeyHeader == null ? 'sin cambios' : (apiKeyHeader.trim().isEmpty ? 'desactivada' : 'configurada'),
      }),
    );
    ref.invalidateSelf();
    await future;
  }
}

final posConfigProvider = AsyncNotifierProvider<PosConfigNotifier, PosConfig>(PosConfigNotifier.new);

const Duration posConnectTimeout = Duration(seconds: 15);
const Duration posReceiveTimeout = Duration(seconds: 60);

/// Builds a dio for a POS address (also used by "Probar conexión" before saving).
Dio buildPosDio(PosAddress address, {String? apiKeyHeader, String? apiKeyValue, HttpClientAdapter? adapter}) {
  final dio = Dio(BaseOptions(
    baseUrl: address.baseUrl,
    connectTimeout: posConnectTimeout,
    receiveTimeout: address.timeoutSeconds != null ? Duration(seconds: address.timeoutSeconds!) : posReceiveTimeout,
    sendTimeout: posConnectTimeout,
    responseType: ResponseType.json,
    headers: {
      'Accept': 'application/json',
      if ((apiKeyHeader ?? '').isNotEmpty && (apiKeyValue ?? '').isNotEmpty) apiKeyHeader!: apiKeyValue,
    },
  ));
  if (adapter != null) dio.httpClientAdapter = adapter;
  return dio;
}

/// Rebuilt whenever the POS configuration changes → live reconfiguration.
final posDioProvider = Provider<Dio?>((ref) {
  final cfg = ref.watch(posConfigProvider).value;
  if (cfg == null || !cfg.isConfigured) return null;
  final dio = buildPosDio(
    cfg.address!,
    apiKeyHeader: cfg.apiKeyHeader,
    apiKeyValue: cfg.apiKeyValue,
    adapter: ref.watch(httpAdapterProvider),
  );
  ref.onDispose(() => dio.close());
  return dio;
});

final posClientProvider = Provider<PosClient>((ref) {
  final dio = ref.watch(posDioProvider);
  if (dio == null) return const UnconfiguredPosClient();
  return RetailManagerPosClient(dio, clock: ref.watch(clockProvider));
});

/// Client for an unsaved address (Probar conexión).
PosClient posClientFor(Ref ref, PosAddress address, {String? apiKeyHeader, String? apiKeyValue}) =>
    RetailManagerPosClient(
      buildPosDio(address,
          apiKeyHeader: apiKeyHeader, apiKeyValue: apiKeyValue, adapter: ref.read(httpAdapterProvider)),
      clock: ref.read(clockProvider),
    );
