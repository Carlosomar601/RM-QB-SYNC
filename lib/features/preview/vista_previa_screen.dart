import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/exceptions.dart';
import '../../core/money.dart';
import '../../core/sync_rules.dart';
import '../../data/pos/pos_providers.dart';
import '../../services/preview_service.dart';
import '../../services/service_providers.dart';
import '../../services/sync_pipeline.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';
import 'preview_dialogs.dart';

/// Quick date range presets.
List<(String, DateTime, DateTime)> rangePresets(DateTime now) {
  final today = Dates.today(now);
  final firstThis = DateTime(today.year, today.month, 1);
  final lastPrev = Dates.addDays(firstThis, -1);
  return [
    ('Hoy', today, today),
    ('Ayer', Dates.addDays(today, -1), Dates.addDays(today, -1)),
    ('Últimos 7 días', Dates.addDays(today, -6), today),
    ('Últimos 21 días', Dates.addDays(today, -20), today),
    ('Este mes', firstThis, today),
    ('Mes anterior', DateTime(lastPrev.year, lastPrev.month, 1), lastPrev),
  ];
}

class VistaPreviaScreen extends ConsumerStatefulWidget {
  const VistaPreviaScreen({super.key, this.initialFrom, this.initialTo});
  final DateTime? initialFrom;
  final DateTime? initialTo;

  @override
  ConsumerState<VistaPreviaScreen> createState() => _VistaPreviaScreenState();
}

class _VistaPreviaScreenState extends ConsumerState<VistaPreviaScreen> {
  static const _draftKey = 'vistaPrevia';
  late DateTime _from;
  late DateTime _to;
  Future<PreviewResult>? _preview;
  PreviewResult? _result;
  Object? _error;
  String? _overlapMessage;
  bool _allowDuplicate = false;
  SyncResult? _sent;
  int _wizardKey = 0;

  @override
  void initState() {
    super.initState();
    final today = Dates.today(ref.read(clockProvider)());
    _from = widget.initialFrom ?? Dates.addDays(today, -20);
    _to = widget.initialTo ?? today;
    if (widget.initialFrom == null) {
      ref.read(draftStoreProvider).read(_draftKey).then((d) {
        if (d == null || !mounted) return;
        final f = DateTime.tryParse('${d['from']}');
        final t = DateTime.tryParse('${d['to']}');
        if (f != null && t != null) {
          setState(() {
            _from = f;
            _to = t;
          });
        }
      });
    }
  }

  void _setRange(DateTime f, DateTime t) {
    setState(() {
      _from = Dates.dateOnly(f);
      _to = Dates.dateOnly(t);
      _result = null;
      _error = null;
    });
    ref.read(draftStoreProvider).save(_draftKey, {'from': Dates.iso(_from), 'to': Dates.iso(_to)});
  }

