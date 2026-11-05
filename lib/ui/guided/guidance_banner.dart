import 'package:flutter/material.dart';

import '../../app/tokens.dart';

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
    final (tone, icon, semantic) = switch (kind) {
      GuidanceKind.info => (RmTone.info, Icons.lightbulb_outline, 'Información'),
      GuidanceKind.success => (RmTone.success, Icons.check_circle_outline, 'Éxito'),
      GuidanceKind.warning => (RmTone.warning, Icons.warning_amber_rounded, 'Advertencia'),
      GuidanceKind.error => (RmTone.danger, Icons.error_outline, 'Error'),
    };
    final c = context.rm.tone(tone);
    final fg = c.fg;
    return Semantics(
      container: true,
      liveRegion: kind == GuidanceKind.error || kind == GuidanceKind.success,
      label: semantic,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(RmRadius.control),
          border: Border.all(color: c.icon.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.icon, size: 20),
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
                        TextButton(
                          // Link color would not be AA on every status tint; use the banner text color.
                          style: TextButton.styleFrom(foregroundColor: fg),
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!, style: const TextStyle(decoration: TextDecoration.underline)),
                        ),
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
