import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/providers.dart';
import 'package:rmqbsync/core/account_mapping.dart';
import 'package:rmqbsync/core/constants.dart';
import 'package:rmqbsync/core/pos_address.dart';
import 'package:rmqbsync/core/schedule.dart';
import 'package:rmqbsync/core/sync_rules.dart';
import 'package:rmqbsync/data/db/repositories.dart';
import 'package:rmqbsync/data/pos/pos_providers.dart';
import 'package:rmqbsync/data/quickbooks/qbo_providers.dart';
import 'package:rmqbsync/data/secrets/secret_store.dart';
import 'package:rmqbsync/services/auth_service.dart';
import 'package:rmqbsync/services/scheduler_service.dart';
import 'package:rmqbsync/services/service_providers.dart';
import 'package:rmqbsync/services/sync_pipeline.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_container.dart';

/// One POS day: Ventas 100 (VentaNeta 90 + StateTax 10), Pagos 100 (cash 60 + card 40).
Map<String, Object> posDay({double cash = 60}) => {
      'Subtotal': 90,
      'TotalCityTax': 0,
      'TotalStateTax': 10,
      'TotalDiscounts': 0,
      'CashPayments': cash,
      'CreditCardPayments': 40,
      'DebitCardPayments': 0,
      'CheckPayments': 0,
      'AthMovilPayments': 0,
    };

