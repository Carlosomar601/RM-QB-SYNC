import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Rotating file logger (5 files × 2 MB) under `%ProgramData%\RMQBsync\logs`.
/// Every message is passed through [redact] so tokens and secrets never
/// reach disk.
abstract final class AppLogger {
  static final Logger _log = Logger('RMQBsync');
  static IOSink? _sink;
  static File? _file;
  static String? _dir;
  static const int maxBytes = 2 * 1024 * 1024;
  static const int maxFiles = 5;

  static void init(String dir) {
    _dir = dir;
    Directory(dir).createSync(recursive: true);
    _open();
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen(_write);
  }

  static void info(String msg) => _log.info(msg);
  static void warning(String msg, [Object? e, StackTrace? st]) => _log.warning(msg, e, st);
  static void error(String msg, [Object? e, StackTrace? st]) => _log.severe(msg, e, st);

  static final List<RegExp> _patterns = [
    RegExp(r'(Bearer\s+)[A-Za-z0-9\-\._~\+\/=]+', caseSensitive: false),
    RegExp(r'(Basic\s+)[A-Za-z0-9\+\/=]+', caseSensitive: false),
    RegExp(r'("?(?:access_token|refresh_token|client_secret|clientSecret|password|code|id_token)"?\s*[:=]\s*"?)[^"&,\s}]+',
        caseSensitive: false),
  ];

  static String redact(String input) {
    var s = input;
    for (final r in _patterns) {
      s = s.replaceAllMapped(r, (m) => '${m[1]}***');
    }
    return s;
  }

  static void _open() {
    if (_dir == null) return;
    _file = File(p.join(_dir!, 'rmqbsync.log'));
    _sink = _file!.openWrite(mode: FileMode.append);
  }

  static void _write(LogRecord r) {
    final line = StringBuffer('${r.time.toIso8601String()} [${r.level.name}] ${r.message}');
    if (r.error != null) line.write(' | ${r.error}');
    if (r.stackTrace != null) line.write('\n${r.stackTrace}');
    final text = redact(line.toString());
    // ignore: avoid_print
    if (_sink == null) return print(text);
    _sink!.writeln(text);
    _rotateIfNeeded();
  }

  static void _rotateIfNeeded() {
    final f = _file;
    if (f == null) return;
    try {
      if (!f.existsSync() || f.lengthSync() < maxBytes) return;
      _sink?.close();
      for (var i = maxFiles - 1; i >= 1; i--) {
        final src = File('${f.path}.$i');
        if (src.existsSync()) {
          final dst = File('${f.path}.${i + 1}');
          if (dst.existsSync()) dst.deleteSync();
          if (i + 1 < maxFiles) {
            src.renameSync(dst.path);
          } else {
            src.deleteSync();
          }
        }
      }
      f.renameSync('${f.path}.1');
      _open();
    } catch (_) {
      // Logging must never crash the app.
    }
  }
}
