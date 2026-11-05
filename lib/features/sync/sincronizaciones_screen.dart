import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../core/sync_rules.dart';
import '../../data/db/repositories.dart';
import '../../services/service_providers.dart';
import '../../services/sync_pipeline.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';
import '../history/historial_screen.dart';
import '../onboarding/tour.dart';
import '../preview/vista_previa_screen.dart';
import 'schedule_editor.dart';

class SincronizacionesScreen extends ConsumerWidget {
  const SincronizacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const PageBody(children: [
        ScreenHeader(
          icon: Icons.sync,
          title: 'Sincronizaciones',
          purpose: 'Envíe ahora un rango a QuickBooks o programe envíos automáticos.',
          nextHint: 'Si es la primera vez, revise antes en Vista Previa.',
        ),
        SectionCard(
          title: 'Sincronización manual',
          icon: Icons.play_circle_outline,
          help: 'Envía un rango a QuickBooks cuando usted lo indique. Antes de enviar se valida el mapeo, '
              'que el asiento esté balanceado y que el rango no se haya enviado antes.',
          child: _SyncNow(),
        ),
        TourTarget(
          id: 'sync:schedule',
          child: SectionCard(
            title: 'Sincronización automática',
            icon: Icons.schedule,
            help: 'Permite enviar asientos sin intervención manual según el horario configurado. '
                'La aplicación debe estar abierta (puede estar minimizada en la bandeja).',
            child: ScheduleWizard(),
          ),
        ),
      ]);
}

class _SyncNow extends ConsumerStatefulWidget {
  const _SyncNow();

  @override
  ConsumerState<_SyncNow> createState() => _SyncNowState();
}

class _SyncNowState extends ConsumerState<_SyncNow> {
  int _preset = 1; // Ayer
  bool _busy = false;
  SyncResult? _result;

  Future<void> _run({bool force = false}) async {
    final p = rangePresets(ref.read(clockProvider)())[_preset];
    final ok = await confirmAction(context,
        title: force ? 'Sincronizar de todas formas' : 'Sincronizar ahora',
        message: 'Se enviará a QuickBooks un asiento con las ventas del ${Dates.dmy(p.$2)} al ${Dates.dmy(p.$3)}.',
        bullets: [if (force) 'ATENCIÓN: ya existe un envío exitoso para parte de estas fechas.'],
        confirmLabel: force ? 'Sí, enviar duplicado' : 'Enviar',
        destructive: force);
    if (!ok) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    final r = await ref.read(syncPipelineProvider).runSync(
          from: p.$2,
          to: p.$3,
          trigger: SyncTrigger.manual,
          user: ref.read(sessionProvider)!.username,
          allowDuplicate: force,
        );
    ref.invalidate(setupStatusProvider);
    if (mounted) {
      setState(() {
        _busy = false;
        _result = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = rangePresets(ref.read(clockProvider)());
    final r = _result;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Steps([
        'Seleccione el rango de fechas.',
        'Revise el asiento generado (recomendado: "Revisar primero en Vista Previa").',
        'Confirme el envío a QuickBooks.',
      ]),
      const SizedBox(height: 12),
      TourTarget(
        id: 'sync:presets',
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < presets.length; i++)
            ChoiceChip(
              label: Text('${presets[i].$1} (${Dates.dmy(presets[i].$2)}'
                  '${presets[i].$2 == presets[i].$3 ? '' : ' – ${Dates.dmy(presets[i].$3)}'})'),
              selected: _preset == i,
              onSelected: (_) => setState(() => _preset = i),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (r != null)
        GuidanceBanner(
          kind: switch (r.status) {
            SyncStatus.success => GuidanceKind.success,
            SyncStatus.skipped => GuidanceKind.warning,
            _ => GuidanceKind.error,
          },
          title: switch (r.status) {
            SyncStatus.success => 'Sincronización exitosa: QuickBooks aceptó el asiento',
            SyncStatus.skipped => 'Sincronización omitida: el rango ya se había enviado',
            _ => 'Sincronización fallida: no se creó ningún asiento',
          },
          message: r.message,
          secondaryLabel: r.status == SyncStatus.failed ? 'Ver Historial' : null,
          onSecondary: r.status == SyncStatus.failed ? () => context.go(Routes.historial) : null,
          actionLabel: r.status == SyncStatus.skipped
              ? 'Sincronizar de todas formas'
              : (r.status == SyncStatus.failed ? 'Revisar en Vista Previa' : 'Ver Historial'),
          onAction: r.status == SyncStatus.skipped
              ? () => _run(force: true)
              : r.status == SyncStatus.failed
                  ? () => context.go(
                      '${Routes.vistaPrevia}?desde=${Dates.iso(presets[_preset].$2)}&hasta=${Dates.iso(presets[_preset].$3)}')
                  : () => context.go(Routes.historial),
        ),
      Align(
        alignment: Alignment.centerRight,
        child: TourTarget(
          id: 'sync:actions',
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
            OutlinedButton.icon(
              onPressed: () => context.go(
                  '${Routes.vistaPrevia}?desde=${Dates.iso(presets[_preset].$2)}&hasta=${Dates.iso(presets[_preset].$3)}'),
              icon: const Icon(Icons.find_in_page_outlined),
              label: const Text('Revisar primero en Vista Previa'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _run,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: Text(_busy ? 'Enviando…' : 'Sincronizar ahora'),
            ),
          ]),
        ),
      ),
    ]);
  }
}

/// Numbered instructions (guided pattern).
class _Steps extends StatelessWidget {
  const _Steps(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final rm = context.rm;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: rm.infoBg,
              child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: rm.infoText)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(items[i])),
          ]),
        ),
    ]);
  }
}

