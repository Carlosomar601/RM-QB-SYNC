import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/providers.dart';
import 'package:rmqbsync/core/account_mapping.dart';
import 'package:rmqbsync/core/exceptions.dart';
import 'package:rmqbsync/core/journal_entry.dart';
import 'package:rmqbsync/data/quickbooks/journal_entry_qbo_mapper.dart';
import 'package:rmqbsync/data/quickbooks/qbo_models.dart';
import 'package:rmqbsync/data/quickbooks/qbo_oauth_service.dart';
import 'package:rmqbsync/data/quickbooks/qbo_providers.dart';
import 'package:rmqbsync/data/secrets/secret_store.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_container.dart';

JournalEntryDraft sampleDraft() => JournalEntryDraft(
      txnDate: DateTime(2026, 5, 21),
      description: 'Ventas del 01/05/2026 al 21/05/2026',
      lines: const [
        JournalEntryLine(
            category: 'Efectivo', accountId: '35', accountName: 'Caja', side: PostingSide.debit, amount: 100.5, description: 'Efectivo'),
        JournalEntryLine(
            category: 'PendienteDeCobro',
            accountId: '84',
            accountName: 'Cuentas a cobrar',
            side: PostingSide.debit,
            amount: 20,
            description: 'Ventas a crédito',
            entityType: EntityType.customer,
            entityId: '1',
            entityName: 'Cliente Generico'),
        JournalEntryLine(
            category: 'VentaNeta', accountId: '79', accountName: 'Ventas', side: PostingSide.credit, amount: 120.5, description: 'VentaNeta'),
      ],
    );

