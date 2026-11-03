import 'dart:io';

import 'package:path/path.dart' as p;

/// Well-known locations. Data lives under `%ProgramData%\RMQBsync` so it is
/// shared by all Windows users and survives upgrades/uninstall.
abstract final class AppPaths {
  /// Overridable for tests.
  static String? overrideDataDir;

  static String get dataDir {
    if (overrideDataDir != null) return overrideDataDir!;
    final env = Platform.environment['RMQBSYNC_DATA_DIR'];
    if (env != null && env.trim().isNotEmpty) return env.trim();
    final programData = Platform.environment['ProgramData'] ?? r'C:\ProgramData';
    return p.join(programData, 'RMQBsync');
  }

  static String get logsDir => p.join(dataDir, 'logs');

  /// Directory containing the running executable.
  static String get exeDir => p.dirname(Platform.resolvedExecutable);

  /// Optional Intuit credentials seed shipped by the installer. The installer
  /// puts it in the (user-writable) data folder so the app can delete it after
  /// importing; next to the exe is accepted as a fallback.
  static List<String> get factorySecretsCandidates => [
        p.join(dataDir, 'factory-secrets.json'),
        p.join(exeDir, 'factory-secrets.json'),
      ];
}
