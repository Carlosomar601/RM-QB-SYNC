import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../data/db/app_database.dart';
import '../data/db/repositories.dart';
import '../data/secrets/secret_store.dart';
import 'app_logger.dart';
import 'app_paths.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.isAdmin,
    required this.isActive,
    required this.mustChangePassword,
    this.lastLoginAt,
    this.createdAt,
  });

  final int id;
  final String username;
  final String displayName;
  final bool isAdmin;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  static AppUser fromRow(UserRow r) => AppUser(
        id: r.id,
        username: r.username,
        displayName: r.displayName,
        isAdmin: r.isAdmin,
        isActive: r.isActive,
        mustChangePassword: r.mustChangePassword,
        lastLoginAt: r.lastLoginAt,
        createdAt: r.createdAt,
      );
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// PBKDF2-HMAC-SHA256 hashes stored as `pbkdf2$<iter>$<saltB64>$<hashB64>`.
class PasswordHasher {
  PasswordHasher({this.iterations = 120000});
  final int iterations;

  Future<String> hash(String password) async {
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final h = await _derive(password, salt, iterations);
    return 'pbkdf2\$$iterations\$${base64Encode(salt)}\$${base64Encode(h)}';
  }

  Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final iter = int.tryParse(parts[1]) ?? 0;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = await _derive(password, salt, iter);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Future<List<int>> _derive(String password, List<int> salt, int iterations) async {
    final algo = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final key = await algo.deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }
}

/// Local users, lockout, remembered sessions and the first-run admin.
class AuthService {
  AuthService({
    required this.db,
    required this.secrets,
    required this.audit,
    PasswordHasher? hasher,
    DateTime Function()? clock,
  })  : hasher = hasher ?? PasswordHasher(),
        _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final SecretStore secrets;
  final AuditRepository audit;
  final PasswordHasher hasher;
  final DateTime Function() _clock;

  static const maxFailedAttempts = 5;
  static const lockoutDuration = Duration(minutes: 15);
  static const sessionDuration = Duration(days: 30);
  static const seedAdminUsername = 'admin';

  static String get firstAccessFile => p.join(AppPaths.dataDir, 'primer-acceso.txt');

  /// Returns the temporary password when the admin was just created.
  Future<String?> ensureSeedAdmin({bool writeFile = true}) async {
    final count = await db.users.count().getSingle();
    if (count > 0) return null;
    final temp = generateTemporaryPassword();
    await db.into(db.users).insert(UsersCompanion.insert(
          username: seedAdminUsername,
          passwordHash: await hasher.hash(temp),
          displayName: 'Administrador',
          isAdmin: const Value(true),
          mustChangePassword: const Value(true),
          createdAt: _clock(),
        ));
    await audit.log('Sistema', 'UsuarioAdministradorInicialCreado', 'Usuario "$seedAdminUsername" con contraseña temporal.');
    if (writeFile) {
      try {
        Directory(AppPaths.dataDir).createSync(recursive: true);
        File(firstAccessFile).writeAsStringSync(
          'RMQBsync - primer acceso\r\n\r\nUsuario: $seedAdminUsername\r\nContraseña temporal: $temp\r\n\r\n'
          'Se le pedirá cambiarla al iniciar sesión. Este archivo se borra automáticamente después del cambio.\r\n',
        );
      } catch (e) {
        AppLogger.warning('No se pudo escribir primer-acceso.txt: $e');
      }
    }
    return temp;
  }

