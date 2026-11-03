import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rmqbsync/core/sync_rules.dart';
import 'package:rmqbsync/data/db/app_database.dart';
import 'package:rmqbsync/data/db/legacy_migrator.dart';
import 'package:rmqbsync/data/db/repositories.dart';
import 'package:sqlite3/sqlite3.dart';

/// EF Core DateTimeOffsetToBinaryConverter (UTC offset 0).
int efBinary(DateTime utc) {
  const epochTicks = 621355968000000000;
  final ticks = utc.microsecondsSinceEpoch * 10 + epochTicks;
  return (ticks ~/ 1000) << 11;
}

void main() {
  test('EF binary DateTimeOffset decoding (incl. negative offset)', () {
    final utc = DateTime.utc(2026, 5, 21, 23, 0, 0);
    expect(LegacyMigrator.fromEfBinary(efBinary(utc))!.toUtc(), utc);
    // 2026-05-21 19:00 at -04:00 (Puerto Rico) == 23:00 UTC.
    const epochTicks = 621355968000000000;
    final localTicks = DateTime.utc(2026, 5, 21, 19).microsecondsSinceEpoch * 10 + epochTicks;
    final v = ((localTicks ~/ 1000) << 11) | ((-240) & 0x7FF);
    expect(LegacyMigrator.fromEfBinary(v)!.toUtc(), utc);
  });

  test('detects EF database, imports mappings/schedule/history, moves file aside', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = Directory.systemTemp.createTempSync('rmqb-legacy');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'rmqbsync.db');

    final legacy = sqlite3.open(path);
    legacy.execute('''
      CREATE TABLE "__EFMigrationsHistory" (MigrationId TEXT PRIMARY KEY, ProductVersion TEXT);
      CREATE TABLE AccountMappings (Id INTEGER PRIMARY KEY, Category TEXT, AccountId TEXT, AccountName TEXT,
        Side INTEGER, Description TEXT, EntityType INTEGER, EntityId TEXT, EntityName TEXT);
      CREATE TABLE SyncSchedules (Id INTEGER PRIMARY KEY, Enabled INTEGER, Frequency INTEGER, TimeOfDay TEXT,
        DayOfWeek INTEGER, DayOfMonth INTEGER, LastRunAt INTEGER, NextRunAt INTEGER);
      CREATE TABLE SyncHistory (Id INTEGER PRIMARY KEY, RanAt INTEGER, Trigger INTEGER, PerformedByUsername TEXT,
        FromDate TEXT, ToDate TEXT, Status INTEGER, TotalDebit TEXT, TotalCredit TEXT, QuickBooksJournalEntryId TEXT,
        RequestJson TEXT, ResponseJson TEXT, ErrorMessage TEXT);
      CREATE TABLE OAuthConnections (Id INTEGER PRIMARY KEY, LastSyncAt INTEGER);
      CREATE TABLE Users (Id INTEGER PRIMARY KEY, Username TEXT);
    ''');
    legacy.execute("INSERT INTO AccountMappings VALUES (1,'Efectivo','35','Caja',0,NULL,NULL,NULL,NULL)");
    legacy.execute("INSERT INTO AccountMappings VALUES (2,'PendienteDeCobro','84','AR',0,'Credito',0,'1','Cliente Generico')");
    legacy.execute("INSERT INTO AccountMappings VALUES (3,'VentaNeta','79','Ventas',1,NULL,NULL,NULL,NULL)");
    legacy.execute("INSERT INTO SyncSchedules VALUES (1,1,1,'23:30:00',5,NULL,NULL,NULL)");
    legacy.execute('INSERT INTO SyncHistory VALUES (1,?,0,\'RM\',\'2026-05-01\',\'2026-05-21\',0,\'12800.00\',\'12800.00\',\'145\',\'{}\',\'{}\',NULL)',
        [efBinary(DateTime.utc(2026, 5, 22, 3))]);
    legacy.execute('INSERT INTO SyncHistory VALUES (2,?,1,NULL,\'2026-05-22\',\'2026-05-22\',1,NULL,NULL,NULL,NULL,NULL,\'boom\')',
        [efBinary(DateTime.utc(2026, 5, 23, 3))]);
    legacy.execute('INSERT INTO OAuthConnections VALUES (1, ?)', [efBinary(DateTime.utc(2026, 5, 22, 3))]);
    legacy.close();

    final data = LegacyMigrator.extractAndMoveAside(path, now: DateTime(2026, 11, 3, 14, 5, 6))!;
    expect(File(path).existsSync(), isFalse);
    expect(File(data.backupPath).existsSync(), isTrue);
    expect(p.basename(data.backupPath), 'rmqbsync-legacy-20261103140506.db');
    expect(LegacyMigrator.extractAndMoveAside(path), isNull); // nothing left to migrate

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);
    await LegacyMigrator.importInto(db, data);

    final maps = await MappingRepository(db).byCategory();
    expect(maps.keys, containsAll(['Efectivo', 'PendienteDeCobro', 'VentaNeta']));
    expect(maps['VentaNeta']!.side.qboName, 'Credit');
    expect(maps['PendienteDeCobro']!.entityName, 'Cliente Generico');
    expect(maps['PendienteDeCobro']!.entityType!.qboName, 'Customer');

    final sched = (await ScheduleRepository(db).single())!;
    expect(sched.frequency.name, 'weekly');
    expect(sched.timeOfDay.toString(), '23:30');
    expect(sched.dayOfWeek, 5);

    // Imported history keeps the duplicate rule effective.
    final hist = HistoryRepository(db);
    final dup = await hist.findOverlappingSuccess(DateTime(2026, 5, 10), DateTime(2026, 5, 10));
    expect(dup, isNotNull);
    expect(dup!.status, SyncStatus.success);
    final rows = await hist.recent();
    expect(rows, hasLength(2));
    expect(rows.firstWhere((r) => r.qboJournalEntryId == '145').totalDebit, 12800.00);
    expect(rows.firstWhere((r) => r.errorMessage == 'boom').trigger, 'Scheduled');
  });
}
