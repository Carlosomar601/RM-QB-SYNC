import 'package:flutter/material.dart';

import '../../app/tokens.dart';

/// Status pill: tinted background + icon + text. Never color alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone, this.icon, this.tooltip});

  final String label;
  final RmTone tone;
  final IconData? icon;
  final String? tooltip;

  static IconData defaultIcon(RmTone tone) => switch (tone) {
        RmTone.success => Icons.check_circle_outline,
        RmTone.warning => Icons.warning_amber_rounded,
        RmTone.danger => Icons.error_outline,
        RmTone.info => Icons.schedule,
        RmTone.neutral => Icons.radio_button_unchecked,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.rm.tone(tone);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(RmRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon ?? defaultIcon(tone), size: 16, color: c.icon),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.fg)),
        ),
      ]),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}
