import 'dates.dart';

enum SyncStatus {
  success('Success', 'Exitosa'),
  failed('Failed', 'Fallida'),
  skipped('Skipped', 'Omitida'),
  running('Running', 'En curso');

  const SyncStatus(this.code, this.label);
  final String code;
  final String label;

  static SyncStatus parse(String v) =>
      values.firstWhere((s) => s.code.toLowerCase() == v.toLowerCase(), orElse: () => failed);
}

enum SyncTrigger {
  manual('Manual', 'Manual'),
  scheduled('Scheduled', 'Programada');

  const SyncTrigger(this.code, this.label);
  final String code;
  final String label;

  static SyncTrigger parse(String v) =>
      values.firstWhere((s) => s.code.toLowerCase() == v.toLowerCase(), orElse: () => manual);
}

/// Minimal view of a history row needed by the duplicate rule.
class SyncRangeRecord {
  const SyncRangeRecord({required this.from, required this.to, required this.status, this.id});
  final int? id;
  final DateTime from;
  final DateTime to;
  final SyncStatus status;
}

abstract final class DuplicateRule {
  /// True if [a]..[b] overlaps [c]..[d] (inclusive dates).
  static bool overlaps(DateTime aFrom, DateTime aTo, DateTime bFrom, DateTime bTo) =>
      !Dates.dateOnly(aFrom).isAfter(Dates.dateOnly(bTo)) &&
      !Dates.dateOnly(aTo).isBefore(Dates.dateOnly(bFrom));

  /// First prior successful sync overlapping the requested range, or null.
  static SyncRangeRecord? findOverlappingSuccess(
    Iterable<SyncRangeRecord> history,
    DateTime from,
    DateTime to,
  ) {
    for (final h in history) {
      if (h.status == SyncStatus.success && overlaps(h.from, h.to, from, to)) return h;
    }
    return null;
  }

  static String skippedMessage(SyncRangeRecord prior) =>
      'Omitida: ya existe una sincronización exitosa que cubre parte de este rango '
      '(${Dates.dmy(prior.from)} al ${Dates.dmy(prior.to)}). '
      'Use "Sincronizar de todas formas" si realmente desea enviar otro asiento.';
}
