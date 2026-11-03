import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/account_mapping.dart';
import '../core/constants.dart';
import '../data/db/repositories.dart';
import '../data/pos/pos_providers.dart';
import '../data/quickbooks/qbo_providers.dart';
import '../services/service_providers.dart';
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
  });

  final bool posConfigured;
  final bool qboCredentials;
  final bool qboConnected;
  final int mappedCount;
  final int totalCategories;
  final bool scheduleEnabled;
  final String? companyName;
  final String? posUrl;
  final DateTime? lastSyncAt;

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
    mappedCount: PosCategories.all.where(maps.containsKey).length,
    totalCategories: PosCategories.all.length,
    scheduleEnabled: sched?.enabled ?? false,
  );
});

/// The single most relevant next action for the current setup state.
({String label, String route, String why}) recommendedNextAction(SetupStatus s) {
  if (!s.posConfigured) {
    return (label: 'Configurar la API del POS', route: '/configuracion', why: 'Sin la dirección del POS no se pueden leer las ventas.');
  }
  if (!s.qboCredentials) {
    return (label: 'Guardar credenciales de Intuit', route: '/configuracion', why: 'Se necesitan para conectar con QuickBooks.');
  }
  if (!s.qboConnected) {
    return (label: 'Conectar con QuickBooks', route: '/configuracion', why: 'Autorice a RMQBsync a crear asientos.');
  }
  if (!s.mappingsComplete) {
    return (
      label: 'Completar Mapeo de Cuentas',
      route: '/mapeo',
      why: 'Faltan ${s.totalCategories - s.mappedCount} categoría(s) por asignar a una cuenta.'
    );
  }
  if (s.lastSyncAt == null) {
    return (label: 'Hacer su primera sincronización', route: '/vista-previa', why: 'Revise el asiento y envíelo a QuickBooks.');
  }
  if (!s.scheduleEnabled) {
    return (label: 'Programar envíos automáticos', route: '/sincronizaciones', why: 'Evite tener que enviar manualmente cada día.');
  }
  return (label: 'Revisar Vista Previa', route: '/vista-previa', why: 'Todo está configurado. Puede revisar o enviar un rango cuando guste.');
}
