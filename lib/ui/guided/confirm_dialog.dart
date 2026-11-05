import 'package:flutter/material.dart';

import '../../app/tokens.dart';

/// Confirmation for consequential or irreversible actions.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
  List<String> bullets = const [],
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final rm = ctx.rm;
      return AlertDialog(
        icon: Icon(destructive ? Icons.warning_amber_rounded : Icons.help_outline,
            color: destructive ? rm.dangerIcon : rm.infoIcon),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (bullets.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final b in bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('•  '),
                      Expanded(child: Text(b)),
                    ]),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
          FilledButton(
            autofocus: true,
            style: destructive
                ? ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.hovered)
                        ? Color.lerp(rm.dangerIcon, rm.textPrimary, 0.12)
                        : rm.dangerIcon),
                    foregroundColor: WidgetStatePropertyAll(Theme.of(ctx).colorScheme.onError),
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return r ?? false;
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final rm = context.rm;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: error
          ? Row(children: [
              Icon(Icons.error_outline, color: rm.dangerText, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: TextStyle(color: rm.dangerText))),
            ])
          : Text(message),
      backgroundColor: error ? rm.dangerBg : null,
      closeIconColor: error ? rm.dangerText : null,
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      duration: Duration(seconds: error ? 8 : 4),
    ));
}
