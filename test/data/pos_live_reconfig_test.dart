import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/providers.dart';
import 'package:rmqbsync/core/exceptions.dart';
import 'package:rmqbsync/core/pos_address.dart';
import 'package:rmqbsync/data/pos/pos_client.dart';
import 'package:rmqbsync/data/pos/pos_providers.dart';
import 'package:rmqbsync/data/secrets/secret_store.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_container.dart';

void main() {
  test('unconfigured until saved, then reconfigures live without restart', () async {
    final adapter = FakeAdapter((o) async => const FakeResponse(200, []));
    final t = makeContainer(adapter: adapter);
    final c = t.container;
    addTearDown(() async {
      c.dispose();
      await t.db.close();
    });

    await c.read(posConfigProvider.future);
    expect(c.read(posClientProvider), isA<UnconfiguredPosClient>());
    await expectLater(
      c.read(posClientProvider).getSalesSummary(DateTime(2026, 1, 1), DateTime(2026, 1, 1)),
      throwsA(isA<PosNotConfiguredException>()),
    );

    // Save first address.
    await c.read(posConfigProvider.notifier).save(
          address: const PosAddress(host: '192.168.100.175', port: 8180),
          username: 'admin',
        );
    expect(c.read(posDioProvider)!.options.baseUrl, 'http://192.168.100.175:8180');
    await c.read(posClientProvider).testConnection();
    expect(adapter.requests.last.uri.toString(), startsWith('http://192.168.100.175:8180/cse.api.v1/SalesByMethod'));

    // Change IP/port + API key: next request goes to the new address.
    await c.read(posConfigProvider.notifier).save(
          address: const PosAddress(host: '10.0.0.5', port: 9000, basePath: 'rm', timeoutSeconds: 90),
          username: 'admin',
          apiKeyHeader: 'X-Api-Key',
          apiKeyValue: 's3cr3t',
        );
    final dio = c.read(posDioProvider)!;
    expect(dio.options.baseUrl, 'http://10.0.0.5:9000/rm');
    expect(dio.options.receiveTimeout, const Duration(seconds: 90));
    await c.read(posClientProvider).testConnection();
    final last = adapter.requests.last;
    expect(last.uri.toString(), startsWith('http://10.0.0.5:9000/rm/cse.api.v1/SalesByMethod'));
    expect(last.headers['X-Api-Key'], 's3cr3t');
    expect(t.secrets.values[SecretKeys.posApiKeyValue], 's3cr3t');

    // History + audit.
    final cfg = await c.read(posConfigProvider.future);
    expect(cfg.history.map((h) => h.host), ['10.0.0.5', '192.168.100.175']);
    final audit = await c.read(auditRepositoryProvider).recent();
    expect(audit.where((a) => a.action == 'ConfiguracionApiPosActualizada'), hasLength(2));
    expect(audit.first.details, contains('http://192.168.100.175:8180'));
    expect(audit.first.details, contains('http://10.0.0.5:9000/rm'));
    expect(audit.first.details, isNot(contains('s3cr3t')));
  });

  test('history keeps the last 5 distinct addresses', () async {
    final t = makeContainer();
    addTearDown(() async {
      t.container.dispose();
      await t.db.close();
    });
    final s = t.container.read(settingsRepositoryProvider);
    for (var i = 1; i <= 7; i++) {
      await s.pushPosHistory(PosAddress(host: '10.0.0.$i', port: 8180));
    }
    await s.pushPosHistory(const PosAddress(host: '10.0.0.5', port: 8180));
    final h = await s.getPosHistory();
    expect(h.map((e) => e.host), ['10.0.0.5', '10.0.0.7', '10.0.0.6', '10.0.0.4', '10.0.0.3']);
  });
}
