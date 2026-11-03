import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as s3;

import '../../core/dates.dart';
import '../../services/app_logger.dart';
import 'app_database.dart';

/// Data recovered from the legacy C#/EF Core database.
class LegacyData {
  LegacyData({
    required this.mappings,
    required this.schedules,
    required this.history,
    required this.lastSyncAt,
    required this.backupPath,
  });

  final List<AccountMappingsCompanion> mappings;
  final List<SyncSchedulesCompanion> schedules;
  final List<SyncHistoryCompanion> history;
  final DateTime? lastSyncAt;
  final String backupPath;
}

/// The legacy Blazor app stored its EF Core database at the same path
/// (`%ProgramData%\RMQBsync\rmqbsync.db`). SQLite table names are
/// case-insensitive, so its `Users` table would collide with ours.
///
/// On first start we detect it (`__EFMigrationsHistory`), read the useful
/// data, move the file aside (`rmqbsync-legacy-<timestamp>.db`) and import
/// mappings, schedules and history into the new database. History matters:
/// it keeps the duplicate rule from re-posting ranges already sent to QBO.
/// Tokens/users are not migrated (DPAPI-bound / different hash format):
/// QuickBooks must be reconnected and the admin password set again.
abstract final class LegacyMigrator {
  static bool isLegacyDatabase(String dbPath) {
    if (!File(dbPath).existsSync()) return false;
    final db = s3.sqlite3.open(dbPath, mode: s3.OpenMode.readOnly);
    try {
      return db.select("SELECT 1 FROM sqlite_master WHERE type='table' AND name='__EFMigrationsHistory'").isNotEmpty;
    } finally {
      db.close();
    }
  }

  /// EF Core `DateTimeOffsetToBinaryConverter` → UTC DateTime (local).
  static DateTime? fromEfBinary(Object? v) {
    if (v == null) return null;
    final value = (v as num).toInt();
    final ticks = (value >> 11) * 1000;
    var offsetMinutes = value & 0x7FF;
    if (offsetMinutes >= 0x400) offsetMinutes -= 0x800;
    const epochTicks = 621355968000000000;
    final utcTicks = ticks - offsetMinutes * 600000000;
    return DateTime.fromMicrosecondsSinceEpoch((utcTicks - epochTicks) ~/ 10, isUtc: true).toLocal();
  }

  static double? _dec(Object? v) => v == null ? null : double.tryParse(v.toString());