void main() {
  test('mapper produces the exact QBO JSON (Entity omitted when none)', () {
    final json = JournalEntryQboMapper.toQbo(sampleDraft());
    expect(jsonEncode(json), jsonEncode({
      'TxnDate': '2026-05-21',
      'PrivateNote': 'Ventas del 01/05/2026 al 21/05/2026',
      'Line': [
        {
          'Id': '0',
          'Description': 'Efectivo',
          'Amount': 100.5,
          'DetailType': 'JournalEntryLineDetail',
          'JournalEntryLineDetail': {
            'PostingType': 'Debit',
            'AccountRef': {'value': '35', 'name': 'Caja'},
          },
        },
        {
          'Id': '1',
          'Description': 'Ventas a crédito',
          'Amount': 20.0,
          'DetailType': 'JournalEntryLineDetail',
          'JournalEntryLineDetail': {
            'PostingType': 'Debit',
            'AccountRef': {'value': '84', 'name': 'Cuentas a cobrar'},
            'Entity': {
              'Type': 'Customer',
              'EntityRef': {'value': '1', 'name': 'Cliente Generico'},
            },
          },
        },
        {
          'Id': '2',
          'Description': 'VentaNeta',
          'Amount': 120.5,
          'DetailType': 'JournalEntryLineDetail',
          'JournalEntryLineDetail': {
            'PostingType': 'Credit',
            'AccountRef': {'value': '79', 'name': 'Ventas'},
          },
        },
      ],
    }));
  });

  test('requestId is stable, changes with content and salt', () {
    final a = JournalEntryQboMapper.requestId(DateTime(2026, 5, 1), DateTime(2026, 5, 21), sampleDraft());
    final b = JournalEntryQboMapper.requestId(DateTime(2026, 5, 1), DateTime(2026, 5, 21), sampleDraft());
    final c = JournalEntryQboMapper.requestId(DateTime(2026, 5, 2), DateTime(2026, 5, 21), sampleDraft());
    final d = JournalEntryQboMapper.requestId(DateTime(2026, 5, 1), DateTime(2026, 5, 21), sampleDraft(), salt: '42');
    expect(a, b);
    expect(a, isNot(c));
    expect(a, isNot(d));
    expect(a.length, 36);
  });

  test('fault parser extracts Message/Detail', () {
    final e = QboFaultParser.parse(400, {
      'Fault': {
        'Error': [
          {'Message': 'Business Validation Error', 'Detail': 'Transaction must be balanced', 'code': '6000'},
          {'Message': 'Otro', 'Detail': 'Segundo'},
        ],
        'type': 'ValidationFault',
      }
    });
    expect(e.statusCode, 400);
    expect(e.message, contains('Business Validation Error'));
    expect(e.message, contains('Transaction must be balanced'));
    expect(e.details.single, contains('Segundo'));
    expect(QboFaultParser.parse(401, '{"error":"invalid_grant"}').message, contains('invalid_grant'));
    expect(QboFaultParser.parse(503, '<html>').message, contains('no está disponible'));
  });

  group('with connected container', () {
    late TestEnv t;
    late FakeAdapter adapter;
    late Future<FakeResponse> Function(RequestOptions o) route;
    final now = DateTime(2026, 11, 3, 12);
    final sleeps = <Duration>[];

    setUp(() async {
      sleeps.clear();
      adapter = FakeAdapter((o) => route(o));
      t = makeContainer(adapter: adapter, clock: () => now, overrides: [
        retrySleepProvider.overrideWithValue((d) async => sleeps.add(d)),
      ]);
      await t.secrets.write(SecretKeys.qboClientId, 'cid');
      await t.secrets.write(SecretKeys.qboClientSecret, 'csecret');
      await t.secrets.write(SecretKeys.qboAccessToken, 'AT1');
      await t.secrets.write(SecretKeys.qboRefreshToken, 'RT1');
      await t.container.read(connectionRepositoryProvider).replace(
            realmId: '9130',
            environment: 'sandbox',
            accessExpiresAt: now.add(const Duration(minutes: 30)),
            refreshExpiresAt: now.add(const Duration(days: 90)),
          );
    });
    tearDown(() async {
      t.container.dispose();
      await t.db.close();
    });

    test('queryAll pages with STARTPOSITION/MAXRESULTS 1000', () async {
      route = (o) async {
        final q = o.queryParameters['query'] as String;
        final start = int.parse(RegExp(r'STARTPOSITION (\d+)').firstMatch(q)!.group(1)!);
        final count = start == 1 ? 1000 : (start == 1001 ? 1000 : 3);
        return FakeResponse(200, {
          'QueryResponse': {
            'Account': [for (var i = 0; i < count; i++) {'Id': '${start + i}', 'Name': 'A${start + i}'}]
          }
        });
      };
      final accounts = await t.container.read(qboApiClientProvider).accounts();
      expect(accounts, hasLength(2003));
      final queries = adapter.requests.map((r) => r.queryParameters['query'] as String).toList();
      expect(queries, [
        'select * from Account where Active = true STARTPOSITION 1 MAXRESULTS 1000',
        'select * from Account where Active = true STARTPOSITION 1001 MAXRESULTS 1000',
        'select * from Account where Active = true STARTPOSITION 2001 MAXRESULTS 1000',
      ]);
      expect(adapter.requests.first.uri.toString(), startsWith('https://sandbox-quickbooks.api.intuit.com/v3/company/9130/query'));
      expect(adapter.requests.first.headers['Authorization'], 'Bearer AT1');
      expect(adapter.requests.first.queryParameters['minorversion'], QboConstants.minorVersion);
    });

    test('retries 5xx with 2/4/8s backoff and keeps requestid', () async {
      var calls = 0;
      route = (o) async {
        calls++;
        if (calls < 4) return const FakeResponse(503, {'Fault': {'Error': [{'Message': 'down'}]}});
        return const FakeResponse(200, {'JournalEntry': {'Id': '777'}});
      };
      final r = await t.container.read(qboApiClientProvider).createJournalEntry(sampleDraft(), requestId: 'rid-1');
      expect(r.id, '777');
      expect(calls, 4);
      expect(sleeps, const [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)]);
      expect(adapter.requests.map((x) => x.queryParameters['requestid']).toSet(), {'rid-1'});
      expect(jsonDecode(adapter.bodies.last)['TxnDate'], '2026-05-21');
    });

    test('gives up after 3 retries with parsed fault', () async {
      route = (o) async => const FakeResponse(500, {'Fault': {'Error': [{'Message': 'Server', 'Detail': 'boom'}]}});
      await expectLater(
        t.container.read(qboApiClientProvider).createJournalEntry(sampleDraft(), requestId: 'x'),
        throwsA(isA<QboApiException>().having((e) => e.message, 'msg', contains('boom'))),
      );
      expect(adapter.requests, hasLength(4));
    });

    test('400 is not retried', () async {
      route = (o) async => const FakeResponse(400, {'Fault': {'Error': [{'Message': 'Bad'}]}});
      await expectLater(t.container.read(qboApiClientProvider).createJournalEntry(sampleDraft(), requestId: 'x'),
          throwsA(isA<QboApiException>()));
      expect(adapter.requests, hasLength(1));
    });

    test('refreshes just-in-time and always stores rotated refresh token', () async {
      await t.container.read(connectionRepositoryProvider).updateTokens(
          accessExpiresAt: now.add(const Duration(minutes: 3)), refreshExpiresAt: now.add(const Duration(days: 50)));
      route = (o) async {
        if (o.uri.toString() == QboConstants.tokenUrl) {
          return const FakeResponse(200, {
            'access_token': 'AT2',
            'refresh_token': 'RT2',
            'expires_in': 3600,
            'x_refresh_token_expires_in': 8726400,
          });
        }
        return const FakeResponse(200, {'CompanyInfo': {'CompanyName': 'Tienda Demo'}});
      };
      final name = await t.container.read(qboApiClientProvider).companyName();
      expect(name, 'Tienda Demo');
      final tokenReq = adapter.requests.firstWhere((r) => r.uri.toString() == QboConstants.tokenUrl);
      expect(tokenReq.headers['Authorization'], 'Basic ${base64Encode(utf8.encode('cid:csecret'))}');
      expect(adapter.bodies[adapter.requests.indexOf(tokenReq)], 'grant_type=refresh_token&refresh_token=RT1');
      expect(t.secrets.values[SecretKeys.qboRefreshToken], 'RT2');
      expect(t.secrets.values[SecretKeys.qboAccessToken], 'AT2');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer AT2');
      final conn = await t.container.read(connectionRepositoryProvider).current();
      expect(conn!.accessTokenExpiresAt, now.add(const Duration(hours: 1)));
    });

    test('OAuth callback validates per-attempt state and exchanges code', () async {
      route = (o) async {
        if (o.uri.toString() == QboConstants.tokenUrl) {
          return const FakeResponse(200, {'access_token': 'NEW', 'refresh_token': 'NEWRT', 'expires_in': 3600});
        }
        return const FakeResponse(200, {'CompanyInfo': {'CompanyName': 'Mi Tienda'}});
      };
      final svc = t.container.read(qboOAuthServiceProvider);
      final s1 = QboOAuthService.newState();
      final s2 = QboOAuthService.newState();
      expect(s1, isNot(s2));
      final f1 = svc.registerAttemptForTest(s1);
      svc.registerAttemptForTest(s2).ignore();

      final bad = await svc.handleCallback(Uri.parse('/oauth/callback?code=c&state=WRONG&realmId=1'));
      expect(bad.status, 400);
      expect(svc.hasPending(s1), isTrue);

      final ok = await svc.handleCallback(Uri.parse('/oauth/callback?code=abc&state=$s1&realmId=4620'));
      expect(ok.status, 200);
      expect(ok.html, contains('Mi Tienda'));
      final r = await f1;
      expect(r.realmId, '4620');
      expect(svc.hasPending(s1), isFalse);
      expect(svc.hasPending(s2), isTrue); // other attempt untouched
      expect(t.secrets.values[SecretKeys.qboRefreshToken], 'NEWRT');
      final conn = await t.container.read(connectionRepositoryProvider).current();
      expect(conn!.realmId, '4620');
      expect(conn.companyName, 'Mi Tienda');
      final tokenBody = adapter.bodies[adapter.requests.indexWhere((r) => r.uri.toString() == QboConstants.tokenUrl)];
      expect(tokenBody, contains('grant_type=authorization_code'));
      expect(tokenBody, contains('redirect_uri=${Uri.encodeQueryComponent(QboConstants.redirectUri)}'));

      // Replay of the same state is rejected.
      expect((await svc.handleCallback(Uri.parse('/oauth/callback?code=abc&state=$s1&realmId=4620'))).status, 400);
    });

    test('authorize URL has required params', () {
      final u = t.container.read(qboOAuthServiceProvider).authorizeUrl('cid', 'st');
      expect(u.queryParameters, {
        'client_id': 'cid',
        'redirect_uri': 'http://localhost:5177/oauth/callback',
        'response_type': 'code',
        'scope': 'com.intuit.quickbooks.accounting',
        'state': 'st',
      });
    });
  });
}
