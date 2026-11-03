import '../core/dates.dart';
import '../core/journal_entry.dart';
import '../core/money.dart';
import '../core/sync_rules.dart';
import '../data/db/repositories.dart';
import '../data/quickbooks/journal_entry_qbo_mapper.dart';
import '../data/quickbooks/qbo_api_client.dart';
import 'app_logger.dart';
import 'preview_service.dart';

class SyncResult {
  const SyncResult({
    required this.status,
    required this.historyId,
    required this.message,
    this.qboJournalEntryId,
    this.totalDebit,
    this.totalCredit,
  });

  final SyncStatus status;
  final int historyId;
  final String message;
  final String? qboJournalEntryId;
  final double? totalDebit;
  final double? totalCredit;
}

abstract final class AuditActions {
  static const manualSuccess = 'SincronizacionManualExitosa';
  static const manualFailed = 'SincronizacionManualFallida';
  static const manualSkipped = 'SincronizacionManualOmitidaDuplicado';
  static const scheduledSuccess = 'SincronizacionProgramadaExitosa';
  static const scheduledFailed = 'SincronizacionProgramadaFallida';
  static const scheduledSkipped = 'SincronizacionProgramadaOmitidaDuplicado';
}

/// End-to-end sync: POS → journal entry → QuickBooks, with history + audit.
class SyncPipeline {
  SyncPipeline({
    required this.preview,
    required this.qbo,
    required this.history,
    required this.audit,
    required this.connections,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PreviewService preview;
  final QboApiClient qbo;
  final HistoryRepository history;
  final AuditRepository audit;
  final ConnectionRepository connections;
  final DateTime Function() _clock;

  Future<SyncResult> runSync({
    required DateTime from,
    required DateTime to,
    required SyncTrigger trigger,
    required String user,
    bool allowDuplicate = false,
  }) async {
    from = Dates.dateOnly(from);
    to = Dates.dateOnly(to);
    // Scheduled runs never override the duplicate rule.
    if (trigger == SyncTrigger.scheduled) allowDuplicate = false;
    final manual = trigger == SyncTrigger.manual;
    final range = '${Dates.dmy(from)} al ${Dates.dmy(to)}';

    final id = await history.start(trigger: trigger, performedBy: user, from: from, to: to, now: _clock());
    try {
      if (to.isBefore(from)) {
        throw ArgumentError('La fecha final no puede ser anterior a la fecha inicial.');
      }

      if (!allowDuplicate) {
        final prior = await history.findOverlappingSuccess(from, to, excludeId: id);
        if (prior != null) {
          final msg = DuplicateRule.skippedMessage(prior);
          await history.finish(id, status: SyncStatus.skipped, errorMessage: msg);
          await audit.log(user, manual ? AuditActions.manualSkipped : AuditActions.scheduledSkipped, 'Rango $range. $msg');
          return SyncResult(status: SyncStatus.skipped, historyId: id, message: msg);
        }
      }

      final p = await preview.build(from, to);
      if (p.missingCategories.isNotEmpty) {
        throw StateError('Faltan cuentas en Mapeo de Cuentas para: ${p.missingCategories.join(', ')}.');
      }
      final draft = p.draft!;
      _validate(draft);

      final requestId = JournalEntryQboMapper.requestId(from, to, draft, salt: allowDuplicate ? 'forzado-$id' : '');
      final r = await qbo.createJournalEntry(draft, requestId: requestId);

      await history.finish(
        id,
        status: SyncStatus.success,
        totalDebit: draft.totalDebit,
        totalCredit: draft.totalCredit,
        qboJournalEntryId: r.id,
        requestJson: r.requestJson,
        responseJson: r.responseJson,
      );
      await connections.setLastSync(_clock());
      final msg = 'Asiento #${r.id} creado en QuickBooks por \$${Money.format(draft.totalDebit)} ($range).';
      await audit.log(user, manual ? AuditActions.manualSuccess : AuditActions.scheduledSuccess,
          '$msg${allowDuplicate ? ' Forzado a pesar de duplicado.' : ''}');
      AppLogger.info('Sincronización exitosa: $msg');
      return SyncResult(
        status: SyncStatus.success,
        historyId: id,
        message: msg,
        qboJournalEntryId: r.id,
        totalDebit: draft.totalDebit,
        totalCredit: draft.totalCredit,
      );
    } catch (e, st) {
      final msg = _message(e);
      AppLogger.error('Sincronización fallida ($range): $msg', e, st);
      await history.finish(id, status: SyncStatus.failed, errorMessage: msg);
      await audit.log(user, manual ? AuditActions.manualFailed : AuditActions.scheduledFailed, 'Rango $range. $msg');
      return SyncResult(status: SyncStatus.failed, historyId: id, message: msg);
    }
  }

  static void _validate(JournalEntryDraft draft) {
    if (!draft.hasLines) {
      throw StateError('No hay datos de ventas en el rango seleccionado; no se envió ningún asiento.');
    }
    if (!draft.isBalanced) {
      throw StateError('El asiento no está balanceado (Debe \$${Money.format(draft.totalDebit)} vs Haber '
          '\$${Money.format(draft.totalCredit)}, diferencia \$${Money.format(draft.difference)}). '
          'Use "Diagnosticar Diferencia" en Vista Previa.');
    }
    if (draft.hasMissingEntities) {
      throw StateError('Las líneas ${draft.linesMissingRequiredEntity.map((l) => l.category).join(', ')} '
          'requieren un cliente o suplidor. Complételo en Mapeo de Cuentas.');
    }
  }

  static String _message(Object e) => switch (e) {
        StateError(:final message) => message,
        ArgumentError(:final message) => '$message',
        _ => e.toString(),
      };
}
