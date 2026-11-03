import 'package:flutter/material.dart';

import 'help_tip.dart';

/// Titled card used to group related controls.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.help,
    this.icon,
    this.trailing,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final String? help;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
              Flexible(child: Semantics(header: true, child: Text(title, style: t.titleLarge))),
              if (help != null) HelpTip(help!),
              const Spacer(),
              ?trailing,
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Progressive disclosure: hides advanced options until requested.
class AdvancedOptions extends StatelessWidget {
  const AdvancedOptions({super.key, required this.children, this.title = 'Opciones avanzadas', this.initiallyExpanded = false});

  final List<Widget> children;
  final String title;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: initiallyExpanded,
        leading: const Icon(Icons.tune),
        title: Text(title),
        subtitle: const Text('Solo si su técnico se lo indica'),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: children,
      ),
    );
  }
}

/// Generic loading / error wrapper for async values.
class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key, this.message = 'Cargando…'});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: 12),
          Text(message),
        ]),
      );
}
