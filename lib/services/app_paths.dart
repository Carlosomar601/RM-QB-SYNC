import 'dart:io';

import 'package:path/path.dart' as p;

/// Well-known locations. Data lives under `%ProgramData%\RMQBsync` so it is
/// shared by all Windows users and survives upgrades/uninstall.
abstract final class AppPaths {
  /// Overridable for tests.
  static String? overrideDataDir;

  static String get dataDir {
    if (overrideDataDir != null) return overrideDataDir!;
    final programData = Platform.environment['ProgramData'] ?? r'C:\ProgramData';
    return p.join(programData, 'RMQBsync');
  }

  static String get logsDir => p.join(dataDir, 'logs');

  /// Directory containing the running executable.
  static String get exeDir => p.dirname(Platform.resolvedExecutable);

  /// Optional seed shipped by the installer next to the exe.
  static String get factorySecretsFile => p.join(exeDir, 'factory-secrets.json');
}
