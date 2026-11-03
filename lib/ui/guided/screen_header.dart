import 'package:flutter/material.dart';

/// "¿Dónde estoy? / ¿Qué hago aquí? / ¿Qué sigue?" header for every screen.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.purpose,
    this.nextHint,
    this.icon,
    this.actions = const [],
  });

  final String title;

  /// What the user does here (one line).
  final String purpose;

  /// What comes next.
  final String? nextHint;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 30, color: cs.primary), const SizedBox(width: 12)],
              Expanded(child: Semantics(header: true, child: Text(title, style: t.headlineSmall))),
              ...actions,
            ],
          ),
          const SizedBox(height: 6),
          Text(purpose, style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
          if (nextHint != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('Qué sigue: $nextHint',
                      style: t.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrollable page body with consistent padding and max width.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1200});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final pad = c.maxWidth < 700 ? 12.0 : 24.0;
      return SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      );
    });
  }
}