/// Result of the latest scheduled run (status + link to its detail).
class _LastScheduledRun extends ConsumerWidget {
  const _LastScheduledRun();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(syncHealthProvider).value?.lastScheduled;
    final t = Theme.of(context).textTheme;
    if (r == null) {
      return Text('Resultado de la última ejecución: todavía no se ha ejecutado.', style: t.bodyMedium);
    }
    return Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('Resultado de la última ejecución (${Dates.dmyHm(r.ranAt)}):', style: t.bodyMedium),
      SyncStatusChip(SyncStatus.parse(r.status)),
      TextButton(
        onPressed: () => showHistoryDetail(context, r),
        child: Text(SyncStatus.parse(r.status) == SyncStatus.failed ? 'Ver error' : 'Ver detalle'),
      ),
    ]);
  }
}

/// Schedule editor as a 3-step wizard with autosaved draft.
class ScheduleWizard extends ConsumerStatefulWidget {
  const ScheduleWizard({super.key, this.compact = false, this.onApplied});

  /// Single-form layout (used inside the setup assistant).
  final bool compact;
  final VoidCallback? onApplied;

  @override
  ConsumerState<ScheduleWizard> createState() => _ScheduleWizardState();
}

class _ScheduleWizardState extends ConsumerState<ScheduleWizard> {
  static const _draftKey = 'programacion';
  ScheduleDraft? _draft;
  bool _restored = false;
  bool _editing = false;
  ScheduleModel? _saved;

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  Future<void> _init(ScheduleModel? current) async {
    final d = ScheduleDraft(from: current);
    final j = await ref.read(draftStoreProvider).read(_draftKey);
    if (j != null) {
      d.applyJson(j);
      _restored = true;
      _editing = true;
    }
    d.addListener(() => ref.read(draftStoreProvider).save(_draftKey, d.toJson()));
    if (mounted) setState(() => _draft = d);
  }

