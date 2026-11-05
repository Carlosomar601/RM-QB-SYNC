import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_state.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/sync_rules.dart';
import '../../services/app_paths.dart';
import '../../services/service_providers.dart';
import '../../ui/brand.dart';
import '../../ui/guided/guided.dart';
import '../onboarding/tour.dart';
import 'help_content.dart';
import 'help_panel.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(sessionProvider)?.isAdmin ?? false;
    return DefaultTabController(
      length: 5,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child:
        ScreenHeader(
          icon: Icons.help_outline,
          title: 'Centro de Ayuda',
          purpose: 'Referencia rápida, tutoriales paso a paso y soluciones a problemas comunes.',
          nextHint: 'Presione F1 en cualquier pantalla para ver su ayuda específica.',
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                ref.read(tourProvider.notifier).restart();
                context.go(Routes.dashboard);
              },
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Reiniciar recorrido guiado'),
            ),
            const SizedBox(width: 8),
            if (isAdmin)
              FilledButton.icon(
                onPressed: () => context.go(Routes.asistente),
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Abrir asistente de configuración'),
              ),
          ],
        ),
        ),
        const TourTarget(
          id: 'ayuda:tabs',
          child: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
            Tab(icon: Icon(Icons.bolt), text: 'Referencia rápida'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Tutoriales'),
            Tab(icon: Icon(Icons.quiz_outlined), text: 'Preguntas frecuentes'),
            Tab(icon: Icon(Icons.build_outlined), text: 'Solución de problemas'),
            Tab(icon: Icon(Icons.info_outline), text: 'Acerca de'),
          ]),
        ),
        Expanded(
          child: TabBarView(children: [
            _QuickReference(),
            _Tutorials(),
            _Faq(),
            const _Troubleshooting(),
            const _About(),
          ]),
        ),
      ]),
    );
  }
}

class _Defs extends StatelessWidget {
  const _Defs(this.title, this.items);
  final String title;
  final List<GlossaryEntry> items;

  @override
  Widget build(BuildContext context) => SectionCard(
        title: title,
        child: Column(children: [
          for (final g in items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(g.term, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(g.definition),
            ),
        ]),
      );
}

class _QuickReference extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _Defs('Secciones de la aplicación', HelpContent.features),
          const _Defs('Glosario', HelpContent.glossary),
          const _Defs('Botones e iconos', HelpContent.buttons),
          const _Defs('Atajos de teclado', HelpContent.shortcuts),
          SectionCard(
            title: 'Ayuda por pantalla',
            child: Column(children: [
              for (final e in HelpContent.screens.entries)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(e.value.title),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  children: [HelpArticleView(article: e.value, closeDrawerOnLink: false)],
                ),
            ]),
          ),
        ],
      );
}

class _Tutorials extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final t in HelpContent.tutorials)
            SectionCard(
              title: t.title,
              icon: Icons.school_outlined,
              child: HelpArticleView(article: t, closeDrawerOnLink: false),
            ),
        ],
      );
}

/// Live diagnosis (from the real app state) + known problems with fixes.
class _Troubleshooting extends ConsumerWidget {
  const _Troubleshooting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(setupStatusProvider).value;
    final h = ref.watch(syncHealthProvider).value;
    Widget check(String label, bool? ok, String okText, String badText, String route) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (ok == null)
              const StatusChip(label: 'Leyendo…', tone: RmTone.neutral)
            else
              StatusChip(label: ok ? okText : badText, tone: ok ? RmTone.success : RmTone.danger),
            if (ok == false) TextButton(onPressed: () => context.go(route), child: const Text('Resolver')),
          ]),
        );
    final last = h?.lastStatus;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Diagnóstico rápido',
          icon: Icons.monitor_heart_outlined,
          subtitle: 'Estado actual de esta instalación. Empiece por lo que esté en rojo.',
          child: Column(children: [
            check('API del POS', s?.posConfigured, 'Configurada', 'Sin configurar', Routes.configuracion),
            check('QuickBooks', s?.qboConnected, 'Conectado', 'No conectado', Routes.configuracion),
            check('Mapeo de cuentas', s?.mappingsComplete, 'Completo', 'Incompleto', Routes.mapeo),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Última sincronización'),
              subtitle: h?.lastRun == null ? null : Text(Dates.dmyHm(h!.lastRun!.ranAt)),
              trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                StatusChip(
                  label: last?.label ?? 'Nunca',
                  tone: switch (last) {
                    SyncStatus.success => RmTone.success,
                    SyncStatus.failed => RmTone.danger,
                    null => RmTone.warning,
                    _ => RmTone.warning,
                  },
                ),
                if (last == SyncStatus.failed)
                  TextButton(onPressed: () => context.go(Routes.historial), child: const Text('Ver error')),
              ]),
            ),
          ]),
        ),
        SectionCard(
          title: 'Problemas comunes',
          icon: Icons.build_outlined,
          child: Column(children: [
            for (final f in HelpContent.faq.where((f) => f.fix != null))
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: Icon(Icons.report_problem_outlined, color: context.rm.warningIcon),
                title: Text(f.question),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Causa: ${f.answer}'),
                  const SizedBox(height: 6),
                  Text('Qué hacer: ${f.fix}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (f.link != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go(f.link!.route),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text('Ir a ${f.link!.label}'),
                      ),
                    ),
                ],
              ),
          ]),
        ),
        for (final t in HelpContent.tutorials.where((t) => t.id == 't-imbalance'))
          SectionCard(
            title: t.title,
            icon: Icons.balance_outlined,
            child: HelpArticleView(article: t, closeDrawerOnLink: false),
          ),
      ],
    );
  }
}

/// Product identity, version and where data lives.
class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const BrandHeader(subtitle: 'Ventas del POS Retail Manager → QuickBooks Online'),
                  const SizedBox(height: 16),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snap) => Text(
                      'Versión ${snap.data?.version ?? '—'}${(snap.data?.buildNumber ?? '').isEmpty ? '' : ' (compilación ${snap.data!.buildNumber})'}',
                      textAlign: TextAlign.center,
                      style: t.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('© Retail Manager', textAlign: TextAlign.center, style: t.bodySmall),
                ]),
              ),
            ),
          ),
        ),
        SectionCard(
          title: 'Datos de la aplicación',
          icon: Icons.folder_outlined,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Base de datos, registros y copias de seguridad se guardan en:'),
            const SizedBox(height: 4),
            SelectableText(AppPaths.dataDir, style: const TextStyle(fontFamily: 'Consolas')),
            const SizedBox(height: 8),
            const Text('Las credenciales de Intuit y las claves se guardan cifradas en Windows y nunca se muestran.'),
          ]),
        ),
        const SectionCard(
          title: 'Soporte',
          icon: Icons.support_agent_outlined,
          child: Text('Antes de contactar a soporte, revise "Solución de problemas". Si necesita ayuda, '
              'indique la versión y el número de la sincronización (Historial) que falló.'),
        ),
        Text('${AppInfo.displayName} no está afiliado a Intuit. QuickBooks es una marca de Intuit Inc.',
            textAlign: TextAlign.center, style: t.bodySmall),
      ],
    );
  }
}

class _Faq extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Column(children: [
              for (final f in HelpContent.faq)
                ExpansionTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(f.question),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Causa: ${f.answer}'),
                    if (f.fix != null) ...[const SizedBox(height: 6), Text('Solución: ${f.fix}')],
                    if (f.link != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.go(f.link!.route),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text('Ir a ${f.link!.label}'),
                        ),
                      ),
                  ],
                ),
            ]),
          ),
        ],
      );
}
