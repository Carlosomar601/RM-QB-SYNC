import 'dart:convert';
import 'dart:io';

import '../data/db/repositories.dart';
import '../data/secrets/secret_store.dart';
import 'app_logger.dart';

/// Copies the optional bundled `factory-secrets.json` (Intuit client
/// credentials) into secure storage on first run and deletes the plaintext.
///
/// File format (same keys as the legacy app):
/// ```json
/// { "QuickBooksOnline:ClientId": "...", "QuickBooksOnline:ClientSecret": "...",
///   "QuickBooksOnline:Environment": "production" }
/// ```
class FactorySecretsSeeder {
  FactorySecretsSeeder(this.secrets, this.settings);
  final SecretStore secrets;
  final SettingsRepository settings;

  /// Returns true if secrets were seeded.
  Future<bool> seedIfNeeded(File file) async {
    if (!file.existsSync()) return false;
    try {
      final alreadyHas = await secrets.has(SecretKeys.qboClientId) && await secrets.has(SecretKeys.qboClientSecret);
      if (!alreadyHas) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        String? pick(String k) {
          final v = json['QuickBooksOnline:$k'] ?? (json['QuickBooksOnline'] as Map?)?[k];
          return v?.toString().trim();
        }

        final id = pick('ClientId');
        final secret = pick('ClientSecret');
        final env = pick('Environment')?.toLowerCase();
        if ((id ?? '').isNotEmpty && (secret ?? '').isNotEmpty) {
          await secrets.write(SecretKeys.qboClientId, id);
          await secrets.write(SecretKeys.qboClientSecret, secret);
          if (env == 'production' || env == 'sandbox') await settings.setQboEnvironment(env!);
          AppLogger.info('Credenciales de fábrica de QuickBooks importadas.');
        }
      }
      return !alreadyHas;
    } catch (e) {
      AppLogger.warning('No se pudo leer factory-secrets.json: $e');
      return false;
    } finally {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        AppLogger.warning('No se pudo borrar factory-secrets.json: $e');
      }
    }
  }
}
