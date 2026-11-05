import 'package:flutter/material.dart';

import '../../app/tokens.dart';

/// Small ⓘ icon with a tooltip; also announced by screen readers.
class HelpTip extends StatelessWidget {
  const HelpTip(this.message, {super.key, this.size = 18});

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ayuda: $message',
      excludeSemantics: true,
      child: Tooltip(
        message: message,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 8),
        waitDuration: const Duration(milliseconds: 250),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.help_outline, size: size, color: context.rm.infoIcon),
        ),
      ),
    );
  }
}

/// Field label with required marker and optional help tip.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false, this.help});

  final String text;
  final bool required;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final rm = context.rm;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: Theme.of(context).textTheme.labelLarge),
        if (required)
          Semantics(
            label: 'obligatorio',
            child: Text(' *', style: TextStyle(color: rm.dangerText, fontWeight: FontWeight.w600)),
          ),
        if (help != null) HelpTip(help!, size: 16),
      ],
    );
  }
}
