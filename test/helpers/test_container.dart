import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rmqbsync/app/providers.dart';
import 'package:rmqbsync/data/db/app_database.dart';
import 'package:rmqbsync/data/secrets/secret_store.dart';

typedef TestEnv = ({ProviderContainer container, AppDatabase db, InMemorySecretStore secrets});

/// Builds a ProviderContainer with an in-memory DB and secret store.
TestEnv makeContainer({
  HttpClientAdapter? adapter,
  DateTime Function()? clock,
  List overrides = const [],
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase.memory();
  final secrets = InMemorySecretStore();
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    secretStoreProvider.overrideWithValue(secrets),
    if (adapter != null) httpAdapterProvider.overrideWithValue(adapter),
    if (clock != null) clockProvider.overrideWithValue(clock),
    ...overrides.cast(),
  ]);
  return (container: container, db: db, secrets: secrets);
}
