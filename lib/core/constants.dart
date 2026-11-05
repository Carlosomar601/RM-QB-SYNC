/// Product identity. The visible name follows the design system v1.0; the
/// technical name RMQBsync stays for paths, exe, registry and secrets.
abstract final class AppInfo {
  static const String displayName = 'RM Ledger Sync';
}

/// Domain constants shared by the POS client, the sync pipeline and the UI.
abstract final class PosConstants {
  /// Hard cap on ARReconciliationInvoices pages to avoid infinite loops.
  static const int maxPages = 200;

  /// How far back to look for invoices whose payments land on a given day.
  static const int crossDayLookbackDays = 90;

  /// How far back to look for AR invoices whose payments fall in the range.
  static const int arCollectionLookbackDays = 90;
}

/// Category groups.
abstract final class PosGroups {
  static const String ventas = 'Ventas';
  static const String pagos = 'Pagos';
}

/// POS categories produced by the Retail Manager client.
abstract final class PosCategories {
  // Ventas
  static const String ventaNeta = 'VentaNeta';
  static const String cityTax = 'CityTax';
  static const String stateTax = 'StateTax';
  static const String pagosAFacturasPendientes = 'PagosAFacturasPendientes';

  // Pagos
  static const String efectivo = 'Efectivo';
  static const String tarjetaCredito = 'TarjetaCredito';
  static const String tarjetaDebito = 'TarjetaDebito';
  static const String cheques = 'Cheques';
  static const String athMovil = 'AthMovil';
  static const String pendienteDeCobro = 'PendienteDeCobro';

  static const List<String> ventas = [
    ventaNeta,
    cityTax,
    stateTax,
    pagosAFacturasPendientes,
  ];

  static const List<String> pagos = [
    efectivo,
    tarjetaCredito,
    tarjetaDebito,
    cheques,
    athMovil,
    pendienteDeCobro,
  ];

  static const List<String> all = [...ventas, ...pagos];

  /// Spanish display labels for the known categories.
  static const Map<String, String> labels = {
    ventaNeta: 'Venta neta',
    cityTax: 'IVU municipal',
    stateTax: 'IVU estatal',
    pagosAFacturasPendientes: 'Cobros a facturas pendientes',
    efectivo: 'Efectivo',
    tarjetaCredito: 'Tarjeta de crédito',
    tarjetaDebito: 'Tarjeta de débito',
    cheques: 'Cheques',
    athMovil: 'ATH Móvil',
    pendienteDeCobro: 'Pendiente de cobro (ventas a crédito)',
  };

  static String label(String category) => labels[category] ?? category;

  /// Group a known category belongs to (null for unknown categories).
  static String? groupOf(String category) {
    if (ventas.contains(category)) return PosGroups.ventas;
    if (pagos.contains(category)) return PosGroups.pagos;
    return null;
  }
}
