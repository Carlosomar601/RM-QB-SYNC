import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/service_providers.dart';
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
      length: 3,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child:
        ScreenHeader(
          icon: Icons.help,
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
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Abrir asistente de configuración'),
              ),
          ],
        ),
        ),
        const TabBar(isScrollable: true, tabs: [
          Tab(icon: Icon(Icons.bolt), text: 'Referencia rápida'),
          Tab(icon: Icon(Icons.school_outlined), text: 'Tutoriales'),
          Tab(icon: Icon(Icons.quiz_outlined), text: 'Preguntas frecuentes'),
        ]),
        Expanded(
          child: TabBarView(children: [
            _QuickReference(),
            _Tutorials(),
            _Faq(),
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
