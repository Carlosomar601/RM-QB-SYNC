import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../services/app_paths.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  OAuthConnections,
  AccountMappings,
  SyncSchedules,
  SyncHistory,
  Users,
  AuditLog,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-disk database at `%ProgramData%\RMQBsync\rmqbsync.db`.
  factory AppDatabase.open() => AppDatabase(NativeDatabase.createInBackground(File(defaultPath())));

  static String defaultPath() {
    final dir = AppPaths.dataDir;
    Directory(dir).createSync(recursive: true);
    return p.join(dir, 'rmqbsync.db');
  }

  /// In-memory database for tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  /// Bump this and add a step in [migration] when the schema changes.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sync_history_range ON sync_history (status, from_date, to_date)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_audit_ts ON audit_log (timestamp)');
        },
        onUpgrade: (m, from, to) async {
          // Future schema versions add stepwise migrations here.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );
}
