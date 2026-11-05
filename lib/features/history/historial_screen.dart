import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../core/sync_rules.dart';
import '../../data/db/app_database.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';
import '../onboarding/tour.dart';

final historyProvider = StreamProvider<List<SyncHistoryRow>>(
  (ref) => ref.watch(historyRepositoryProvider).watchRecent(200),
);

/// Sync-run status pill (icon + text + tint; never color alone).
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip(this.status, {super.key});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      SyncStatus.success => (RmTone.success, Icons.check_circle_outline),
      SyncStatus.failed => (RmTone.danger, Icons.error_outline),
      SyncStatus.skipped => (RmTone.warning, Icons.skip_next_outlined),
      SyncStatus.running => (RmTone.info, Icons.schedule),
    };
    return StatusChip(label: status.label, tone: tone, icon: icon);
  }
}

/// Best-effort recovery hint for a failure message (UI guidance only).
({String hint, String? label, String? route}) recoveryFor(String message) {
  final m = message.toLowerCase();
  if (m.contains('balance') || m.contains('cuadr') || m.contains('diferencia')) {
    return (
      hint: 'El asiento no cuadra. Abra Vista Previa con el mismo rango y use "Diagnosticar diferencia".',
      label: null,
      route: null,
    );
  }
  if (m.contains('mapeo') || m.contains('sin cuenta') || m.contains('categor')) {
    return (hint: 'Falta asignar una cuenta de QuickBooks a alguna categoría.', label: 'Ir a Mapeo de Cuentas', route: Routes.mapeo);
  }
  if (m.contains('cliente') || m.contains('suplidor') || m.contains('entidad')) {
    return (hint: 'Una cuenta de Cuentas por Cobrar o por Pagar necesita un cliente o suplidor.', label: 'Ir a Mapeo de Cuentas', route: Routes.mapeo);
  }
  if (m.contains('401') || m.contains('token') || m.contains('autoriz') || m.contains('invalid_grant') || m.contains('conect')) {
    return (
      hint: 'Puede que la autorización de QuickBooks haya vencido o la conexión falló. Pruebe o reconecte QuickBooks.',
      label: 'Ir a Configuración',
      route: Routes.configuracion,
    );
  }
  if (m.contains('pos') || m.contains('socket') || m.contains('timeout') || m.contains('tiempo de espera')) {
    return (
      hint: 'No se pudo leer el POS. Verifique que el servidor Retail Manager esté encendido y en la red.',
      label: 'Ir a Configuración',
      route: Routes.configuracion,
    );
  }
  if (m.contains('cerró antes')) {
    return (hint: 'La aplicación se cerró durante el envío. Revise en QuickBooks si el asiento existe antes de volver a enviar.', label: null, route: null);
  }
  return (hint: 'Revise el rango en Vista Previa para ver el asiento y los avisos antes de volver a enviarlo.', label: null, route: null);
}

