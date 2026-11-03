import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'help_content.dart';

/// Contextual help drawer; opening it never loses the screen's state.
class HelpPanel extends StatelessWidget {
  const HelpPanel({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final a = HelpContent.forRoute(location);
    final t = Theme.of(context).textTheme;
    return Drawer(
      width: 420,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text('Ayuda: ${a.title}', style: t.titleMedium),
              trailing: IconButton(
                tooltip: 'Cerrar ayuda (Esc)',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  HelpArticleView(article: a),
                  const Divider(height: 32),
                  Text('Más ayuda', style: t.titleSmall),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('Abrir Centro de Ayuda completo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(Routes.ayuda);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpArticleView extends StatelessWidget {
  const HelpArticleView({super.key, required this.article, this.closeDrawerOnLink = true});
  final HelpArticle article;
  final bool closeDrawerOnLink;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(article.summary, style: t.bodyLarge),
        for (final s in article.sections) ...[
          const SizedBox(height: 14),
          Semantics(header: true, child: Text(s.heading, style: t.titleSmall)),
          const SizedBox(height: 4),
          for (final p in s.paragraphs) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(p)),
        ],
        if (article.steps.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (var i = 0; i < article.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 11, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 10),
                Expanded(child: Text(article.steps[i])),
              ]),
            ),
        ],
        if (article.links.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in article.links)
              ActionChip(
                avatar: const Icon(Icons.arrow_forward, size: 16),
                label: Text('Ir a: ${l.label}'),
                onPressed: () {
                  final router = GoRouter.of(context);
                  if (closeDrawerOnLink && Scaffold.maybeOf(context)?.isEndDrawerOpen == true) {
                    Navigator.of(context).pop();
                  }
                  router.go(l.route);
                },
              ),
          ]),
        ],
      ],
    );
  }
}
