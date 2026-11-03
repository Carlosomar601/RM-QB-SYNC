import 'dart:convert';

import '../../core/exceptions.dart';

abstract final class QboConstants {
  static const sandboxApiBase = 'https://sandbox-quickbooks.api.intuit.com';
  static const productionApiBase = 'https://quickbooks.api.intuit.com';
  static const authorizeUrl = 'https://appcenter.intuit.com/connect/oauth2';
  static const tokenUrl = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';
  static const revokeUrl = 'https://developer.api.intuit.com/v2/oauth2/tokens/revoke';
  static const scope = 'com.intuit.quickbooks.accounting';
  static const minorVersion = '75';

  /// Must match the redirect URI registered with Intuit (same as the legacy app).
  static const redirectUri = 'http://localhost:5177/oauth/callback';
  static const loopbackPort = 5177;
  static const callbackPath = '/oauth/callback';

  static const pageSize = 1000;

  static String apiBase(String environment) =>
      environment.toLowerCase() == 'production' ? productionApiBase : sandboxApiBase;
}

class QboTokens {
  const QboTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  factory QboTokens.fromTokenResponse(Map<String, dynamic> j, DateTime now) {
    final access = j['access_token'] as String?;
    final refresh = j['refresh_token'] as String?;
    if (access == null || refresh == null) {
      throw QboApiException('Respuesta de token de Intuit incompleta.');
    }
    final expiresIn = (j['expires_in'] as num?)?.toInt() ?? 3600;
    final refreshIn = (j['x_refresh_token_expires_in'] as num?)?.toInt() ?? 8726400;
    return QboTokens(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: now.add(Duration(seconds: expiresIn)),
      refreshExpiresAt: now.add(Duration(seconds: refreshIn)),
    );
  }
}

class QboAccount {
  const QboAccount({required this.id, required this.name, this.fullyQualifiedName, this.accountType, this.acctNum});

  final String id;
  final String name;
  final String? fullyQualifiedName;
  final String? accountType;
  final String? acctNum;

  String get displayName {
    final n = fullyQualifiedName ?? name;
    return (acctNum ?? '').isEmpty ? n : '$acctNum · $n';
  }

  factory QboAccount.fromJson(Map<String, dynamic> j) => QboAccount(
        id: j['Id'].toString(),
        name: (j['Name'] ?? '').toString(),
        fullyQualifiedName: j['FullyQualifiedName']?.toString(),
        accountType: j['AccountType']?.toString(),
        acctNum: j['AcctNum']?.toString(),
      );
}

class QboEntity {
  const QboEntity({required this.id, required this.displayName});
  final String id;
  final String displayName;

  factory QboEntity.fromJson(Map<String, dynamic> j) => QboEntity(
        id: j['Id'].toString(),
        displayName: (j['DisplayName'] ?? j['FullyQualifiedName'] ?? j['CompanyName'] ?? '').toString(),
      );
}

class QboJournalEntryResult {
  const QboJournalEntryResult({required this.id, required this.requestJson, required this.responseJson});
  final String id;
  final String requestJson;
  final String responseJson;
}

/// Parses QuickBooks error payloads into a Spanish [QboApiException].
abstract final class QboFaultParser {
  static QboApiException parse(int? statusCode, Object? body) {
    Map<String, dynamic>? j;
    if (body is Map) {
      j = body.cast<String, dynamic>();
    } else if (body is String && body.trim().startsWith('{')) {
      try {
        j = (jsonDecode(body) as Map).cast<String, dynamic>();
      } catch (_) {}
    }

    final details = <String>[];
    final fault = (j?['Fault'] ?? j?['fault']) as Map?;
    if (fault != null) {
      final errors = (fault['Error'] ?? fault['error']) as List? ?? const [];
      for (final e in errors.whereType<Map>()) {
        final msg = (e['Message'] ?? e['message'] ?? '').toString();
        final detail = (e['Detail'] ?? e['detail'] ?? '').toString();
        final code = (e['code'] ?? '').toString();
        details.add([
          if (msg.isNotEmpty) msg,
          if (detail.isNotEmpty && detail != msg) detail,
          if (code.isNotEmpty) '(código $code)',
        ].join(' – '));
      }
    } else if (j?['error'] != null) {
      details.add([j!['error'], j['error_description']].whereType<Object>().join(': '));
    }

    final prefix = switch (statusCode) {
      400 => 'QuickBooks rechazó la solicitud',
      401 => 'La sesión con QuickBooks expiró o no es válida. Reconecte en Configuración',
      403 => 'QuickBooks negó el acceso (permisos o suscripción)',
      404 => 'Recurso no encontrado en QuickBooks',
      429 => 'QuickBooks limitó la cantidad de solicitudes; intente en unos minutos',
      final int s when s >= 500 => 'QuickBooks no está disponible en este momento (HTTP $s)',
      _ => 'Error de QuickBooks${statusCode == null ? '' : ' (HTTP $statusCode)'}',
    };
    return QboApiException(details.isEmpty ? '$prefix.' : '$prefix: ${details.first}',
        statusCode: statusCode, details: details.length > 1 ? details.sublist(1) : const []);
  }
}
