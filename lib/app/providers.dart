import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/repositories.dart';
import '../data/secrets/secret_store.dart';

/// Must be overridden in `main()` / tests.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider'));

/// Must be overridden in `main()` / tests.
final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());

/// Injectable clock (tests override).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Optional HTTP adapter override for tests (applies to every dio instance).
final httpAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final mappingRepositoryProvider = Provider((ref) => MappingRepository(ref.watch(databaseProvider)));
final historyRepositoryProvider = Provider((ref) => HistoryRepository(ref.watch(databaseProvider)));
final auditRepositoryProvider = Provider((ref) => AuditRepository(ref.watch(databaseProvider)));
final scheduleRepositoryProvider = Provider((ref) => ScheduleRepository(ref.watch(databaseProvider)));
final connectionRepositoryProvider = Provider((ref) => ConnectionRepository(ref.watch(databaseProvider)));
