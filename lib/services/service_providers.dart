import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/pos/pos_providers.dart';
import '../data/quickbooks/qbo_providers.dart';
import 'auth_service.dart';
import 'balance_diagnostic_service.dart';
import 'preview_service.dart';
import 'scheduler_service.dart';
import 'sync_pipeline.dart';

/// Overridable in tests to use cheap PBKDF2 iterations.
final passwordHasherProvider = Provider<PasswordHasher>((ref) => PasswordHasher());

final authServiceProvider = Provider<AuthService>((ref) => AuthService(
      db: ref.watch(databaseProvider),
      secrets: ref.watch(secretStoreProvider),
      audit: ref.watch(auditRepositoryProvider),
      hasher: ref.watch(passwordHasherProvider),
      clock: ref.watch(clockProvider),
    ));

final previewServiceProvider = Provider<PreviewService>((ref) => PreviewService(
      pos: ref.watch(posClientProvider),
      mappings: ref.watch(mappingRepositoryProvider),
    ));

final syncPipelineProvider = Provider<SyncPipeline>((ref) => SyncPipeline(
      preview: ref.watch(previewServiceProvider),
      qbo: ref.watch(qboApiClientProvider),
      history: ref.watch(historyRepositoryProvider),
      audit: ref.watch(auditRepositoryProvider),
      connections: ref.watch(connectionRepositoryProvider),
      clock: ref.watch(clockProvider),
    ));

final balanceDiagnosticProvider = Provider<BalanceDiagnosticService>(
  (ref) => BalanceDiagnosticService(ref.watch(posClientProvider)),
);

/// Long-lived scheduler. It resolves the pipeline at run time so POS
/// address / QBO changes made after start-up are always honoured.
final schedulerServiceProvider = Provider<SchedulerService>((ref) {
  final s = SchedulerService(
    schedules: ref.watch(scheduleRepositoryProvider),
    clock: ref.watch(clockProvider),
    runSync: ({required from, required to, required trigger, required user, allowDuplicate = false}) =>
        ref.read(syncPipelineProvider).runSync(
              from: from,
              to: to,
              trigger: trigger,
              user: user,
              allowDuplicate: allowDuplicate,
            ),
  );
  ref.onDispose(s.stop);
  return s;
});

/// Logged-in user (null = logged out).
class SessionNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void set(AppUser? user) => state = user;
}

final sessionProvider = NotifierProvider<SessionNotifier, AppUser?>(SessionNotifier.new);

/// Temporary admin password created on this launch (shown once on login).
class FirstRunPasswordNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final firstRunPasswordProvider = NotifierProvider<FirstRunPasswordNotifier, String?>(FirstRunPasswordNotifier.new);
