import 'package:drift/drift.dart';

/// One row per connected QuickBooks company (only one is used).
class OAuthConnections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get edition => text().withDefault(const Constant('QuickBooksOnline'))();
  TextColumn get environment => text().withDefault(const Constant('sandbox'))();
  TextColumn get realmId => text()();
  TextColumn get companyName => text().nullable()();
  DateTimeColumn get accessTokenExpiresAt => dateTime().nullable()();
  DateTimeColumn get refreshTokenExpiresAt => dateTime().nullable()();
  DateTimeColumn get connectedAt => dateTime()();
  DateTimeColumn get lastRefreshAt => dateTime().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

class AccountMappings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text().unique()();
  TextColumn get accountId => text()();
  TextColumn get accountName => text()();
  TextColumn get side => text()(); // Debit | Credit
  TextColumn get description => text().nullable()();
  TextColumn get entityType => text().nullable()(); // Customer | Vendor
  TextColumn get entityId => text().nullable()();
  TextColumn get entityName => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

class SyncSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  TextColumn get frequency => text()(); // daily | weekly | monthly
  TextColumn get timeOfDay => text()(); // HH:mm
  IntColumn get dayOfWeek => integer().nullable()();
  IntColumn get dayOfMonth => integer().nullable()();
  DateTimeColumn get lastRunAt => dateTime().nullable()();
  DateTimeColumn get nextRunAt => dateTime().nullable()();
}

class SyncHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get ranAt => dateTime()();
  TextColumn get trigger => text()();
  TextColumn get performedBy => text()();
  DateTimeColumn get fromDate => dateTime()();
  DateTimeColumn get toDate => dateTime()();
  TextColumn get status => text()();
  RealColumn get totalDebit => real().nullable()();
  RealColumn get totalCredit => real().nullable()();
  TextColumn get qboJournalEntryId => text().nullable()();
  TextColumn get requestJson => text().nullable()();
  TextColumn get responseJson => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get displayName => text()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get mustChangePassword => boolean().withDefault(const Constant(false))();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
}

class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get username => text()();
  TextColumn get action => text()();
  TextColumn get details => text().nullable()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
