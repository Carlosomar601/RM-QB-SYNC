import 'package:flutter/material.dart';

enum GuidanceKind { info, success, warning, error }

/// Inline message with an optional "how to fix" action.
class GuidanceBanner extends StatelessWidget {
  const GuidanceBanner({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final GuidanceKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, icon, semantic) = switch (kind) {
      GuidanceKind.info => (cs.secondaryContainer, cs.onSecondaryContainer, Icons.lightbulb_outline, 'Información'),
      GuidanceKind.success => (const Color(0xFFDDF3E4), const Color(0xFF0B4F25), Icons.check_circle_outline, 'Éxito'),
      GuidanceKind.warning => (const Color(0xFFFFF1CC), const Color(0xFF5C4300), Icons.warning_amber_rounded, 'Advertencia'),
      GuidanceKind.error => (cs.errorContainer, cs.onErrorContainer, Icons.error_outline, 'Error'),
    };
    return Semantics(
      container: true,
      liveRegion: kind == GuidanceKind.error || kind == GuidanceKind.success,
      label: semantic,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                  if (message != null) ...[
                    const SizedBox(height: 4),
                    SelectableText(message!, style: TextStyle(color: fg)),
                  ],
                  if (actionLabel != null || secondaryLabel != null) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      if (actionLabel != null)
                        FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
                      if (secondaryLabel != null)
                        TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
