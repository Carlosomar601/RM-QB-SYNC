import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../core/sync_rules.dart';
import '../../data/db/app_database.dart';
import '../../services/service_providers.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';
import '../history/historial_screen.dart';
import '../onboarding/tour.dart';

final recentHistoryProvider = StreamProvider<List<SyncHistoryRow>>(
  (ref) => ref.watch(historyRepositoryProvider).watchRecent(5),
);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // First visit: start the guided tour once per user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(tourProvider.notifier).startIfFirstTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(setupStatusProvider);
    final recent = ref.watch(recentHistoryProvider);
    final user = ref.watch(sessionProvider);

    final health = ref.watch(syncHealthProvider).value;

    return PageBody(children: [
      ScreenHeader(
        icon: Icons.dashboard_outlined,
        title: 'Hola, ${user?.displayName ?? ''}',
        purpose: 'Estado de la conexión con QuickBooks y el POS, y lo que falta por hacer.',
        nextHint: 'Siga el "Siguiente paso recomendado".',
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(setupStatusProvider);
              ref.invalidate(mappingsProvider);
              ref.invalidate(scheduleProvider);
            },
          ),
        ],
      ),
      status.when(
        loading: () => const LoadingBox(),
        error: (e, _) => GuidanceBanner(kind: GuidanceKind.error, title: 'No se pudo leer el estado', message: '$e'),
        data: (s) {
          final next = recommendedNextAction(s, health);
          final lastRun = health?.lastRun;
          final opensFailure = next.route == Routes.historial && lastRun != null && (health?.lastFailed ?? false);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TourTarget(
              id: 'inicio:next',
              child: _NextStepCard(
                label: next.label,
                why: next.why,
                actionLabel: opensFailure ? 'Ver el error' : 'Ir',
                onAction: opensFailure ? () => showHistoryDetail(context, lastRun) : () => context.go(next.route),
              ),
            ),
            const SizedBox(height: 12),
            TourTarget(
              id: 'inicio:status',
              child: LayoutBuilder(builder: (context, c) {
                final cards = [
                  _qboCard(s),
                  ConnectionStatusCard(
                    icon: Icons.point_of_sale_outlined,
                    title: 'Retail Manager POS',
                    tone: s.posConfigured ? RmTone.success : RmTone.danger,
                    stateLabel: s.posConfigured ? 'Configurado' : 'Pendiente',
                    value: s.posUrl ?? 'Sin configurar',
                    route: Routes.configuracion,
                  ),
                  _lastSyncCard(context, health),
                ];
                return c.maxWidth > 900
                    ? IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: cards[i]),
                          ],
                        ]),
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards);
              }),
            ),
            if (health != null && health.failuresSinceSuccess > 0 && lastRun != null) ...[
              const SizedBox(height: 6),
              GuidanceBanner(
                kind: GuidanceKind.error,
                title: health.failuresSinceSuccess == 1
                    ? 'La última sincronización falló'
                    : '${health.failuresSinceSuccess} sincronizaciones fallaron desde el último envío exitoso',
                message: health.lastSuccess == null
                    ? 'Todavía no hay ningún envío exitoso a QuickBooks. La configuración puede estar completa y aun así fallar el envío.'
                    : 'Último envío exitoso: ${Dates.dmyHm(health.lastSuccess!.ranAt)}.',
                actionLabel: 'Ver detalle del error',
                onAction: () => showHistoryDetail(context, lastRun),
                secondaryLabel: 'Abrir Historial',
                onSecondary: () => context.go(Routes.historial),
              ),
            ],
            const SizedBox(height: 12),
            SectionCard(
              title: 'Configuración',
              icon: Icons.checklist,
              subtitle: '${s.doneCount} de 5 completados',
              help: 'Lo necesario para poder sincronizar. Que esté completa no garantiza que los envíos funcionen: '
                  'el resultado de cada envío se ve en "Última sincronización" y en Historial.',
              child: Column(children: [
                _Check('API del POS configurada', s.posConfigured, Routes.configuracion),
                _Check('Credenciales de Intuit guardadas', s.qboCredentials, Routes.configuracion),
                _Check('QuickBooks conectado', s.qboConnected, Routes.configuracion),
                _Check('Mapeo de cuentas completo (${s.mappedCount}/${s.totalCategories})', s.mappingsComplete, Routes.mapeo),
                _Check('Sincronización programada (opcional)', s.scheduleEnabled, Routes.sincronizaciones),
              ]),
            ),
          ]);
        },
      ),
      SectionCard(
        title: 'Sincronizaciones recientes',
        icon: Icons.history,
        trailing: TextButton(onPressed: () => context.go(Routes.historial), child: const Text('Ver todas')),
        child: recent.when(
          loading: () => const LoadingBox(),
          error: (e, _) => GuidanceBanner(kind: GuidanceKind.error, title: 'No se pudo leer el historial', message: '$e'),
          data: (rows) => rows.isEmpty
              ? EmptyState(
                  icon: Icons.history,
                  title: 'Todavía no hay sincronizaciones',
                  message: 'Revise un rango en Vista Previa y envíelo a QuickBooks. El resultado aparecerá aquí.',
                  actions: [OutlinedButton(onPressed: () => context.go(Routes.vistaPrevia), child: const Text('Ir a Vista Previa'))],
                )
              : Column(children: [
                  for (final r in rows)
                    ListTile(
                      leading: SyncStatusChip(SyncStatus.parse(r.status)),
                      title: Text('${Dates.dmy(r.fromDate)} al ${Dates.dmy(r.toDate)}'
                          '${r.qboJournalEntryId != null ? ' · Asiento #${r.qboJournalEntryId}' : ''}'),
                      subtitle: Text('${Dates.dmyHm(r.ranAt)} · ${SyncTrigger.parse(r.trigger).label} · ${r.performedBy}'),
                      trailing: r.totalDebit == null ? null : MoneyText(r.totalDebit!),
                      onTap: () => showHistoryDetail(context, r),
                    ),
                ]),
        ),
      ),
    ]);
  }

  Widget _qboCard(SetupStatus s) {
    final exp = s.authExpiresAt;
    final days = exp?.difference(DateTime.now()).inDays;
    final (tone, label) = !s.qboConnected
        ? (RmTone.danger, 'No conectado')
        : days != null && days < 0
            ? (RmTone.danger, 'Autorización vencida')
            : days != null && days <= 14
                ? (RmTone.warning, 'Vence en $days día(s)')
                : (RmTone.success, 'Conectado');
    return ConnectionStatusCard(
      icon: Icons.cloud_outlined,
      title: 'QuickBooks Online',
      tone: tone,
      stateLabel: label,
      value: s.qboConnected ? (s.companyName ?? 'Conectado') : 'No conectado',
      detail: s.qboConnected ? 'Ambiente: ${s.isProduction ? 'Producción' : 'Sandbox (pruebas)'}' : null,
      route: Routes.configuracion,
    );
  }

  /// Truthful last-sync status: the actual result of the latest run, not just
  /// a timestamp.
  Widget _lastSyncCard(BuildContext context, SyncHealth? h) {
    final r = h?.lastRun;
    if (h == null || r == null) {
      return const ConnectionStatusCard(
        icon: Icons.schedule,
        title: 'Última sincronización',
        tone: RmTone.warning,
        stateLabel: 'Sin ejecutar',
        value: 'Nunca',
        detail: 'Aún no se ha enviado nada a QuickBooks.',
        route: Routes.vistaPrevia,
      );
    }
    final st = SyncStatus.parse(r.status);
    final tone = switch (st) {
      SyncStatus.success => RmTone.success,
      SyncStatus.failed => RmTone.danger,
      SyncStatus.skipped => RmTone.warning,
      SyncStatus.running => RmTone.info,
    };
    final success = h.lastSuccess;
    return ConnectionStatusCard(
      icon: Icons.schedule,
      title: 'Última sincronización',
      tone: tone,
      stateLabel: st.label,
      value: Dates.dmyHm(r.ranAt),
      detail: st == SyncStatus.success
          ? '${SyncTrigger.parse(r.trigger).label}${r.qboJournalEntryId != null ? ' · Asiento #${r.qboJournalEntryId}' : ''}'
          : (success == null ? 'Ningún envío exitoso todavía' : 'Último exitoso: ${Dates.dmyHm(success.ranAt)}'),
      onTap: () => showHistoryDetail(context, r),
    );
  }
}

/// Recommended next step: soft guidance surface, not a saturated panel.
class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.label, required this.why, required this.actionLabel, required this.onAction});
  final String label;
  final String why;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final rm = context.rm;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: rm.surfaceGuide,
        borderRadius: BorderRadius.circular(RmRadius.card),
        border: Border.all(color: rm.focus.withValues(alpha: 0.45)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.flag_outlined, size: 26, color: rm.link),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Siguiente paso recomendado', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: t.titleSmall),
            const SizedBox(height: 4),
            Text(why, style: t.bodyMedium?.copyWith(color: rm.textSecondary)),
          ]),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.arrow_forward), label: Text(actionLabel)),
      ]),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check(this.label, this.done, this.route);
  final String label;
  final bool done;
  final String route;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? context.rm.successIcon : context.rm.textMuted,
            semanticLabel: done ? 'Completado' : 'Pendiente'),
        title: Text(label),
        trailing: done ? null : OutlinedButton(onPressed: () => context.go(route), child: const Text('Ir')),
      );
}
