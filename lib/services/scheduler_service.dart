import 'dart:async';

import '../core/schedule.dart';
import '../core/sync_rules.dart';
import '../data/db/repositories.dart';
import 'app_logger.dart';
import 'sync_pipeline.dart';

/// Fires scheduled syncs. Polls at most hourly (sooner if a run is due
/// earlier), catches up missed runs on wake (`nextRunAt <= now`), and never
/// overrides the duplicate rule.
class SchedulerService {
  SchedulerService({
    required this.schedules,
    required this.runSync,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ScheduleRepository schedules;
  final Future<SyncResult> Function({
    required DateTime from,
    required DateTime to,
    required SyncTrigger trigger,
    required String user,
    bool allowDuplicate,
  }) runSync;
  final DateTime Function() _clock;

  static const maxPoll = Duration(hours: 1);
  static const minPoll = Duration(minutes: 1);
  static const systemUser = 'Sistema (programada)';

  Timer? _timer;
  bool _running = false;

  /// Notified after each executed scheduled run (UI refresh / tray balloon).
  void Function(SyncResult result)? onRun;

  void start() {
    unawaited(_loop());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Re-evaluates immediately (e.g. after the schedule is edited).
  void poke() {
    _timer?.cancel();
    unawaited(_loop());
  }

  Future<void> _loop() async {
    Duration wait = maxPoll;
    try {
      wait = await tick();
    } catch (e, st) {
      AppLogger.error('Error en el programador de sincronizaciones', e, st);
    }
    _timer?.cancel();
    _timer = Timer(wait, () => unawaited(_loop()));
  }

  /// Runs due schedules; returns how long to wait before the next check.
  Future<Duration> tick() async {
    if (_running) return minPoll;
    _running = true;
    try {
      final now = _clock();
      DateTime? earliest;
      for (final s in await schedules.all()) {
        if (!s.enabled || s.id == null) continue;
        var next = s.nextRunAt;
        if (next == null) {
          next = s.computeNext(now);
          await schedules.setNext(s.id!, next);
        } else if (!next.isAfter(now)) {
          final range = ScheduleCalculator.rangeFor(s.frequency, now);
          AppLogger.info('Ejecutando sincronización programada (${s.frequency.label}) para $range '
              '(prevista ${next.toIso8601String()}).');
          final result = await runSync(
            from: range.from,
            to: range.to,
            trigger: SyncTrigger.scheduled,
            user: systemUser,
            allowDuplicate: false,
          );
          final after = _clock();
          next = s.computeNext(after);
          await schedules.markRun(s.id!, ranAt: after, nextRunAt: next);
          onRun?.call(result);
        }
        if (earliest == null || next.isBefore(earliest)) earliest = next;
      }
      if (earliest == null) return maxPoll;
      final until = earliest.difference(_clock());
      if (until < minPoll) return minPoll;
      return until > maxPoll ? maxPoll : until;
    } finally {
      _running = false;
    }
  }
}
