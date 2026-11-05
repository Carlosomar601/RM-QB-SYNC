import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/account_mapping.dart';
import '../core/constants.dart';
import '../core/sync_rules.dart';
import '../data/db/app_database.dart';
import '../data/db/repositories.dart';
import '../data/pos/pos_providers.dart';
import '../data/quickbooks/qbo_providers.dart';
import '../services/service_providers.dart';
import '../features/help/help_content.dart' show Routes;
import 'providers.dart';

/// Per-user autosaved drafts for half-finished workflows.
class DraftStore {
  DraftStore(this._settings, this._user);
  final SettingsRepository _settings;
  final String _user;

  Future<Map<String, Object?>?> read(String wizard) => _settings.getJson(SettingKeys.draft(wizard, _user));
  Future<void> save(String wizard, Map<String, Object?> data) => _settings.setJson(SettingKeys.draft(wizard, _user), data);
  Future<void> clear(String wizard) => _settings.remove(SettingKeys.draft(wizard, _user));
}

final draftStoreProvider = Provider<DraftStore>((ref) => DraftStore(
      ref.watch(settingsRepositoryProvider),
      ref.watch(sessionProvider)?.username ?? '_',
    ));

final mappingsProvider = FutureProvider<Map<String, AccountMapping>>(
  (ref) => ref.watch(mappingRepositoryProvider).byCategory(),
);

final scheduleProvider = FutureProvider<ScheduleModel?>((ref) => ref.watch(scheduleRepositoryProvider).single());

class SetupStatus {
  const SetupStatus({
    required this.posConfigured,
    required this.qboCredentials,
    required this.qboConnected,
    required this.mappedCount,
    required this.totalCategories,
    required this.scheduleEnabled,
    this.companyName,
    this.posUrl,
    this.lastSyncAt,
    this.environment,
    this.authExpiresAt,
  });

  final bool posConfigured;
  final bool qboCredentials;
  final bool qboConnected;
  final int mappedCount;
  final int totalCategories;
  final bool scheduleEnabled;
  final String? companyName;
  final String? posUrl;
  /// Last *successful* sync (written only on success).
  final DateTime? lastSyncAt;

  /// 'sandbox' | 'production' of the active QuickBooks connection.
  final String? environment;

  /// When the QuickBooks authorization (refresh token) expires.
  final DateTime? authExpiresAt;

  bool get isProduction => environment?.toLowerCase() == 'production';

  bool get mappingsComplete => mappedCount >= totalCategories;

  /// Required pieces (schedule is optional).
  bool get ready => posConfigured && qboConnected && mappingsComplete;

  int get doneCount => [posConfigured, qboCredentials, qboConnected, mappingsComplete, scheduleEnabled].where((x) => x).length;
}

final setupStatusProvider = FutureProvider<SetupStatus>((ref) async {
  final pos = await ref.watch(posConfigProvider.future);
  final creds = await ref.watch(qboCredentialsProvider.future);
  final conn = await ref.watch(qboConnectionProvider.future);
  final maps = await ref.watch(mappingsProvider.future);
  final sched = await ref.watch(scheduleProvider.future);
  return SetupStatus(
    posConfigured: pos.isConfigured,
    posUrl: pos.address?.baseUrl,
    qboCredentials: creds.hasClientId && creds.hasSecret,
    qboConnected: conn != null,
    companyName: conn?.companyName,
    lastSyncAt: conn?.lastSyncAt,
    environment: conn?.environment,
    authExpiresAt: conn?.refreshTokenExpiresAt,
    mappedCount: PosCategories.all.where(maps.containsKey).length,
    totalCategories: PosCategories.all.length,
    scheduleEnabled: sched?.enabled ?? false,
  );
});

/// Operational synchronization health, tracked separately from setup
/// readiness (spec §7.4): a complete setup does not mean syncs are working.
class SyncHealth {
  const SyncHealth({this.lastRun, this.lastSuccess, this.lastScheduled, this.failuresSinceSuccess = 0});

  /// Most recent finished run (success, failed or skipped), any trigger.
  final SyncHistoryRow? lastRun;
  final SyncHistoryRow? lastSuccess;

