import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class SecretKeys {
  static const qboClientId = 'qbo.clientId';
  static const qboClientSecret = 'qbo.clientSecret';
  static const qboAccessToken = 'qbo.accessToken';
  static const qboRefreshToken = 'qbo.refreshToken';
  static const posApiKeyHeader = 'pos.apiKeyHeader';
  static const posApiKeyValue = 'pos.apiKeyValue';
  static const sessionToken = 'auth.session';
}

/// Secret storage abstraction (Windows: DPAPI/Credential Manager via
/// flutter_secure_storage). Tests use [InMemorySecretStore].
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
  Future<void> delete(String key);

  Future<bool> has(String key) async => ((await read(key)) ?? '').isNotEmpty;
}

class SecureSecretStore extends SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  static const _prefix = 'RMQBsync.';

  @override
  Future<String?> read(String key) => _s.read(key: '$_prefix$key');

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await delete(key);
    } else {
      await _s.write(key: '$_prefix$key', value: value);
    }
  }

  @override
  Future<void> delete(String key) => _s.delete(key: '$_prefix$key');
}

class InMemorySecretStore extends SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}
