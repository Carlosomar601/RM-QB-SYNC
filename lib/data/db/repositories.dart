import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/account_mapping.dart';
import '../../core/pos_address.dart';
import '../../core/schedule.dart';
import '../../core/sync_rules.dart';
import 'app_database.dart';

// ---------------------------------------------------------------------------
// Settings (key/value)
// ---------------------------------------------------------------------------

abstract final class SettingKeys {
  static const posAddress = 'pos.address';
  static const posHistory = 'pos.history';
  static const qboEnvironment = 'qbo.environment';
  static const launchAtStartup = 'app.launchAtStartup';
  static const setupWizardDone = 'app.setupWizardDone';
  static String tourDone(String user) => 'tour.done.$user';
  static String themeMode(String user) => 'ui.theme.$user';

  /// Last appearance chosen on this computer; used before login and for
  /// users who have not chosen one yet.
  static const themeModeDevice = 'ui.theme';
  static String draft(String wizard, String user) => 'draft.$wizard.$user';
}

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDatabase db;

  Future<String?> get(String key) async {
    final row = await (db.select(db.appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) =>
      db.into(db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<void> remove(String key) => (db.delete(db.appSettings)..where((t) => t.key.equals(key))).go();

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final v = await get(key);
    return v == null ? fallback : v == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value.toString());

  Future<Map<String, Object?>?> getJson(String key) async {
    final v = await get(key);
    if (v == null || v.isEmpty) return null;
    return jsonDecode(v) as Map<String, Object?>;
  }

  Future<void> setJson(String key, Map<String, Object?> value) => set(key, jsonEncode(value));

  // --- POS address -------------------------------------------------------

  Future<PosAddress?> getPosAddress() async {
    final j = await getJson(SettingKeys.posAddress);
    if (j == null) return null;
    final a = PosAddress.fromJson(j);
    return a.isConfigured ? a : null;
  }

  Future<void> setPosAddress(PosAddress a) => setJson(SettingKeys.posAddress, a.toJson());

  /// Last 5 distinct addresses, most recent first.
  Future<List<PosAddress>> getPosHistory() async {
    final v = await get(SettingKeys.posHistory);
    if (v == null) return const [];
    return (jsonDecode(v) as List).cast<Map<String, Object?>>().map(PosAddress.fromJson).toList();
  }

  Future<void> pushPosHistory(PosAddress a) async {
    final list = [a, ...(await getPosHistory()).where((x) => x.baseUrl != a.baseUrl)].take(5).toList();
    await set(SettingKeys.posHistory, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // --- QBO environment -----------------------------------------------------

  Future<String> getQboEnvironment() async => (await get(SettingKeys.qboEnvironment)) ?? 'sandbox';
  Future<void> setQboEnvironment(String env) => set(SettingKeys.qboEnvironment, env);
}

// ---------------------------------------------------------------------------
// Account mappings
// ---------------------------------------------------------------------------

class MappingRepository {
  MappingRepository(this.db);
  final AppDatabase db;

  static AccountMapping toDomain(AccountMappingRow r) => AccountMapping(
        category: r.category,
        accountId: r.accountId,
        accountName: r.accountName,
        side: PostingSide.parse(r.side),
        description: r.description,
        entityType: EntityType.tryParse(r.entityType),
        entityId: r.entityId,
        entityName: r.entityDisplayName,
      );

  Future<List<AccountMapping>> all() async =>
      (await (db.select(db.accountMappings)..orderBy([(t) => OrderingTerm.asc(t.category)])).get())
          .map(toDomain)
          .toList();

  Future<Map<String, AccountMapping>> byCategory() async => {for (final m in await all()) m.category: m};

  Future<void> upsert(AccountMapping m) => db.into(db.accountMappings).insert(
        AccountMappingsCompanion.insert(
          category: m.category,
          accountId: m.accountId,
          accountName: m.accountName,
          side: m.side.qboName,
          description: Value(m.description),
          entityType: Value(m.entityType?.qboName),
          entityId: Value(m.entityType == null ? null : m.entityId),
          entityDisplayName: Value(m.entityType == null ? null : m.entityName),
          updatedAt: DateTime.now(),
        ),
        onConflict: DoUpdate.withExcluded((old, excluded) => AccountMappingsCompanion.custom(
              accountId: excluded.accountId,
              accountName: excluded.accountName,
              side: excluded.side,
              description: excluded.description,
              entityType: excluded.entityType,
              entityId: excluded.entityId,
              entityDisplayName: excluded.entityDisplayName,
              updatedAt: excluded.updatedAt,
            ), target: [db.accountMappings.category]),
      );

  Future<void> deleteCategory(String category) =>
      (db.delete(db.accountMappings)..where((t) => t.category.equals(category))).go();
}

// ---------------------------------------------------------------------------
// Sync history
// ---------------------------------------------------------------------------

class HistoryRepository {
  HistoryRepository(this.db);
  final AppDatabase db;

  Future<int> start({
    required SyncTrigger trigger,
    required String performedBy,
    required DateTime from,
    required DateTime to,
    DateTime? now,
  }) =>
      db.into(db.syncHistory).insert(SyncHistoryCompanion.insert(
            ranAt: now ?? DateTime.now(),
            trigger: trigger.code,
            performedBy: performedBy,
            fromDate: from,
            toDate: to,
            status: SyncStatus.running.code,
          ));

  Future<void> finish(
    int id, {
    required SyncStatus status,
    double? totalDebit,
    double? totalCredit,
    String? qboJournalEntryId,
    String? requestJson,
    String? responseJson,
    String? errorMessage,
  }) =>
      (db.update(db.syncHistory)..where((t) => t.id.equals(id))).write(SyncHistoryCompanion(
        status: Value(status.code),
        totalDebit: Value(totalDebit),
        totalCredit: Value(totalCredit),
        qboJournalEntryId: Value(qboJournalEntryId),
        requestJson: Value(requestJson),
        responseJson: Value(responseJson),
        errorMessage: Value(errorMessage),
      ));

  /// First successful run whose range overlaps [from]..[to], excluding [excludeId].
  Future<SyncRangeRecord?> findOverlappingSuccess(DateTime from, DateTime to, {int? excludeId}) async {
    final q = db.select(db.syncHistory)
      ..where((t) =>
          t.status.equals(SyncStatus.success.code) &
          t.fromDate.isSmallerOrEqualValue(to) &
          t.toDate.isBiggerOrEqualValue(from) &
          (excludeId == null ? const Constant(true) : t.id.equals(excludeId).not()))
      ..orderBy([(t) => OrderingTerm.desc(t.ranAt)])
      ..limit(1);
    final r = await q.getSingleOrNull();
    return r == null
        ? null
        : SyncRangeRecord(id: r.id, from: r.fromDate, to: r.toDate, status: SyncStatus.parse(r.status));
  }

  Future<List<SyncHistoryRow>> recent([int limit = 200]) =>
      (db.select(db.syncHistory)
            ..orderBy([(t) => OrderingTerm.desc(t.ranAt), (t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .get();

  Stream<List<SyncHistoryRow>> watchRecent([int limit = 200]) =>
      (db.select(db.syncHistory)
            ..orderBy([(t) => OrderingTerm.desc(t.ranAt), (t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .watch();

  /// Marks rows left in "Running" by a crash as failed.
  Future<void> failStaleRunning() =>
      (db.update(db.syncHistory)..where((t) => t.status.equals(SyncStatus.running.code))).write(
        const SyncHistoryCompanion(
          status: Value('Failed'),
          errorMessage: Value('La aplicación se cerró antes de terminar la sincronización.'),
        ),
      );
}

// ---------------------------------------------------------------------------
// Audit
// ---------------------------------------------------------------------------

class AuditRepository {
  AuditRepository(this.db);
  final AppDatabase db;

  Future<void> log(String username, String action, [String? details]) =>
      db.into(db.auditLog).insert(AuditLogCompanion.insert(
            timestamp: DateTime.now(),
            username: username,
            action: action,
            details: Value(details),
          ));

  Future<List<AuditLogRow>> recent([int limit = 300]) =>
      (db.select(db.auditLog)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp), (t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .get();
}

// ---------------------------------------------------------------------------
// Schedules
// ---------------------------------------------------------------------------

class ScheduleModel {
  const ScheduleModel({
    this.id,
    required this.enabled,
    required this.frequency,
    required this.timeOfDay,
    this.dayOfWeek,
    this.dayOfMonth,
    this.lastRunAt,
    this.nextRunAt,
  });

  final int? id;
  final bool enabled;
  final ScheduleFrequency frequency;
  final TimeOfDayHm timeOfDay;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;

  static ScheduleModel fromRow(SyncScheduleRow r) => ScheduleModel(
        id: r.id,
        enabled: r.enabled,
        frequency: ScheduleFrequency.parse(r.frequency),
        timeOfDay: TimeOfDayHm.parse(r.timeOfDay),
        dayOfWeek: r.dayOfWeek,
        dayOfMonth: r.dayOfMonth,
        lastRunAt: r.lastRunAt,
        nextRunAt: r.nextRunAt,
      );

  DateTime computeNext(DateTime now) => ScheduleCalculator.nextRun(
        frequency: frequency,
        timeOfDay: timeOfDay,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
        now: now,
      );

  String get description => ScheduleCalculator.describe(
        frequency: frequency,
        timeOfDay: timeOfDay,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
      );
}

class ScheduleRepository {
  ScheduleRepository(this.db);
  final AppDatabase db;

  Future<List<ScheduleModel>> all() async =>
      (await db.select(db.syncSchedules).get()).map(ScheduleModel.fromRow).toList();

  Future<ScheduleModel?> single() async {
    final rows = await (db.select(db.syncSchedules)..orderBy([(t) => OrderingTerm.asc(t.id)])..limit(1)).get();
    return rows.isEmpty ? null : ScheduleModel.fromRow(rows.first);
  }

  /// Saves the (single) schedule and recomputes its next run.
  Future<ScheduleModel> save(ScheduleModel m, {DateTime? now}) async {
    final next = m.enabled ? m.computeNext(now ?? DateTime.now()) : null;
    final companion = SyncSchedulesCompanion(
      enabled: Value(m.enabled),
      frequency: Value(m.frequency.name),
      timeOfDay: Value(m.timeOfDay.toString()),
      dayOfWeek: Value(m.frequency == ScheduleFrequency.weekly ? (m.dayOfWeek ?? 1) : null),
      dayOfMonth: Value(m.frequency == ScheduleFrequency.monthly ? (m.dayOfMonth ?? 1) : null),
      nextRunAt: Value(next),
    );
    final existing = await single();
    if (existing == null) {
      await db.into(db.syncSchedules).insert(companion);
    } else {
      await (db.update(db.syncSchedules)..where((t) => t.id.equals(existing.id!))).write(companion);
    }
    return (await single())!;
  }

  Future<void> markRun(int id, {required DateTime ranAt, required DateTime? nextRunAt}) =>
      (db.update(db.syncSchedules)..where((t) => t.id.equals(id)))
          .write(SyncSchedulesCompanion(lastRunAt: Value(ranAt), nextRunAt: Value(nextRunAt)));

  Future<void> setNext(int id, DateTime? next) =>
      (db.update(db.syncSchedules)..where((t) => t.id.equals(id))).write(SyncSchedulesCompanion(nextRunAt: Value(next)));
}

// ---------------------------------------------------------------------------
// QBO connection metadata (tokens live in secure storage)
// ---------------------------------------------------------------------------

class ConnectionRepository {
  ConnectionRepository(this.db);
  final AppDatabase db;

  Future<OAuthConnectionRow?> current() =>
      (db.select(db.oAuthConnections)..orderBy([(t) => OrderingTerm.desc(t.id)])..limit(1)).getSingleOrNull();

  Stream<OAuthConnectionRow?> watchCurrent() =>
      (db.select(db.oAuthConnections)..orderBy([(t) => OrderingTerm.desc(t.id)])..limit(1)).watchSingleOrNull();

  Future<void> replace({
    required String realmId,
    required String environment,
    String? companyName,
    required DateTime accessExpiresAt,
    required DateTime refreshExpiresAt,
  }) async {
    await db.transaction(() async {
      await db.delete(db.oAuthConnections).go();
      await db.into(db.oAuthConnections).insert(OAuthConnectionsCompanion.insert(
            realmId: realmId,
            environment: Value(environment),
            companyName: Value(companyName),
            accessTokenExpiresAt: Value(accessExpiresAt),
            refreshTokenExpiresAt: Value(refreshExpiresAt),
            connectedAt: DateTime.now(),
          ));
    });
  }

  Future<void> updateTokens({required DateTime accessExpiresAt, required DateTime refreshExpiresAt}) async {
    final c = await current();
    if (c == null) return;
    await (db.update(db.oAuthConnections)..where((t) => t.id.equals(c.id))).write(OAuthConnectionsCompanion(
      accessTokenExpiresAt: Value(accessExpiresAt),
      refreshTokenExpiresAt: Value(refreshExpiresAt),
      lastRefreshAt: Value(DateTime.now()),
    ));
  }

  Future<void> setCompanyName(String name) async {
    final c = await current();
    if (c == null) return;
    await (db.update(db.oAuthConnections)..where((t) => t.id.equals(c.id)))
        .write(OAuthConnectionsCompanion(companyName: Value(name)));
  }

  Future<void> setLastSync(DateTime at) async {
    final c = await current();
    if (c == null) return;
    await (db.update(db.oAuthConnections)..where((t) => t.id.equals(c.id)))
        .write(OAuthConnectionsCompanion(lastSyncAt: Value(at)));
  }

  Future<void> clear() => db.delete(db.oAuthConnections).go();
}
