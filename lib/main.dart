import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/dates.dart';
import 'core/sync_rules.dart';
import 'data/db/app_database.dart';
import 'data/quickbooks/qbo_providers.dart';
import 'data/secrets/secret_store.dart';
import 'services/app_logger.dart';
import 'services/app_paths.dart';
import 'services/desktop_integration.dart';
import 'services/factory_secrets_seeder.dart';
import 'services/service_providers.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init(AppPaths.logsDir);
  FlutterError.onError = (d) => AppLogger.error('Error de interfaz: ${d.exceptionAsString()}', d.exception, d.stack);
  PlatformDispatcher.instance.onError = (e, st) {
    AppLogger.error('Error no controlado', e, st);
    return true;
  };

  DesktopIntegration? desktop;
  if (!await SingleInstance.acquire(() => desktop?.showWindow())) {
    // Another instance is running; it was asked to show itself.
    exit(0);
  }

  await initializeDateFormatting('es');
  final db = AppDatabase.open();
  final secrets = SecureSecretStore();
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    secretStoreProvider.overrideWithValue(secrets),
  ]);

  AppLogger.info('RMQBsync iniciado (datos en ${AppPaths.dataDir}).');
  await FactorySecretsSeeder(secrets, container.read(settingsRepositoryProvider))
      .seedIfNeeded(File(AppPaths.factorySecretsFile));
  await container.read(historyRepositoryProvider).failStaleRunning();

  final auth = container.read(authServiceProvider);
  final temp = await auth.ensureSeedAdmin();
  if (temp != null) container.read(firstRunPasswordProvider.notifier).set(temp);
  final restored = await auth.restoreSession();
  if (restored != null) container.read(sessionProvider.notifier).set(restored);

  desktop = DesktopIntegration(onSyncNow: () async {
    final today = Dates.today();
    final user = container.read(sessionProvider)?.username ?? 'Bandeja del sistema';
    final r = await container
        .read(syncPipelineProvider)
        .runSync(from: today, to: today, trigger: SyncTrigger.manual, user: user);
    desktop?.setTooltip('RMQBsync – ${r.status.label}: ${r.message}');
  });
  await desktop.init(startMinimized: args.contains('--minimized'));

  container.read(tokenManagerProvider).startProactiveRefresh();
  final scheduler = container.read(schedulerServiceProvider);
  scheduler.onRun = (r) => desktop?.setTooltip('RMQBsync – última programada: ${r.status.label}');
  scheduler.start();

  runApp(UncontrolledProviderScope(container: container, child: const RmqbApp()));
}