  static String generateTemporaryPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final r = Random.secure();
    final s = List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
    return '$s${r.nextInt(10)}';
  }

  /// Minimum: 8 chars, at least one letter and one digit.
  static String? validatePasswordPolicy(String pw) {
    if (pw.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    if (!RegExp(r'[A-Za-z]').hasMatch(pw) || !RegExp(r'\d').hasMatch(pw)) {
      return 'La contraseña debe incluir letras y números.';
    }
    return null;
  }

  Future<UserRow?> _byUsername(String username) => (db.select(db.users)
        ..where((u) => u.username.lower().equals(username.trim().toLowerCase())))
      .getSingleOrNull();

  Future<UserRow> _byId(int id) => (db.select(db.users)..where((u) => u.id.equals(id))).getSingle();

  Future<AppUser> login(String username, String password, {bool remember = false}) async {
    final u = await _byUsername(username);
    final now = _clock();
    if (u == null) {
      await audit.log(username, 'InicioSesionFallido', 'Usuario no existe');
      throw AuthException('Usuario o contraseña incorrectos.');
    }
    if (u.lockedUntil != null && u.lockedUntil!.isAfter(now)) {
      final mins = u.lockedUntil!.difference(now).inMinutes + 1;
      throw AuthException('Cuenta bloqueada por intentos fallidos. Intente de nuevo en $mins minuto(s).');
    }
    if (!u.isActive) {
      throw AuthException('El usuario está desactivado. Contacte a un administrador.');
    }
    if (!await hasher.verify(password, u.passwordHash)) {
      final failed = u.failedAttempts + 1;
      final lock = failed >= maxFailedAttempts;
      await (db.update(db.users)..where((x) => x.id.equals(u.id))).write(UsersCompanion(
        failedAttempts: Value(lock ? 0 : failed),
        lockedUntil: Value(lock ? now.add(lockoutDuration) : null),
      ));
      await audit.log(u.username, lock ? 'CuentaBloqueada' : 'InicioSesionFallido', 'Intento $failed de $maxFailedAttempts');
      throw AuthException(lock
          ? 'Demasiados intentos fallidos. La cuenta quedó bloqueada por ${lockoutDuration.inMinutes} minutos.'
          : 'Usuario o contraseña incorrectos. Le quedan ${maxFailedAttempts - failed} intento(s).');
    }
    await (db.update(db.users)..where((x) => x.id.equals(u.id))).write(UsersCompanion(
      failedAttempts: const Value(0),
      lockedUntil: const Value(null),
      lastLoginAt: Value(now),
    ));
    await audit.log(u.username, 'InicioSesion');
    if (remember) {
      await secrets.write(SecretKeys.sessionToken,
          jsonEncode({'u': u.username, 'exp': now.add(sessionDuration).toIso8601String()}));
    } else {
      await secrets.delete(SecretKeys.sessionToken);
    }
    return AppUser.fromRow(await _byId(u.id));
  }

  /// Restores a remembered (≤30-day) session.
  Future<AppUser?> restoreSession() async {
    try {
      final raw = await secrets.read(SecretKeys.sessionToken);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final exp = DateTime.parse(j['exp'] as String);
      if (exp.isBefore(_clock())) {
        await secrets.delete(SecretKeys.sessionToken);
        return null;
      }
      final u = await _byUsername(j['u'] as String);
      if (u == null || !u.isActive) return null;
      return AppUser.fromRow(u);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout(AppUser user) async {
    await secrets.delete(SecretKeys.sessionToken);
    await audit.log(user.username, 'CierreSesion');
  }

  Future<AppUser> changePassword(AppUser user, String current, String newPassword) async {
    final u = await _byId(user.id);
    if (!await hasher.verify(current, u.passwordHash)) {
      throw AuthException('La contraseña actual no es correcta.');
    }
    if (current == newPassword) throw AuthException('La nueva contraseña debe ser distinta de la actual.');
    final policy = validatePasswordPolicy(newPassword);
    if (policy != null) throw AuthException(policy);
    await (db.update(db.users)..where((x) => x.id.equals(u.id))).write(UsersCompanion(
      passwordHash: Value(await hasher.hash(newPassword)),
      mustChangePassword: const Value(false),
    ));
    await audit.log(u.username, 'ContrasenaCambiada');
    try {
      final f = File(firstAccessFile);
      if (u.mustChangePassword && f.existsSync()) f.deleteSync();
    } catch (_) {}
    return AppUser.fromRow(await _byId(u.id));
  }

  Future<List<AppUser>> allUsers() async =>
      (await (db.select(db.users)..orderBy([(u) => OrderingTerm.asc(u.username)])).get()).map(AppUser.fromRow).toList();

  Future<AppUser> createUser({
    required AppUser by,
    required String username,
    required String displayName,
    required String password,
    bool isAdmin = false,
  }) async {
    _requireAdmin(by);
    final name = username.trim();
    if (!RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(name)) {
      throw AuthException('El usuario debe tener 3–32 caracteres: letras, números, punto, guion o guion bajo.');
    }
    if (await _byUsername(name) != null) throw AuthException('Ya existe un usuario "$name".');
    final policy = validatePasswordPolicy(password);
    if (policy != null) throw AuthException(policy);
    final id = await db.into(db.users).insert(UsersCompanion.insert(
          username: name,
          passwordHash: await hasher.hash(password),
          displayName: displayName.trim().isEmpty ? name : displayName.trim(),
          isAdmin: Value(isAdmin),
          mustChangePassword: const Value(true),
          createdAt: _clock(),
        ));
    await audit.log(by.username, 'UsuarioCreado', '$name${isAdmin ? ' (administrador)' : ''}');
    return AppUser.fromRow(await _byId(id));
  }

  Future<int> _activeAdminCount() async =>
      (await (db.select(db.users)..where((u) => u.isAdmin.equals(true) & u.isActive.equals(true))).get()).length;

  Future<void> setActive({required AppUser by, required int userId, required bool active}) async {
    _requireAdmin(by);
    final u = await _byId(userId);
    if (!active) {
      if (u.id == by.id) throw AuthException('No puede desactivar su propio usuario.');
      if (u.isAdmin && u.isActive && await _activeAdminCount() <= 1) {
        throw AuthException('No se puede desactivar el último administrador activo.');
      }
    }
    await (db.update(db.users)..where((x) => x.id.equals(userId))).write(UsersCompanion(
      isActive: Value(active),
      failedAttempts: const Value(0),
      lockedUntil: const Value(null),
    ));
    await audit.log(by.username, active ? 'UsuarioActivado' : 'UsuarioDesactivado', u.username);
  }

  Future<void> setAdmin({required AppUser by, required int userId, required bool isAdmin}) async {
    _requireAdmin(by);
    final u = await _byId(userId);
    if (!isAdmin && u.isAdmin && u.isActive && await _activeAdminCount() <= 1) {
      throw AuthException('Debe quedar al menos un administrador activo.');
    }
    await (db.update(db.users)..where((x) => x.id.equals(userId))).write(UsersCompanion(isAdmin: Value(isAdmin)));
    await audit.log(by.username, isAdmin ? 'UsuarioPromovidoAdmin' : 'UsuarioQuitadoAdmin', u.username);
  }

  /// Admin reset: sets a temporary password and forces a change.
  Future<void> resetPassword({required AppUser by, required int userId, required String temporaryPassword}) async {
    _requireAdmin(by);
    final policy = validatePasswordPolicy(temporaryPassword);
    if (policy != null) throw AuthException(policy);
    final u = await _byId(userId);
    await (db.update(db.users)..where((x) => x.id.equals(userId))).write(UsersCompanion(
      passwordHash: Value(await hasher.hash(temporaryPassword)),
      mustChangePassword: const Value(true),
      failedAttempts: const Value(0),
      lockedUntil: const Value(null),
    ));
    await audit.log(by.username, 'ContrasenaRestablecida', u.username);
  }

  static void _requireAdmin(AppUser by) {
    if (!by.isAdmin) throw AuthException('Solo un administrador puede realizar esta acción.');
  }
}