  /// Reads the legacy DB and moves it aside. Returns null if not legacy.
  static LegacyData? extractAndMoveAside(String dbPath, {DateTime? now}) {
    if (!isLegacyDatabase(dbPath)) return null;
    final db = s3.sqlite3.open(dbPath, mode: s3.OpenMode.readOnly);
    final mappings = <AccountMappingsCompanion>[];
    final schedules = <SyncSchedulesCompanion>[];
    final history = <SyncHistoryCompanion>[];
    DateTime? lastSync;
    bool hasTable(String t) => db.select("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", [t]).isNotEmpty;
    try {
      if (hasTable('AccountMappings')) {
        for (final r in db.select('SELECT * FROM AccountMappings')) {
          final et = r['EntityType'] as int?;
          mappings.add(AccountMappingsCompanion.insert(
            category: r['Category'] as String,
            accountId: r['AccountId'] as String,
            accountName: r['AccountName'] as String,
            side: (r['Side'] as int) == 1 ? 'Credit' : 'Debit',
            description: Value(r['Description'] as String?),
            entityType: Value(et == null ? null : (et == 1 ? 'Vendor' : 'Customer')),
            entityId: Value(r['EntityId'] as String?),
            entityDisplayName: Value(r['EntityName'] as String?),
            updatedAt: now ?? DateTime.now(),
          ));
        }
      }
      if (hasTable('SyncSchedules')) {
        for (final r in db.select('SELECT * FROM SyncSchedules')) {
          final t = (r['TimeOfDay'] as String? ?? '23:00').split(':');
          schedules.add(SyncSchedulesCompanion.insert(
            enabled: Value((r['Enabled'] as int) == 1),
            frequency: const ['daily', 'weekly', 'monthly'][(r['Frequency'] as int).clamp(0, 2)],
            timeOfDay: '${t[0].padLeft(2, '0')}:${(t.length > 1 ? t[1] : '00').padLeft(2, '0')}',
            dayOfWeek: Value(r['DayOfWeek'] as int?),
            dayOfMonth: Value(r['DayOfMonth'] as int?),
            lastRunAt: Value(fromEfBinary(r['LastRunAt'])),
            // Recomputed by the scheduler on start.
            nextRunAt: const Value(null),
          ));
        }
      }
      if (hasTable('SyncHistory')) {
        for (final r in db.select('SELECT * FROM SyncHistory ORDER BY Id')) {
          final from = Dates.tryParseDate(r['FromDate']);
          final to = Dates.tryParseDate(r['ToDate']);
          if (from == null || to == null) continue;
          history.add(SyncHistoryCompanion.insert(
            ranAt: fromEfBinary(r['RanAt']) ?? from,
            trigger: (r['Trigger'] as int) == 1 ? 'Scheduled' : 'Manual',
            performedBy: (r['PerformedByUsername'] as String?) ?? 'Sistema (versión anterior)',
            fromDate: from,
            toDate: to,
            status: const ['Success', 'Failed', 'Skipped'][(r['Status'] as int).clamp(0, 2)],
            totalDebit: Value(_dec(r['TotalDebit'])),
            totalCredit: Value(_dec(r['TotalCredit'])),
            qboJournalEntryId: Value(r['QuickBooksJournalEntryId'] as String?),
            requestJson: Value(r['RequestJson'] as String?),
            responseJson: Value(r['ResponseJson'] as String?),
            errorMessage: Value(r['ErrorMessage'] as String?),
          ));
        }
      }
      if (hasTable('OAuthConnections')) {
        for (final r in db.select('SELECT LastSyncAt FROM OAuthConnections')) {
          final d = fromEfBinary(r['LastSyncAt']);
          if (d != null && (lastSync == null || d.isAfter(lastSync))) lastSync = d;
        }
      }
    } finally {
      db.close();
    }

    final stamp = (now ?? DateTime.now()).toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
    final backup = p.join(p.dirname(dbPath), 'rmqbsync-legacy-$stamp.db');
    File(dbPath).renameSync(backup);
    for (final suffix in ['-wal', '-shm']) {
      final f = File('$dbPath$suffix');
      if (f.existsSync()) f.renameSync('$backup$suffix');
    }
    AppLogger.info('Base de datos de la versión anterior movida a $backup '
        '(${mappings.length} mapeos, ${schedules.length} programaciones, ${history.length} historiales).');
    return LegacyData(
      mappings: mappings,
      schedules: schedules,
      history: history,
      lastSyncAt: lastSync,
      backupPath: backup,
    );
  }

  /// Inserts the recovered data into the new database.
  static Future<void> importInto(AppDatabase db, LegacyData data) async {
    await db.transaction(() async {
      for (final m in data.mappings) {
        await db.into(db.accountMappings).insert(m, mode: InsertMode.insertOrReplace);
      }
      for (final s in data.schedules.take(1)) {
        await db.into(db.syncSchedules).insert(s);
      }
      for (final h in data.history) {
        await db.into(db.syncHistory).insert(h);
      }
      await db.into(db.auditLog).insert(AuditLogCompanion.insert(
            timestamp: DateTime.now(),
            username: 'Sistema',
            action: 'MigracionVersionAnterior',
            details: Value('${data.mappings.length} mapeos, ${data.schedules.length} programaciones y '
                '${data.history.length} registros de historial importados. Copia: ${data.backupPath}'),
          ));
      await db.into(db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(
            key: 'legacy.importedFrom',
            value: data.backupPath,
          ));
    });
  }
}
