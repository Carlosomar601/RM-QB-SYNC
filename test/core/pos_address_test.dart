import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/core/pos_address.dart';

void main() {
  group('host validation', () {
    for (final ok in ['192.168.100.175', '10.0.0.1', 'fe80::1', '::1', '2001:db8::5', 'pos-server', 'pos.tienda.local']) {
      test('accepts $ok', () => expect(PosAddressValidator.validateHost(ok), isNull));
    }
    for (final bad in ['', '256.1.1.1', '192.168.1', '192.168.01.1', 'http://192.168.1.1', '192.168.1.1/api', 'bad_host!', '-pos']) {
      test('rejects "$bad"', () => expect(PosAddressValidator.validateHost(bad), isNotNull));
    }
    test('bracketed IPv6 accepted', () => expect(PosAddressValidator.validateHost('[fe80::1]'), isNull));
  });

  group('port', () {
    test('range 1..65535', () {
      expect(PosAddressValidator.validatePort('8180'), isNull);
      expect(PosAddressValidator.validatePort('1'), isNull);
      expect(PosAddressValidator.validatePort('65535'), isNull);
      expect(PosAddressValidator.validatePort('0'), isNotNull);
      expect(PosAddressValidator.validatePort('65536'), isNotNull);
      expect(PosAddressValidator.validatePort('abc'), isNotNull);
      expect(PosAddressValidator.validatePort(''), isNotNull);
    });
  });

  group('baseUrl composition', () {
    test('ipv4 no path', () {
      expect(const PosAddress(host: '192.168.100.175', port: 8180).baseUrl, 'http://192.168.100.175:8180');
    });
    test('ipv6 bracketed, https, normalized base path', () {
      expect(const PosAddress(protocol: 'https', host: 'fe80::1', port: 443, basePath: 'api/').baseUrl,
          'https://[fe80::1]:443/api');
    });
    test('json round trip', () {
      const a = PosAddress(host: 'pos', port: 9000, basePath: '/x', timeoutSeconds: 30);
      expect(PosAddress.fromJson(a.toJson()), a);
    });
  });

  group('private LAN detection', () {
    test('private', () {
      for (final h in ['10.1.2.3', '172.16.0.1', '172.31.255.255', '192.168.100.175', '127.0.0.1', '169.254.1.1', '::1', 'fe80::1', 'fd00::1', 'localhost', 'POS01', 'pos.local']) {
        expect(PosAddressValidator.isPrivateLan(h), isTrue, reason: h);
      }
    });
    test('public', () {
      for (final h in ['8.8.8.8', '172.32.0.1', '2001:4860::8888', 'api.example.com']) {
        expect(PosAddressValidator.isPrivateLan(h), isFalse, reason: h);
      }
    });
  });

  test('money/basepath validators', () {
    expect(PosAddressValidator.validateBasePath('/api'), isNull);
    expect(PosAddressValidator.validateBasePath('/api?x=1'), isNotNull);
    expect(PosAddressValidator.validateTimeout('60'), isNull);
    expect(PosAddressValidator.validateTimeout('2'), isNotNull);
  });
}
