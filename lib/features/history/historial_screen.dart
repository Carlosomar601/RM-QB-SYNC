import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/sync_rules.dart';
import '../../data/db/app_database.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';

final historyProvider = StreamProvider<List<SyncHistoryRow>>(
  (ref) => ref.watch(historyRepositoryProvider).watchRecent(200),
);

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SyncStatus.success => (const Color(0xFF1B7F3B), Icons.check_circle),
      SyncStatus.failed => (Theme.of(context).colorScheme.error, Icons.cancel),
      SyncStatus.skipped => (const Color(0xFF8A6100), Icons.skip_next),
      SyncStatus.running => (Theme.of(context).colorScheme.primary, Icons.hourglass_top),
    };
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }
}

Future<void> showHistoryDetail(BuildContext context, SyncHistoryRow r) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sincronización #${r.id}'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [StatusChip(SyncStatus.parse(r.status))]),
              const SizedBox(height: 8),
              Text('Rango: ${Dates.dmy(r.fromDate)} al ${Dates.dmy(r.toDate)}'),
              Text('Ejecutada: ${Dates.dmyHm(r.ranAt)} · ${SyncTrigger.parse(r.trigger).label} · ${r.performedBy}'),
              if (r.qboJournalEntryId != null) Text('Asiento en QuickBooks: #${r.qboJournalEntryId}'),
              if (r.totalDebit != null)
                Text('Debe: \$${Money.format(r.totalDebit!)} · Haber: \$${Money.format(r.totalCredit ?? 0)}'),
              if (r.errorMessage != null) ...[
                const SizedBox(height: 8),
                GuidanceBanner(
                  kind: SyncStatus.parse(r.status) == SyncStatus.skipped ? GuidanceKind.warning : GuidanceKind.error,
                  title: 'Mensaje',
                  message: r.errorMessage,
                ),
              ],
              if (r.requestJson != null) _JsonBlock('JSON enviado a QuickBooks', r.requestJson!),
              if (r.responseJson != null) _JsonBlock('Respuesta de QuickBooks', r.responseJson!),
            ]),
          ),
        ),
        actions: [
          if (SyncStatus.parse(r.status) != SyncStatus.success)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                GoRouter.of(context).go('${Routes.vistaPrevia}?desde=${Dates.iso(r.fromDate)}&hasta=${Dates.iso(r.toDate)}');
              },
              child: const Text('Revisar en Vista Previa'),
            ),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
        ],
      ),
    );

class _JsonBlock extends StatelessWidget {
  const _JsonBlock(this.title, this.json);
  final String title;
  final String json;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(title),
        trailing: IconButton(
          tooltip: 'Copiar',
          icon: const Icon(Icons.copy),
          onPressed: () => Clipboard.setData(ClipboardData(text: json)),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SelectableText(json, style: const TextStyle(fontFamily: 'Consolas', fontSize: 12)),
          ),
        ],
      );
}

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(historyProvider);
    return PageBody(children: [
      const ScreenHeader(
        icon: Icons.history,
        title: 'Historial',
        purpose: 'Resultado de las últimas 200 sincronizaciones. Toque una fila para ver el detalle.',
        nextHint: 'Si una falló, abra el detalle y use "Revisar en Vista Previa".',
      ),
      rows.when(
        loading: () => const LoadingBox(),
        error: (e, _) => GuidanceBanner(kind: GuidanceKind.error, title: 'Error', message: '$e'),
        data: (list) => list.isEmpty
            ? const GuidanceBanner(
                kind: GuidanceKind.info,
                title: 'Todavía no hay sincronizaciones',
                message: 'Cuando envíe un asiento desde Vista Previa o una programación se ejecute, aparecerá aquí.')
            : Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Ejecutada')),
                      DataColumn(label: Text('Rango')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Origen')),
                      DataColumn(label: Text('Usuario')),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('Asiento QBO')),
                      DataColumn(label: Text('Mensaje')),
                    ],
                    rows: [
                      for (final r in list)
                        DataRow(
                          onSelectChanged: (_) => showHistoryDetail(context, r),
                          cells: [
                            DataCell(Text(Dates.dmyHm(r.ranAt))),
                            DataCell(Text('${Dates.dmy(r.fromDate)} – ${Dates.dmy(r.toDate)}')),
                            DataCell(StatusChip(SyncStatus.parse(r.status))),
                            DataCell(Text(SyncTrigger.parse(r.trigger).label)),
                            DataCell(Text(r.performedBy)),
                            DataCell(Text(r.totalDebit == null ? '—' : Money.format(r.totalDebit!))),
                            DataCell(Text(r.qboJournalEntryId ?? '—')),
                            DataCell(SizedBox(
                              width: 320,
                              child: Text(r.errorMessage ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
    ]);
  }
}