  Future<void> _apply() async {
    final saved = await ref.read(scheduleRepositoryProvider).save(_draft!.toModel(), now: ref.read(clockProvider)());
    await ref.read(auditRepositoryProvider).log(ref.read(sessionProvider)!.username, 'ProgramacionActualizada',
        '${saved.description}; activa: ${saved.enabled ? 'sí' : 'no'}');
    await ref.read(draftStoreProvider).clear(_draftKey);
    ref.read(schedulerServiceProvider).poke();
    ref.invalidate(scheduleProvider);
    ref.invalidate(setupStatusProvider);
    setState(() {
      _saved = saved;
      _editing = false;
      _restored = false;
    });
    widget.onApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(scheduleProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin ?? false;
    if (current.isLoading) return const LoadingBox();
    if (_draft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_draft == null) _init(current.value);
      });
      return const LoadingBox();
    }
    final now = ref.read(clockProvider)();
    final d = _draft!;

    if (_saved != null) {
      return CompletionSummary(
        title: 'Programación guardada',
        items: [
          SummaryItem('Programación', _saved!.description),
          SummaryItem('Estado', _saved!.enabled ? 'Activa' : 'Desactivada'),
          if (_saved!.nextRunAt != null) SummaryItem('Próxima ejecución', Dates.dmyHm(_saved!.nextRunAt!)),
        ],
        nextActionLabel: 'Ir a Inicio',
        onNextAction: () => context.go(Routes.dashboard),
        secondaryLabel: 'Editar de nuevo',
        onSecondary: () => setState(() => _saved = null),
      );
    }

    final cur = current.value;
    if (widget.compact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FrequencyPicker(draft: d, enabled: isAdmin),
        TimeDayPicker(draft: d, enabled: isAdmin),
        const SizedBox(height: 12),
        ScheduleSummaryView(draft: d, now: now, enabled: isAdmin),
        if (isAdmin)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(onPressed: _apply, icon: const Icon(Icons.save), label: const Text('Aplicar programación')),
          ),
      ]);
    }

    if (!_editing) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (cur == null)
          const GuidanceBanner(
              kind: GuidanceKind.info,
              title: 'No hay programación',
              message: 'Programe un envío diario para no tener que hacerlo a mano.')
        else ...[
          // Active schedule reads as a green "Éxito" strip (visual guide).
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cur.enabled ? context.rm.successBg : context.rm.surfaceAlt,
              borderRadius: BorderRadius.circular(RmRadius.control),
              border: Border.all(color: cur.enabled ? context.rm.successIcon.withValues(alpha: 0.45) : context.rm.border),
            ),
            child: TextButtonTheme(
              data: TextButtonThemeData(
                style: Theme.of(context).textButtonTheme.style?.copyWith(
                      foregroundColor: WidgetStatePropertyAll(cur.enabled ? context.rm.successText : context.rm.link),
                    ),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(cur.enabled ? Icons.check_circle : Icons.alarm_off,
                color: cur.enabled ? context.rm.successIcon : context.rm.textSecondary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(cur.description, style: Theme.of(context).textTheme.titleSmall),
                  StatusChip(
                    label: cur.enabled ? 'Activa' : 'Desactivada',
                    tone: cur.enabled ? RmTone.success : RmTone.neutral,
                    icon: cur.enabled ? Icons.alarm_on : Icons.alarm_off,
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Próxima ejecución: ${cur.enabled && cur.nextRunAt != null ? Dates.dmyHm(cur.nextRunAt!) : '—'}'
                    '  ·  Ejecución anterior: ${cur.lastRunAt != null ? Dates.dmyHm(cur.lastRunAt!) : 'nunca'}'),
                const SizedBox(height: 4),
                const _LastScheduledRun(),
              ]),
            ),
          ]),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (isAdmin)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: Icon(cur == null ? Icons.add_alarm : Icons.edit_calendar),
              label: Text(cur == null ? 'Programar envíos' : 'Cambiar programación'),
            ),
          ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_restored)
        GuidanceBanner(
          kind: GuidanceKind.info,
          title: 'Se restauró un borrador sin aplicar',
          actionLabel: 'Descartar borrador',
          onAction: () async {
            await ref.read(draftStoreProvider).clear(_draftKey);
            _draft?.dispose();
            setState(() {
              _draft = null;
              _restored = false;
              _editing = false;
            });
          },
        ),
      StepWizard(
        completeLabel: 'Aplicar programación',
        onCancel: () => setState(() => _editing = false),
        steps: [
          WizardStep(
            title: 'Frecuencia',
            explanation: '¿Cada cuánto quiere enviar las ventas a QuickBooks?',
            example: 'La mayoría de las tiendas usa la frecuencia Diaria a las 23:00.',
            builder: (_) => FrequencyPicker(draft: d),
          ),
          WizardStep(
            title: 'Hora y día',
            explanation: 'Elija cuándo se ejecuta. Use una hora posterior al cierre.',
            instructions: const ['Elija la hora.', 'Si es semanal o mensual, elija también el día.'],
            builder: (_) => TimeDayPicker(draft: d),
          ),
          WizardStep(
            title: 'Resumen',
            explanation: 'Confirme qué se enviará y cuándo.',
            builder: (_) => ScheduleSummaryView(draft: d, now: now),
          ),
        ],
        onComplete: _apply,
      ),
    ]);
  }
}
