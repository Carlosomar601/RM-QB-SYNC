import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
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

    return PageBody(children: [
      ScreenHeader(
        icon: Icons.dashboard,
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
          final next = recommendedNextAction(s);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.flag_outlined, size: 32),
                title: const Text('Siguiente paso recomendado'),
                subtitle: Text('${next.label}\n${next.why}'),
                isThreeLine: true,
                trailing: FilledButton(onPressed: () => context.go(next.route), child: const Text('Ir')),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final cards = [
                _StatusTile(
                  icon: Icons.cloud_done_outlined,
                  title: 'QuickBooks Online',
                  ok: s.qboConnected,
                  value: s.qboConnected ? (s.companyName ?? 'Conectado') : 'No conectado',
                  route: Routes.configuracion,
                ),
                _StatusTile(
                  icon: Icons.point_of_sale,
                  title: 'API del POS',
                  ok: s.posConfigured,
                  value: s.posUrl ?? 'Sin configurar',
                  route: Routes.configuracion,
                ),
                _StatusTile(
                  icon: Icons.schedule,
                  title: 'Última sincronización',
                  ok: s.lastSyncAt != null,
                  value: s.lastSyncAt == null ? 'Nunca' : Dates.dmyHm(s.lastSyncAt!),
                  route: Routes.historial,
                ),
              ];
              return c.maxWidth > 900
                  ? Row(children: [for (final w in cards) Expanded(child: w)])
                  : Column(children: cards);
            }),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Lista de configuración',
              icon: Icons.checklist,
              subtitle: '${s.doneCount} de 5 completados',
              help: 'Los primeros cuatro puntos son necesarios para sincronizar. La programación es opcional.',
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
          error: (e, _) => Text('$e'),
          data: (rows) => rows.isEmpty
              ? const Text('Todavía no hay sincronizaciones. Empiece en Vista Previa.')
              : Column(children: [
                  for (final r in rows)
                    ListTile(
                      leading: StatusChip(SyncStatus.parse(r.status)),
                      title: Text('${Dates.dmy(r.fromDate)} al ${Dates.dmy(r.toDate)}'
                          '${r.qboJournalEntryId != null ? ' · Asiento #${r.qboJournalEntryId}' : ''}'),
                      subtitle: Text('${Dates.dmyHm(r.ranAt)} · ${SyncTrigger.parse(r.trigger).label} · ${r.performedBy}'
                          '${r.totalDebit != null ? ' · \$${Money.format(r.totalDebit!)}' : ''}'),
                      onTap: () => showHistoryDetail(context, r),
                    ),
                ]),
        ),
      ),
    ]);
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.icon, required this.title, required this.ok, required this.value, required this.route});
  final IconData icon;
  final String title;
  final bool ok;
  final String value;
  final String route;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF1B7F3B) : Theme.of(context).colorScheme.error;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(ok ? Icons.check_circle : Icons.error_outline, color: color, semanticLabel: ok ? 'Correcto' : 'Pendiente'),
        onTap: () => context.go(route),
      ),
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
            color: done ? const Color(0xFF1B7F3B) : Theme.of(context).colorScheme.outline,
            semanticLabel: done ? 'Completado' : 'Pendiente'),
        title: Text(label),
        trailing: done ? null : OutlinedButton(onPressed: () => context.go(route), child: const Text('Ir')),
      );
}
