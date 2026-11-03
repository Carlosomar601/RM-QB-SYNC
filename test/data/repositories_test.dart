import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/providers.dart';
import 'package:rmqbsync/core/account_mapping.dart';
import 'package:rmqbsync/core/schedule.dart';
import 'package:rmqbsync/core/sync_rules.dart';
import 'package:rmqbsync/data/db/repositories.dart';
import 'package:rmqbsync/data/secrets/secret_store.dart';
import 'package:rmqbsync/services/factory_secrets_seeder.dart';
import 'package:rmqbsync/services/app_logger.dart';

import '../helpers/test_container.dart';

void main() {
  late TestEnv t;

  setUp(() => t = makeContainer());
  tearDown(() async {
    t.container.dispose();
    await t.db.close();
  });

  test('mapping upsert is unique per category and clears entity', () async {
    final repo = t.container.read(mappingRepositoryProvider);
    await repo.upsert(const AccountMapping(
        category: 'Efectivo', accountId: '1', accountName: 'Caja', side: PostingSide.debit,
        entityType: EntityType.customer, entityId: '9', entityName: 'C'));
    await repo.upsert(const AccountMapping(
        category: 'Efectivo', accountId: '2', accountName: 'Banco', side: PostingSide.debit));
    final all = await repo.all();
    expect(all, hasLength(1));
    expect(all.single.accountName, 'Banco');
    expect(all.single.entityType, isNull);
    expect(all.single.entityName, isNull);
  });

  test('history overlap query only matches Success', () async {
    final repo = t.container.read(historyRepositoryProvider);
    final a = await repo.start(trigger: SyncTrigger.manual, performedBy: 'u', from: DateTime(2026, 5, 1), to: DateTime(2026, 5, 7));
    await repo.finish(a, status: SyncStatus.failed);
    expect(await repo.findOverlappingSuccess(DateTime(2026, 5, 3), DateTime(2026, 5, 3)), isNull);
    final b = await repo.start(trigger: SyncTrigger.manual, performedBy: 'u', from: DateTime(2026, 5, 1), to: DateTime(2026, 5, 7));
    await repo.finish(b, status: SyncStatus.success, qboJournalEntryId: '55');
    final hit = await repo.findOverlappingSuccess(DateTime(2026, 5, 7), DateTime(2026, 5, 9));
    expect(hit?.id, b);
    expect(await repo.findOverlappingSuccess(DateTime(2026, 5, 8), DateTime(2026, 5, 9)), isNull);
    expect(await repo.findOverlappingSuccess(DateTime(2026, 5, 1), DateTime(2026, 5, 1), excludeId: b), isNull);
  });

  test('schedule save computes nextRunAt', () async {
    final repo = t.container.read(scheduleRepositoryProvider);
    final saved = await repo.save(
      const ScheduleModel(enabled: true, frequency: ScheduleFrequency.daily, timeOfDay: TimeOfDayHm(23, 0)),
      now: DateTime(2026, 11, 3, 10),
    );
    expect(saved.nextRunAt, DateTime(2026, 11, 3, 23));
    final disabled = await repo.save(
      const ScheduleModel(enabled: false, frequency: ScheduleFrequency.daily, timeOfDay: TimeOfDayHm(23, 0)),
    );
    expect(disabled.nextRunAt, isNull);
    expect(await repo.all(), hasLength(1));
  });

  test('factory secrets seeded once then plaintext deleted', () async {
    final dir = Directory.systemTemp.createTempSync('rmqb');
    addTearDown(() => dir.deleteSync(recursive: true));
    final f = File('${dir.path}/factory-secrets.json')
      ..writeAsStringSync('{"QuickBooksOnline:ClientId":"cid","QuickBooksOnline:ClientSecret":"csec","QuickBooksOnline:Environment":"production"}');
    final seeder = FactorySecretsSeeder(t.secrets, t.container.read(settingsRepositoryProvider));
    expect(await seeder.seedIfNeeded(f), isTrue);
    expect(f.existsSync(), isFalse);
    expect(t.secrets.values[SecretKeys.qboClientId], 'cid');
    expect(await t.container.read(settingsRepositoryProvider).getQboEnvironment(), 'production');

    f.writeAsStringSync('{"QuickBooksOnline:ClientId":"other","QuickBooksOnline:ClientSecret":"x"}');
    expect(await seeder.seedIfNeeded(f), isFalse);
    expect(t.secrets.values[SecretKeys.qboClientId], 'cid');
    expect(f.existsSync(), isFalse);
  });

  test('logger redacts secrets', () {
    expect(AppLogger.redact('Authorization: Bearer abc.def-123'), 'Authorization: Bearer ***');
    expect(AppLogger.redact('{"refresh_token":"RT123","x":1}'), '{"refresh_token":"***","x":1}');
    expect(AppLogger.redact('grant_type=authorization_code&code=XYZ&redirect_uri=a'), contains('code=***'));
  });
}