Future<void> showHistoryDetail(BuildContext context, SyncHistoryRow r) => showDialog<void>(
      context: context,
      builder: (ctx) {
        final st = SyncStatus.parse(r.status);
        final t = Theme.of(ctx).textTheme;
        void go(String route) {
          Navigator.of(ctx).pop();
          GoRouter.of(context).go(route);
        }

        final previewRoute = '${Routes.vistaPrevia}?desde=${Dates.iso(r.fromDate)}&hasta=${Dates.iso(r.toDate)}';
        final rec = r.errorMessage == null ? null : recoveryFor(r.errorMessage!);
        Widget kv(String k, Widget v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 170, child: Text(k, style: t.bodyMedium?.copyWith(color: ctx.rm.textSecondary))),
                Expanded(child: v),
              ]),
            );
        return AlertDialog(
          title: Row(children: [
            Expanded(child: Text('Sincronización #${r.id}')),
            SyncStatusChip(st),
          ]),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                kv('Rango', Text('${Dates.dmy(r.fromDate)} al ${Dates.dmy(r.toDate)}')),
                kv('Ejecutada', Text(Dates.dmyHm(r.ranAt))),
                kv('Origen', Text('${SyncTrigger.parse(r.trigger).label} · ${r.performedBy}')),
                if (r.qboJournalEntryId != null) kv('Asiento en QuickBooks', Text('#${r.qboJournalEntryId}')),
                if (r.totalDebit != null) ...[
                  kv('Total Debe', MoneyText(r.totalDebit!, align: TextAlign.left)),
                  kv('Total Haber', MoneyText(r.totalCredit ?? 0, align: TextAlign.left)),
                ],
                if (r.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  ErrorDetailPanel(
                    tone: st == SyncStatus.failed ? RmTone.danger : RmTone.warning,
                    title: switch (st) {
                      SyncStatus.failed => 'Qué pasó: la sincronización falló y no se creó el asiento',
                      SyncStatus.skipped => 'Qué pasó: se omitió para no duplicar un envío anterior',
                      _ => 'Mensaje',
                    },
                    message: r.errorMessage!,
                    hint: st == SyncStatus.failed
                        ? '${rec?.hint ?? ''} Antes de cada envío se comprueba si el rango ya fue aceptado por QuickBooks, '
                            'así que no se duplicará.'
                        : null,
                    actions: [
                      if (st != SyncStatus.success)
                        FilledButton.tonal(onPressed: () => go(previewRoute), child: const Text('Revisar en Vista Previa')),
                      if (rec != null && rec.route != null)
                        OutlinedButton(onPressed: () => go(rec.route!), child: Text(rec.label!)),
                    ],
                  ),
                ] else if (st != SyncStatus.success) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: () => go(previewRoute), child: const Text('Revisar en Vista Previa')),
                ],
                if (r.requestJson != null) _JsonBlock('JSON enviado a QuickBooks', r.requestJson!),
                if (r.responseJson != null) _JsonBlock('Respuesta de QuickBooks', r.responseJson!),
              ]),
            ),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
          ],
        );
      },
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
            decoration: BoxDecoration(
              color: context.rm.surfaceAlt,
              borderRadius: BorderRadius.circular(RmRadius.control),
              border: Border.all(color: context.rm.border),
            ),
            child: SelectableText(json, style: const TextStyle(fontFamily: 'Consolas', fontSize: 12)),
          ),
        ],
      );
}

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  final _search = TextEditingController();
  SyncStatus? _status;
  SyncTrigger? _trigger;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(SyncHistoryRow r) {
    if (_status != null && SyncStatus.parse(r.status) != _status) return false;
    if (_trigger != null && SyncTrigger.parse(r.trigger) != _trigger) return false;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      Dates.dmyHm(r.ranAt),
      Dates.dmy(r.fromDate),
      Dates.dmy(r.toDate),
      r.performedBy,
      r.errorMessage ?? '',
      r.qboJournalEntryId ?? '',
      SyncStatus.parse(r.status).label,
    ].any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(historyProvider);
    return PageBody(maxWidth: 1400, children: [
      const ScreenHeader(
        icon: Icons.history,
        title: 'Historial',
        purpose: 'Resultado de las últimas 200 sincronizaciones. Toque una fila para ver el detalle.',
        nextHint: 'Si una falló, use "Ver error": explica la causa y cómo resolverla.',
      ),
      TourTarget(
        id: 'historial:filters',
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por fecha, usuario, asiento o mensaje',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          for (final (label, st) in const [
            ('Todas', null),
            ('Exitosas', SyncStatus.success),
            ('Fallidas', SyncStatus.failed),
            ('Omitidas', SyncStatus.skipped),
            ('En curso', SyncStatus.running),
          ])
            ChoiceChip(label: Text(label), selected: _status == st, onSelected: (_) => setState(() => _status = st)),
          const SizedBox(width: 8),
          DropdownButton<SyncTrigger?>(
            value: _trigger,
            underline: const SizedBox.shrink(),
            hint: const Text('Origen: todos'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Origen: todos')),
              for (final tr in SyncTrigger.values) DropdownMenuItem(value: tr, child: Text('Origen: ${tr.label}')),
            ],
            onChanged: (v) => setState(() => _trigger = v),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      rows.when(
        loading: () => const LoadingBox(),
        error: (e, _) => GuidanceBanner(kind: GuidanceKind.error, title: 'No se pudo leer el historial', message: '$e'),
        data: (all) {
          if (all.isEmpty) {
            return Card(
              child: EmptyState(
                icon: Icons.history,
                title: 'Todavía no hay sincronizaciones',
                message: 'Cuando envíe un asiento desde Vista Previa o una programación se ejecute, aparecerá aquí.',
                actions: [OutlinedButton(onPressed: () => context.go(Routes.vistaPrevia), child: const Text('Ir a Vista Previa'))],
              ),
            );
          }
          final list = all.where(_matches).toList();
          if (list.isEmpty) {
            return Card(
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'Ninguna sincronización coincide con el filtro',
                actions: [
                  TextButton(
                    onPressed: () => setState(() {
                      _search.clear();
                      _status = null;
                      _trigger = null;
                    }),
                    child: const Text('Quitar filtros'),
                  ),
                ],
              ),
            );
          }
          return TourTarget(
            id: 'historial:table',
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: c.maxWidth),
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
                              DataCell(SyncStatusChip(SyncStatus.parse(r.status))),
                              DataCell(Text(SyncTrigger.parse(r.trigger).label)),
                              DataCell(ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Text(r.performedBy, overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(r.totalDebit == null ? const Text('—') : MoneyText(r.totalDebit!)),
                              DataCell(Text(r.qboJournalEntryId ?? '—')),
                              DataCell(SyncStatus.parse(r.status) == SyncStatus.failed
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 260),
                                        child: Text(r.errorMessage ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ),
                                      TextButton(onPressed: () => showHistoryDetail(context, r), child: const Text('Ver error')),
                                    ])
                                  : ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 340),
                                      child: Text(r.errorMessage ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                    )),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }
}
