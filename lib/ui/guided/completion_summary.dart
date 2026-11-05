import 'package:flutter/material.dart';

import '../../app/tokens.dart';

class SummaryItem {
  const SummaryItem(this.label, this.value);
  final String label;
  final String value;
}

/// Shown at the end of a workflow: what changed + the next recommended action.
class CompletionSummary extends StatelessWidget {
  const CompletionSummary({
    super.key,
    required this.title,
    required this.items,
    this.success = true,
    this.message,
    this.nextActionLabel,
    this.onNextAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? message;
  final List<SummaryItem> items;
  final bool success;
  final String? nextActionLabel;
  final VoidCallback? onNextAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final tone = context.rm.tone(success ? RmTone.success : RmTone.danger);
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(success ? Icons.check_circle_outline : Icons.error_outline, color: tone.icon, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: t.headlineSmall?.copyWith(color: tone.fg))),
              ]),
              if (message != null) ...[const SizedBox(height: 12), SelectableText(message!, style: t.bodyLarge)],
              if (items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                  children: [
                    for (final i in items)
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16, bottom: 6),
                          child: Text(i.label, style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SelectableText(i.value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ]),
                  ],
                ),
              ],
              if (nextActionLabel != null || secondaryLabel != null) ...[
                const SizedBox(height: 16),
                Text('Siguiente paso recomendado', style: t.labelLarge),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (nextActionLabel != null)
                    FilledButton.icon(
                        autofocus: true,
                        onPressed: onNextAction,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(nextActionLabel!)),
                  if (secondaryLabel != null) OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