void main() {
  late TestEnv t;
  late FakeAdapter adapter;
  var posRows = <Map<String, Object>>[posDay()];
  var qboCalls = 0;
  var now = DateTime(2026, 11, 3, 12);

  Future<void> mapAll(MappingRepository repo) async {
    for (final c in PosCategories.ventas) {
      await repo.upsert(AccountMapping(category: c, accountId: 'V-$c', accountName: c, side: PostingSide.credit));
    }
    for (final c in PosCategories.pagos) {
      await repo.upsert(AccountMapping(category: c, accountId: 'P-$c', accountName: c, side: PostingSide.debit));
    }
  }

  setUp(() async {
    posRows = [posDay()];
    qboCalls = 0;
    now = DateTime(2026, 11, 3, 12);
    adapter = FakeAdapter((o) async {
      final u = o.uri.toString();
      if (u.contains('SalesByMethod')) return FakeResponse(200, posRows);
      if (u.contains('ARReconciliationInvoices')) {
        return const FakeResponse(200, {'success': true, 'page': 1, 'total_pages': 1, 'data': []});
      }
      if (u.contains('/journalentry')) {
        qboCalls++;
        return FakeResponse(200, {'JournalEntry': {'Id': '${100 + qboCalls}'}});
      }
      return const FakeResponse(404, {});
    });
    t = makeContainer(adapter: adapter, clock: () => now, overrides: [
      passwordHasherProvider.overrideWithValue(PasswordHasher(iterations: 1000)),
      retrySleepProvider.overrideWithValue((_) async {}),
    ]);
    final c = t.container;
    await c.read(posConfigProvider.notifier).save(address: const PosAddress(host: '192.168.1.50', port: 8180), username: 'admin');
    await t.secrets.write(SecretKeys.qboClientId, 'id');
    await t.secrets.write(SecretKeys.qboClientSecret, 'sec');
    await t.secrets.write(SecretKeys.qboAccessToken, 'AT');
    await t.secrets.write(SecretKeys.qboRefreshToken, 'RT');
    await c.read(connectionRepositoryProvider).replace(
        realmId: '1', environment: 'sandbox', accessExpiresAt: now.add(const Duration(hours: 1)), refreshExpiresAt: now.add(const Duration(days: 90)));
    await mapAll(c.read(mappingRepositoryProvider));
  });

  tearDown(() async {
    t.container.dispose();
    await t.db.close();
  });

  group('SyncPipeline', () {
    test('success posts once, stores history, audit and lastSync', () async {
      final r = await t.container.read(syncPipelineProvider).runSync(
          from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      expect(r.status, SyncStatus.success, reason: r.message);
      expect(r.qboJournalEntryId, '101');
      expect(qboCalls, 1);
      final h = (await t.container.read(historyRepositoryProvider).recent()).single;
      expect(h.status, 'Success');
      expect(h.totalDebit, 100);
      expect(h.totalCredit, 100);
      expect(h.requestJson, contains('"TxnDate": "2026-11-03"'));
      expect(h.responseJson, contains('101'));
      final audit = await t.container.read(auditRepositoryProvider).recent();
      expect(audit.first.action, AuditActions.manualSuccess);
      expect((await t.container.read(connectionRepositoryProvider).current())!.lastSyncAt, now);
      final je = adapter.requests.firstWhere((r) => r.uri.path.endsWith('journalentry'));
      expect(je.queryParameters['requestid'], isNotEmpty);
    });

    test('overlapping prior success is Skipped without calling QBO', () async {
      final p = t.container.read(syncPipelineProvider);
      await p.runSync(from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      final r = await p.runSync(from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      expect(r.status, SyncStatus.skipped);
      expect(r.message, contains('Omitida'));
      expect(qboCalls, 1);
      expect((await t.container.read(auditRepositoryProvider).recent()).first.action, AuditActions.manualSkipped);
    });

    test('allowDuplicate forces a new entry with a different requestid', () async {
      final p = t.container.read(syncPipelineProvider);
      await p.runSync(from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      final r = await p.runSync(
          from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana', allowDuplicate: true);
      expect(r.status, SyncStatus.success);
      final ids = adapter.requests.where((r) => r.uri.path.endsWith('journalentry')).map((r) => r.queryParameters['requestid']).toList();
      expect(ids, hasLength(2));
      expect(ids[0], isNot(ids[1]));
    });

    test('scheduled runs never override duplicates', () async {
      final p = t.container.read(syncPipelineProvider);
      await p.runSync(from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      final r = await p.runSync(
          from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.scheduled, user: 'x', allowDuplicate: true);
      expect(r.status, SyncStatus.skipped);
      expect(qboCalls, 1);
    });

    test('unbalanced fails with Spanish message and no QBO call', () async {
      posRows = [posDay(cash: 55)];
      final r = await t.container.read(syncPipelineProvider).runSync(
          from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      expect(r.status, SyncStatus.failed);
      expect(r.message, contains('no está balanceado'));
      expect(qboCalls, 0);
      expect((await t.container.read(auditRepositoryProvider).recent()).first.action, AuditActions.manualFailed);
    });

    test('no sales data fails', () async {
      posRows = [];
      final r = await t.container.read(syncPipelineProvider).runSync(
          from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      expect(r.status, SyncStatus.failed);
      expect(r.message, contains('No hay datos de ventas'));
    });

    test('missing mapping fails', () async {
      await t.container.read(mappingRepositoryProvider).deleteCategory(PosCategories.efectivo);
      final r = await t.container.read(syncPipelineProvider).runSync(
          from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 3), trigger: SyncTrigger.manual, user: 'ana');
      expect(r.status, SyncStatus.failed);
      expect(r.message, contains('Efectivo'));
    });
  });

  group('Scheduler', () {
    test('catches up a missed run, uses scheduled trigger, recomputes next', () async {
      final repo = t.container.read(scheduleRepositoryProvider);
      await repo.save(const ScheduleModel(enabled: true, frequency: ScheduleFrequency.daily, timeOfDay: TimeOfDayHm(23, 0)),
          now: DateTime(2026, 11, 1, 10)); // next = Nov 1 23:00 – missed while PC was off
      final calls = <(DateTime, DateTime, SyncTrigger, bool)>[];
      final s = SchedulerService(
        schedules: repo,
        clock: () => now,
        runSync: ({required from, required to, required trigger, required user, allowDuplicate = false}) async {
          calls.add((from, to, trigger, allowDuplicate));
          return const SyncResult(status: SyncStatus.success, historyId: 1, message: 'ok');
        },
      );
      final wait = await s.tick();
      expect(calls, hasLength(1));
      expect(calls.single.$1, DateTime(2026, 11, 3));
      expect(calls.single.$3, SyncTrigger.scheduled);
      expect(calls.single.$4, isFalse);
      final saved = (await repo.single())!;
      expect(saved.lastRunAt, now);
      expect(saved.nextRunAt, DateTime(2026, 11, 3, 23));
      expect(wait, SchedulerService.maxPoll); // 11h away → capped at 1h

      // Not due → nothing runs.
      await s.tick();
      expect(calls, hasLength(1));
    });

    test('wait shrinks when next run is near, min 1 minute', () async {
      final repo = t.container.read(scheduleRepositoryProvider);
      now = DateTime(2026, 11, 3, 22, 30);
      await repo.save(const ScheduleModel(enabled: true, frequency: ScheduleFrequency.daily, timeOfDay: TimeOfDayHm(23, 0)), now: now);
      final s = SchedulerService(
          schedules: repo, clock: () => now, runSync: ({required from, required to, required trigger, required user, allowDuplicate = false}) async => throw UnimplementedError());
      expect(await s.tick(), const Duration(minutes: 30));
    });
  });

  group('Auth', () {
    test('seed admin forces password change; change clears flag', () async {
      final auth = t.container.read(authServiceProvider);
      final temp = await auth.ensureSeedAdmin(writeFile: false);
      expect(temp, isNotNull);
      expect(await auth.ensureSeedAdmin(writeFile: false), isNull);
      final u = await auth.login('ADMIN', temp!);
      expect(u.mustChangePassword, isTrue);
      expect(() => auth.changePassword(u, temp, 'short'), throwsA(isA<AuthException>()));
      final changed = await auth.changePassword(u, temp, 'NuevaClave2026');
      expect(changed.mustChangePassword, isFalse);
      expect(() => auth.login('admin', '1234'), throwsA(isA<AuthException>()));
    });

    test('lockout after 5 failures for 15 minutes', () async {
      final auth = t.container.read(authServiceProvider);
      final temp = (await auth.ensureSeedAdmin(writeFile: false))!;
      for (var i = 0; i < 4; i++) {
        await expectLater(auth.login('admin', 'bad'), throwsA(isA<AuthException>()));
      }
      await expectLater(
          auth.login('admin', 'bad'), throwsA(isA<AuthException>().having((e) => e.message, 'm', contains('bloqueada'))));
      await expectLater(
          auth.login('admin', temp), throwsA(isA<AuthException>().having((e) => e.message, 'm', contains('bloqueada'))));
      now = now.add(const Duration(minutes: 16));
      expect((await auth.login('admin', temp)).username, 'admin');
    });

    test('cannot deactivate or demote the last admin; remembered session', () async {
      final auth = t.container.read(authServiceProvider);
      final temp = (await auth.ensureSeedAdmin(writeFile: false))!;
      final admin = await auth.login('admin', temp, remember: true);
      final other = await auth.createUser(by: admin, username: 'cajero', displayName: 'Cajero', password: 'Cajero2026');
      expect(() => auth.setActive(by: admin, userId: admin.id, active: false), throwsA(isA<AuthException>()));
      expect(() => auth.setAdmin(by: admin, userId: admin.id, isAdmin: false), throwsA(isA<AuthException>()));
      await auth.setAdmin(by: admin, userId: other.id, isAdmin: true);
      final otherAdmin = (await auth.allUsers()).firstWhere((u) => u.username == 'cajero');
      await auth.setActive(by: otherAdmin, userId: admin.id, active: false); // now allowed: 2 admins
      expect(() => auth.setActive(by: otherAdmin, userId: otherAdmin.id, active: false), throwsA(isA<AuthException>()));
      expect(() => auth.createUser(by: other, username: 'x', displayName: 'x', password: 'Abcdefg1'), throwsA(isA<AuthException>()));

      // Session restore respects deactivation + 30 day expiry.
      expect(await auth.restoreSession(), isNull); // admin deactivated
      await auth.setActive(by: otherAdmin, userId: admin.id, active: true);
      expect((await auth.restoreSession())?.username, 'admin');
      now = now.add(const Duration(days: 31));
      expect(await auth.restoreSession(), isNull);
    });

    test('password hasher verifies and rejects', () async {
      final h = PasswordHasher(iterations: 1000);
      final s = await h.hash('Clave1234');
      expect(s, startsWith(r'pbkdf2$1000$'));
      expect(await h.verify('Clave1234', s), isTrue);
      expect(await h.verify('clave1234', s), isFalse);
    });
  });

  test('dio adapter is shared (sanity)', () {
    expect(t.container.read(posDioProvider), isA<Dio>());
  });
}
