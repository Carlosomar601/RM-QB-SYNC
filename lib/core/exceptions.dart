/// Thrown when a POS category with a non-zero amount has no account mapping.
class AccountMappingNotFoundException implements Exception {
  AccountMappingNotFoundException(this.category);

  final String category;

  String get message =>
      "No hay una cuenta configurada para la categoría del POS '$category'. "
      'Configúrela en Mapeo de Cuentas.';

  @override
  String toString() => message;
}

/// Kinds of POS failures, used to give actionable Spanish messages.
enum PosErrorKind { dns, refused, timeout, http, badResponse, notConfigured, other }

/// Any failure talking to the Retail Manager POS API.
class PosApiException implements Exception {
  PosApiException(this.message, {this.kind = PosErrorKind.other, this.statusCode, this.url});

  final String message;
  final PosErrorKind kind;
  final int? statusCode;
  final String? url;

  @override
  String toString() => message;
}

/// The POS API address has not been configured yet.
class PosNotConfiguredException extends PosApiException {
  PosNotConfiguredException()
      : super(
          'La API del POS no está configurada. Vaya a Configuración → '
          'Acceso a la API del POS e indique la dirección IP y el puerto.',
          kind: PosErrorKind.notConfigured,
        );
}

/// A QuickBooks Online error (HTTP or Fault payload).
class QboApiException implements Exception {
  QboApiException(this.message, {this.statusCode, this.details = const []});

  final String message;
  final int? statusCode;
  final List<String> details;

  @override
  String toString() =>
      details.isEmpty ? message : '$message\n${details.join('\n')}';
}

/// QuickBooks is not connected (no tokens / realm).
class QboNotConnectedException extends QboApiException {
  QboNotConnectedException()
      : super('QuickBooks no está conectado. Vaya a Configuración y presione '
            '"Conectar con QuickBooks".');
}