  void _load() {
    setState(() {
      _result = null;
      _error = null;
      _overlapMessage = null;
      _allowDuplicate = false;
      _preview = ref.read(previewServiceProvider).build(_from, _to);
    });
    _preview!.then((r) async {
      final prior = await ref.read(historyRepositoryProvider).findOverlappingSuccess(_from, _to);
      if (!mounted) return;
      setState(() {
        _result = r;
        _overlapMessage = prior == null ? null : DuplicateRule.skippedMessage(prior);
      });
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e);
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final today = Dates.today(ref.read(clockProvider)());
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2015),
      lastDate: today,
      helpText: isFrom ? 'Fecha inicial' : 'Fecha final',
    );
    if (d != null) _setRange(isFrom ? d : _from, isFrom ? _to : d);
  }

  Future<void> _send({bool force = false}) async {
    final r = _result!;
    final d = r.draft!;
    final dup = force || _allowDuplicate;
    final ok = await confirmAction(
      context,
      title: dup ? 'Enviar de todas formas' : 'Enviar a QuickBooks',
      message: 'Se creará un asiento de diario en QuickBooks. Esta acción no se puede deshacer desde RMQBsync '
          '(tendría que borrarlo en QuickBooks).',
      bullets: [
        'Rango: ${Dates.dmy(_from)} al ${Dates.dmy(_to)}',
        'Fecha del asiento: ${Dates.dmy(d.txnDate)}',
        'Total: \$${Money.format(d.totalDebit)} (${d.lines.length} líneas)',
        if (dup) 'ATENCIÓN: ya existe un envío exitoso para parte de estas fechas; podría duplicar ventas.',
      ],
      confirmLabel: dup ? 'Sí, enviar duplicado' : 'Confirmar y enviar',
      destructive: dup,
    );
    if (!ok) return;
    final res = await ref.read(syncPipelineProvider).runSync(
          from: _from,
          to: _to,
          trigger: SyncTrigger.manual,
          user: ref.read(sessionProvider)!.username,
          allowDuplicate: dup,
        );
    if (!mounted) return;
    if (res.status == SyncStatus.success) await ref.read(draftStoreProvider).clear(_draftKey);
    ref.invalidate(setupStatusProvider);
    setState(() => _sent = res);
  }

  @override
  Widget build(BuildContext context) {
    final posCfg = ref.watch(posConfigProvider).value;
    return PageBody(children: [
      const ScreenHeader(
        icon: Icons.preview,
        title: 'Vista Previa',
        purpose: 'Revise el asiento que se enviará a QuickBooks para un rango de fechas.',
        nextHint: 'Paso 1: rango · Paso 2: revisar · Paso 3: confirmar y enviar.',
      ),
      if (posCfg != null && !posCfg.isConfigured)
        GuidanceBanner(
          kind: GuidanceKind.warning,
          title: 'Configure la API del POS',
          message: 'Indique la IP y el puerto del servidor del POS en Configuración para poder leer las ventas.',
          actionLabel: 'Ir a Configuración',
          onAction: () => context.go(Routes.configuracion),
        ),
      if (_sent != null) _resultView(_sent!) else _wizard(),
    ]);
  }

  Widget _resultView(SyncResult r) {
    final ok = r.status == SyncStatus.success;
    final skipped = r.status == SyncStatus.skipped;
    return CompletionSummary(
      success: ok,
      title: ok
          ? 'Asiento enviado a QuickBooks'
          : skipped
              ? 'Envío omitido (posible duplicado)'
              : 'No se pudo enviar',
      message: r.message,
      items: [
        SummaryItem('Rango', '${Dates.dmy(_from)} al ${Dates.dmy(_to)}'),
        if (r.qboJournalEntryId != null) SummaryItem('Número de asiento en QuickBooks', '#${r.qboJournalEntryId}'),
        if (r.totalDebit != null) SummaryItem('Total', '\$${Money.format(r.totalDebit!)}'),
        SummaryItem('Registro en Historial', '#${r.historyId}'),
      ],
      nextActionLabel: ok ? 'Ver en Historial' : (skipped ? 'Sincronizar de todas formas' : 'Volver a revisar'),
      onNextAction: ok
          ? () => context.go(Routes.historial)
          : skipped
              ? () async {
                  setState(() => _sent = null);
                  await _send(force: true);
                }
              : () => setState(() {
                    _sent = null;
                    _wizardKey++;
                  }),
      secondaryLabel: ok ? 'Revisar otro rango' : 'Cerrar',
      onSecondary: () => setState(() {
        _sent = null;
        _result = null;
        _wizardKey++;
      }),
    );
  }

  Widget _wizard() {
    final now = ref.read(clockProvider)();
    return StepWizard(
      key: ValueKey(_wizardKey),
      completeLabel: _overlapMessage != null && !_allowDuplicate ? 'Revise el aviso de duplicado' : 'Confirmar y Enviar a QuickBooks',
      onStepChanged: (i) {
        if (i == 1 && (_result == null || _result!.summary.fromDate != _from || _result!.summary.toDate != _to)) _load();
      },
      steps: [
        WizardStep(
          title: 'Rango de fechas',
          explanation: 'Elija qué días de ventas quiere revisar. Se creará un solo asiento con fecha del último día.',
          instructions: const [
            'Toque un atajo (por ejemplo "Ayer") o elija las fechas inicial y final.',
            'Presione Siguiente para consultar el POS.',
          ],
          example: 'Recomendado: envíe un día a la vez ("Ayer") o el mes anterior completo.',
          validate: () => [
            if (_to.isBefore(_from)) 'La fecha final no puede ser anterior a la inicial.',
            if (Dates.dayCount(_from, _to) > 366) 'El rango no puede ser mayor de un año.',
          ],
          builder: (_) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in rangePresets(now))
                ChoiceChip(
                  label: Text(p.$1),
                  selected: _from == p.$2 && _to == p.$3,
                  onSelected: (_) => _setRange(p.$2, p.$3),
                ),
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.event),
                label: Text('Desde: ${Dates.dmy(_from)}'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.event),
                label: Text('Hasta: ${Dates.dmy(_to)}'),
              ),
              Text('${Dates.dayCount(_from, _to)} día(s)'),
            ]),
          ]),
        ),
        WizardStep(
          title: 'Revisar',
          explanation: 'Compare los totales del POS y el asiento. Debe decir "Balanceado" para poder enviarlo.',
          instructions: const [
            'Revise que cada categoría tenga cuenta.',
            'Confirme que el Debe y el Haber sean iguales.',
            'Si no cuadra, use "Diagnosticar diferencia".',
          ],
          validate: () {
            if (_error != null) return ['No se pudo consultar el POS. Corrija el error y vuelva a intentar.'];
            final r = _result;
            if (r == null) return ['Espere a que termine la consulta al POS.'];
            return [
              if (r.missingCategories.isNotEmpty) 'Faltan cuentas para: ${r.missingCategories.map(PosCategories.label).join(', ')}.',
              if (r.draft != null && !r.draft!.hasLines) 'No hay ventas en este rango.',
              if (r.draft != null && r.draft!.hasLines && !r.draft!.isBalanced) 'El asiento no está balanceado.',
              if (r.draft != null && r.draft!.hasMissingEntities) 'Hay líneas sin cliente/suplidor requerido.',
            ];
          },
          builder: (_) => _reviewStep(),
        ),
        WizardStep(
          title: 'Confirmar y enviar',
          explanation: 'Último paso: se creará el asiento en QuickBooks.',
          instructions: const ['Lea el resumen.', 'Presione "Confirmar y Enviar a QuickBooks" y confirme.'],
          validate: () => [
            if (_overlapMessage != null && !_allowDuplicate)
              'Ya existe un envío exitoso para estas fechas. Marque "Sincronizar de todas formas" solo si está seguro.',
          ],
          builder: (_) => _confirmStep(),
        ),
      ],
      onComplete: _send,
    );
  }

  Widget _reviewStep() {
    if (_error != null) {
      final e = _error!;
      return GuidanceBanner(
        kind: GuidanceKind.error,
        title: e is PosNotConfiguredException ? 'La API del POS no está configurada' : 'No se pudo consultar el POS',
        message: '$e',
        actionLabel: 'Reintentar',
        onAction: _load,
        secondaryLabel: 'Revisar Configuración',
        onSecondary: () => context.go(Routes.configuracion),
      );
    }
    final r = _result;
    if (r == null) return const LoadingBox(message: 'Consultando el POS…');
    final s = r.summary;
    final d = r.draft;
    final t = Theme.of(context).textTheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
          onPressed: () => showBalanceDiagnostic(context, ref, _from, _to),
          icon: const Icon(Icons.troubleshoot),
          label: const Text('Diagnosticar diferencia'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final day = await showDatePicker(
                context: context, initialDate: _to, firstDate: _from, lastDate: _to, helpText: 'Día a detallar');
            if (day != null && mounted) await showDayDrillDown(context, day);
          },
          icon: const Icon(Icons.search),
          label: const Text('Ver detalle de un día'),
        ),
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Volver a consultar')),
      ]),
      const SizedBox(height: 12),
      if (r.missingCategories.isNotEmpty)
        GuidanceBanner(
          kind: GuidanceKind.error,
          title: 'Faltan cuentas en Mapeo de Cuentas',
          message: r.missingCategories.map(PosCategories.label).join(', '),
          actionLabel: 'Ir a Mapeo de Cuentas',
          onAction: () => context.go(Routes.mapeo),
        ),
      if (d != null && !d.hasLines)
        const GuidanceBanner(
            kind: GuidanceKind.warning, title: 'No hay ventas en este rango', message: 'Elija otro rango en el paso 1.'),
      if (d != null && d.hasLines && !d.isBalanced)
        GuidanceBanner(
          kind: GuidanceKind.error,
          title: 'El asiento no está balanceado (diferencia \$${Money.format(d.difference)})',
          message: 'Las ventas y los pagos del POS no suman lo mismo en este rango.',
          actionLabel: 'Diagnosticar diferencia',
          onAction: () => showBalanceDiagnostic(context, ref, _from, _to),
        ),
      if (d != null && d.hasMissingEntities)
        GuidanceBanner(
          kind: GuidanceKind.error,
          title: 'Faltan clientes/suplidores',
          message: 'Líneas: ${d.linesMissingRequiredEntity.map((l) => PosCategories.label(l.category)).join(', ')}',
          actionLabel: 'Ir a Mapeo de Cuentas',
          onAction: () => context.go(Routes.mapeo),
        ),
      if (Money.toCents(s.totalDiscounts) != 0)
        GuidanceBanner(
          kind: GuidanceKind.info,
          title: 'Descuentos del período: \$${Money.format(s.totalDiscounts)}',
          message: 'Solo informativo: los descuentos NO se incluyen en el asiento (la venta neta ya los descuenta).',
        ),
      if (d != null && d.canSubmit)
        const GuidanceBanner(kind: GuidanceKind.success, title: 'Balanceado y listo para enviar'),
      const SizedBox(height: 8),
      Text('Resumen por categoría (${Dates.dmy(s.fromDate)} al ${Dates.dmy(s.toDate)})', style: t.titleMedium),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(columns: const [
          DataColumn(label: Text('Grupo')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Monto'), numeric: true),
          DataColumn(label: Text('Cuenta')),
        ], rows: [
          for (final c in s.categories)
            DataRow(cells: [
              DataCell(Text(c.group)),
              DataCell(Text(PosCategories.label(c.category))),
              DataCell(Text(Money.format(c.amount))),
              DataCell(Text(r.mappings[c.category]?.accountName ??
                  (Money.toCents(c.amount) == 0 ? '—' : 'SIN CUENTA'))),
            ]),
          DataRow(cells: [
            const DataCell(Text('')),
            const DataCell(Text('Total Ventas', style: TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(Money.format(s.totalByGroup(PosGroups.ventas)), style: const TextStyle(fontWeight: FontWeight.bold))),
            const DataCell(Text('')),
          ]),
          DataRow(cells: [
            const DataCell(Text('')),
            const DataCell(Text('Total Pagos', style: TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(Money.format(s.totalByGroup(PosGroups.pagos)), style: const TextStyle(fontWeight: FontWeight.bold))),
            const DataCell(Text('')),
          ]),
        ]),
      ),
      if (d != null && d.hasLines) ...[
        const SizedBox(height: 16),
        Row(children: [
          Text('Asiento de diario', style: t.titleMedium),
          const SizedBox(width: 12),
          Chip(
            avatar: Icon(d.isBalanced ? Icons.check_circle : Icons.error,
                color: d.isBalanced ? const Color(0xFF1B7F3B) : Theme.of(context).colorScheme.error, size: 18),
            label: Text(d.isBalanced ? 'Balanceado' : 'No balanceado'),
          ),
        ]),
        Text(d.description, style: t.bodyMedium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: const [
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Descripción')),
            DataColumn(label: Text('Cuenta')),
            DataColumn(label: Text('Debe'), numeric: true),
            DataColumn(label: Text('Haber'), numeric: true),
          ], rows: [
            for (final l in d.lines)
              DataRow(
                color: l.isMissingRequiredEntity
                    ? WidgetStatePropertyAll(Theme.of(context).colorScheme.errorContainer)
                    : null,
                cells: [
                  DataCell(Text(Dates.dmy(d.txnDate))),
                  DataCell(Text(l.entityName ?? (l.entityType != null ? 'FALTA ${l.entityType!.label.toUpperCase()}' : ''))),
                  DataCell(Text(l.description)),
                  DataCell(Text(l.accountName)),
                  DataCell(Text(l.debit == 0 ? '' : Money.format(l.debit))),
                  DataCell(Text(l.credit == 0 ? '' : Money.format(l.credit))),
                ],
              ),
            DataRow(cells: [
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('Totales', style: TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(Money.format(d.totalDebit), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(Money.format(d.totalCredit), style: const TextStyle(fontWeight: FontWeight.bold))),
            ]),
          ]),
        ),
      ],
    ]);
  }

  Widget _confirmStep() {
    final d = _result?.draft;
    if (d == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Table(columnWidths: const {0: IntrinsicColumnWidth()}, children: [
        for (final (k, v) in [
          ('Rango', '${Dates.dmy(_from)} al ${Dates.dmy(_to)}'),
          ('Fecha del asiento', Dates.dmy(d.txnDate)),
          ('Nota', d.description),
          ('Líneas', '${d.lines.length}'),
          ('Total Debe / Haber', '\$${Money.format(d.totalDebit)} / \$${Money.format(d.totalCredit)}'),
        ])
          TableRow(children: [
            Padding(padding: const EdgeInsets.only(right: 16, bottom: 6), child: Text(k)),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
      ]),
      if (_overlapMessage != null) ...[
        GuidanceBanner(kind: GuidanceKind.warning, title: 'Posible duplicado', message: _overlapMessage),
        CheckboxListTile(
          value: _allowDuplicate,
          onChanged: (v) => setState(() => _allowDuplicate = v ?? false),
          title: const Text('Sincronizar de todas formas'),
          subtitle: const Text('Solo si borró el asiento anterior en QuickBooks o está seguro de que no duplica ventas.'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    ]);
  }
}
