import 'dart:io' show InternetAddress, InternetAddressType;

/// Kind of host entered by the user.
enum HostKind { ipv4, ipv6, hostname }

/// User-editable POS API address. Pure value type.
class PosAddress {
  const PosAddress({
    this.protocol = 'http',
    required this.host,
    required this.port,
    this.basePath = '',
    this.timeoutSeconds,
  });

  final String protocol;
  final String host;
  final int port;
  final String basePath;

  /// Optional receive timeout override (seconds).
  final int? timeoutSeconds;

  bool get isConfigured => host.trim().isNotEmpty;

  /// Composed base URL, e.g. `http://192.168.100.175:8180` or `http://[fe80::1]:8180/api`.
  String get baseUrl {
    final h = host.trim();
    final hostPart = PosAddressValidator.hostKind(h) == HostKind.ipv6 ? '[$h]' : h;
    final path = PosAddressValidator.normalizeBasePath(basePath);
    return '$protocol://$hostPart:$port$path';
  }

  /// Short form for history chips: `host:port`.
  String get shortLabel => '$host:$port';

  Map<String, Object?> toJson() => {
        'protocol': protocol,
        'host': host,
        'port': port,
        'basePath': basePath,
        if (timeoutSeconds != null) 'timeoutSeconds': timeoutSeconds,
      };

  static PosAddress fromJson(Map<String, Object?> j) => PosAddress(
        protocol: (j['protocol'] as String?) ?? 'http',
        host: (j['host'] as String?) ?? '',
        port: (j['port'] as num?)?.toInt() ?? 8180,
        basePath: (j['basePath'] as String?) ?? '',
        timeoutSeconds: (j['timeoutSeconds'] as num?)?.toInt(),
      );

  PosAddress copyWith({
    String? protocol,
    String? host,
    int? port,
    String? basePath,
    int? Function()? timeoutSeconds,
  }) =>
      PosAddress(
        protocol: protocol ?? this.protocol,
        host: host ?? this.host,
        port: port ?? this.port,
        basePath: basePath ?? this.basePath,
        timeoutSeconds: timeoutSeconds != null ? timeoutSeconds() : this.timeoutSeconds,
      );

  @override
  bool operator ==(Object other) =>
      other is PosAddress &&
      other.protocol == protocol &&
      other.host == host &&
      other.port == port &&
      PosAddressValidator.normalizeBasePath(other.basePath) ==
          PosAddressValidator.normalizeBasePath(basePath) &&
      other.timeoutSeconds == timeoutSeconds;

  @override
  int get hashCode => Object.hash(protocol, host, port, PosAddressValidator.normalizeBasePath(basePath), timeoutSeconds);

  @override
  String toString() => baseUrl;
}

/// Validation helpers. Each `validateX` returns a Spanish error or null.
abstract final class PosAddressValidator {
  static final RegExp _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
  static final RegExp _hostnameLabel = RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$');

  static bool isIPv4(String s) {
    final m = _ipv4.firstMatch(s);
    if (m == null) return false;
    for (var i = 1; i <= 4; i++) {
      final part = m.group(i)!;
      if (part.length > 1 && part.startsWith('0')) return false;
      if (int.parse(part) > 255) return false;
    }
    return true;
  }

  static bool isIPv6(String s) {
    if (!s.contains(':')) return false;
    final addr = InternetAddress.tryParse(s.split('%').first);
    return addr != null && addr.type == InternetAddressType.IPv6;
  }

  static bool isHostname(String s) {
    if (s.isEmpty || s.length > 253) return false;
    final labels = s.endsWith('.') ? s.substring(0, s.length - 1).split('.') : s.split('.');
    if (labels.any((l) => !_hostnameLabel.hasMatch(l))) return false;
    // All-numeric dotted strings must be valid IPv4, not hostnames.
    if (labels.every((l) => RegExp(r'^\d+$').hasMatch(l))) return false;
    return true;
  }

  static HostKind? hostKind(String s) {
    final h = s.trim();
    if (isIPv4(h)) return HostKind.ipv4;
    if (isIPv6(h)) return HostKind.ipv6;
    if (isHostname(h)) return HostKind.hostname;
    return null;
  }

  static String? validateHost(String? value) {
    var h = (value ?? '').trim();
    if (h.isEmpty) return 'Indique la dirección IP o el nombre del equipo del POS.';
    if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
    if (h.contains('://') || h.contains('/')) {
      return 'Escriba solo la IP o el nombre (sin http:// ni rutas). Ej.: 192.168.100.175';
    }
    if (hostKind(h) == null) {
      return 'Dirección no válida. Use una IPv4 (192.168.1.10), IPv6 (fe80::1) o un nombre de equipo.';
    }
    return null;
  }

  static String? validatePort(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Indique el puerto (ej.: 8180).';
    final p = int.tryParse(v);
    if (p == null || p < 1 || p > 65535) return 'El puerto debe ser un número entre 1 y 65535.';
    return null;
  }

  static String? validateProtocol(String? value) =>
      (value == 'http' || value == 'https') ? null : 'Seleccione http o https.';

  static String? validateBasePath(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (v.contains('?') || v.contains('#') || v.contains(' ') || v.contains('://')) {
      return 'La ruta base solo puede contener segmentos, ej.: /api';
    }
    return null;
  }

  static String? validateTimeout(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final t = int.tryParse(v);
    if (t == null || t < 5 || t > 600) return 'El tiempo de espera debe estar entre 5 y 600 segundos.';
    return null;
  }

  /// `api/` → `/api`, `/` → ``.
  static String normalizeBasePath(String path) {
    var p = path.trim();
    if (p.isEmpty || p == '/') return '';
    if (!p.startsWith('/')) p = '/$p';
    while (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  /// True when the host is loopback, link-local, a private LAN range,
  /// or a bare/`.local`/`.lan` hostname. Public addresses return false.
  static bool isPrivateLan(String host) {
    var h = host.trim().toLowerCase();
    if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
    if (isIPv4(h)) {
      final o = h.split('.').map(int.parse).toList();
      if (o[0] == 10) return true;
      if (o[0] == 127) return true;
      if (o[0] == 172 && o[1] >= 16 && o[1] <= 31) return true;
      if (o[0] == 192 && o[1] == 168) return true;
      if (o[0] == 169 && o[1] == 254) return true;
      return false;
    }
    if (isIPv6(h)) {
      final addr = InternetAddress.tryParse(h.split('%').first)!;
      final b = addr.rawAddress;
      if (addr.isLoopback) return true;
      if ((b[0] & 0xfe) == 0xfc) return true; // fc00::/7
      if (b[0] == 0xfe && (b[1] & 0xc0) == 0x80) return true; // fe80::/10
      return false;
    }
    if (h == 'localhost') return true;
    if (!h.contains('.')) return true; // NetBIOS-style machine name
    return h.endsWith('.local') || h.endsWith('.lan') || h.endsWith('.home') || h.endsWith('.internal');
  }
}
