import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../core/money.dart';
import 'status_chip.dart';

/// Tabular figures so columns of amounts line up digit by digit.
const tabularFigures = [FontFeature.tabularFigures()];

/// Monetary amount: "$1,234.56", tabular figures, right aligned by default.
class MoneyText extends StatelessWidget {
  const MoneyText(this.amount, {super.key, this.style, this.align = TextAlign.right, this.prefix = r'$'});

  final num amount;
  final TextStyle? style;
  final TextAlign align;
  final String prefix;

  @override
  Widget build(BuildContext context) => Text(
        '$prefix${Money.format(amount)}',
        textAlign: align,
        style: (style ?? DefaultTextStyle.of(context).style).copyWith(fontFeatures: tabularFigures),
      );
}

/// Deliberate empty state: icon, short explanation and real actions only.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.actions = const []});

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final rm = context.rm;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: rm.navSelected, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: rm.link),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: t.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(message!, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: rm.textSecondary)),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Connection / status card for the dashboard: what it is, its current
/// value, and a status pill (icon + text). Tapping opens [route].
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
    required this.stateLabel,
    this.detail,
    this.route,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? detail;
  final RmTone tone;
  final String stateLabel;
  final String? route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rm = context.rm;
    final t = Theme.of(context).textTheme;
    final tap = onTap ?? (route == null ? null : () => context.go(route!));
    // Problems tint the whole card (as in the visual guide); healthy cards
    // stay on the surface and let the status pill carry the color.
    final alert = tone == RmTone.danger || tone == RmTone.warning;
    final c = rm.tone(tone);
    final fg = alert ? c.fg : rm.textPrimary;
    final fg2 = alert ? c.fg : rm.textSecondary;
    return Card(
      color: alert ? c.bg : null,
      shape: alert
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RmRadius.card),
              side: BorderSide(color: c.icon.withValues(alpha: 0.5)),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(RmRadius.card),
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 22, color: alert ? c.icon : rm.link),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: t.titleSmall?.copyWith(color: fg))),
              ]),
              const SizedBox(height: 10),
              Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleMedium?.copyWith(color: fg)),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(detail!, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: fg2)),
              ],
              const SizedBox(height: 10),
              StatusChip(label: stateLabel, tone: tone),
            ],
          ),
        ),
      ),
    );
  }
}

/// Failure explanation: what happened, the authoritative message, and the
/// recovery actions. Never colors a whole screen — only this panel.
class ErrorDetailPanel extends StatelessWidget {
  const ErrorDetailPanel({
    super.key,
    required this.title,
    required this.message,
    this.hint,
    this.actions = const [],
    this.tone = RmTone.danger,
  });

  final String title;
  final String message;
  final String? hint;
  final List<Widget> actions;
  final RmTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.rm.tone(tone);
    return Semantics(
      container: true,
      label: tone == RmTone.danger ? 'Error' : 'Aviso',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(RmRadius.control),
          border: Border.all(color: c.icon.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(tone == RmTone.danger ? Icons.error_outline : Icons.warning_amber_rounded, color: c.icon, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: c.fg, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            SelectableText(message, style: TextStyle(color: c.fg)),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(hint!, style: TextStyle(color: c.fg, fontStyle: FontStyle.italic)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