  /// Most recent finished scheduled run.
  final SyncHistoryRow? lastScheduled;

  /// Failed runs newer than the last success.
  final int failuresSinceSuccess;

  SyncStatus? get lastStatus => lastRun == null ? null : SyncStatus.parse(lastRun!.status);
  bool get lastFailed => lastStatus == SyncStatus.failed;
  bool get neverSucceeded => lastSuccess == null;

  /// Pure: rows newest first (as returned by [HistoryRepository.watchRecent]).
  factory SyncHealth.fromRows(List<SyncHistoryRow> rows) {
    SyncHistoryRow? last, success, scheduled;
    var failures = 0;
    for (final r in rows) {
      final st = SyncStatus.parse(r.status);
      if (st == SyncStatus.running) continue;
      last ??= r;
      if (scheduled == null && SyncTrigger.parse(r.trigger) == SyncTrigger.scheduled) scheduled = r;
      if (st == SyncStatus.success) {
        success ??= r;
      } else if (st == SyncStatus.failed && success == null) {
        failures++;
      }
    }
    return SyncHealth(lastRun: last, lastSuccess: success, lastScheduled: scheduled, failuresSinceSuccess: failures);
  }
}

final syncHealthProvider = StreamProvider<SyncHealth>(
  (ref) => ref.watch(historyRepositoryProvider).watchRecent(200).map(SyncHealth.fromRows),
);

/// The single most relevant next action. Setup readiness first, then
/// QuickBooks authorization, then operational health from [health].
({String label, String route, String why}) recommendedNextAction(SetupStatus s, [SyncHealth? health, DateTime? now]) {
  if (!s.posConfigured) {
    return (label: 'Configurar la API del POS', route: Routes.configuracion, why: 'Sin la dirección del POS no se pueden leer las ventas.');
  }
  if (!s.qboCredentials) {
    return (label: 'Guardar credenciales de Intuit', route: Routes.configuracion, why: 'Se necesitan para conectar con QuickBooks.');
  }
  if (!s.qboConnected) {
    return (label: 'Conectar con QuickBooks', route: Routes.configuracion, why: 'Autorice a RM Ledger Sync a crear asientos.');
  }
  final exp = s.authExpiresAt;
  if (exp != null) {
    final days = exp.difference(now ?? DateTime.now()).inDays;
    if (days < 0) {
      return (
        label: 'Reconectar QuickBooks',
        route: Routes.configuracion,
        why: 'La autorización de QuickBooks venció. Sin ella no se pueden enviar asientos.'
      );
    }
    if (days <= 14) {
      return (
        label: 'Reconectar QuickBooks pronto',
        route: Routes.configuracion,
        why: 'La autorización vence en $days día(s). Reconecte para evitar envíos fallidos.'
      );
    }
  }
  if (!s.mappingsComplete) {
    return (
      label: 'Completar Mapeo de Cuentas',
      route: Routes.mapeo,
      why: 'Faltan ${s.totalCategories - s.mappedCount} categoría(s) por asignar a una cuenta.'
    );
  }
  if (health != null && health.lastFailed) {
    final n = health.failuresSinceSuccess;
    return (
      label: 'Revisar el error de la última sincronización',
      route: Routes.historial,
      why: n > 1
          ? '$n sincronizaciones fallaron desde el último envío exitoso. Abra el detalle para ver la causa.'
          : 'La última sincronización falló. Abra el detalle para ver la causa y cómo resolverla.'
    );
  }
  if (s.lastSyncAt == null && (health == null || health.neverSucceeded)) {
    return (label: 'Hacer su primera sincronización', route: Routes.vistaPrevia, why: 'Revise el asiento y envíelo a QuickBooks.');
  }
  if (!s.scheduleEnabled) {
    return (label: 'Programar envíos automáticos', route: Routes.sincronizaciones, why: 'Evite tener que enviar manualmente cada día.');
  }
  return (
    label: 'Revisar Vista Previa',
    route: Routes.vistaPrevia,
    why: 'La configuración está completa y la última sincronización fue exitosa. Puede revisar o enviar un rango cuando guste.'
  );
}
