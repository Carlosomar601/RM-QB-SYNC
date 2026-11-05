import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/tokens.dart';

/// One step of a [StepWizard].
class WizardStep {
  const WizardStep({
    required this.title,
    required this.explanation,
    required this.builder,
    this.instructions = const [],
    this.example,
    this.validate,
    this.optional = false,
    this.nextLabel,
    this.blockedReason,
  });

  final String title;

  /// Short explanation of what this step is for.
  final String explanation;

  /// Exact instructions ("Escriba…", "Seleccione…").
  final List<String> instructions;

  /// Helpful example or recommended selection.
  final String? example;

  final WidgetBuilder builder;

  /// Returns the list of missing/invalid items; empty → can continue.
  final List<String> Function()? validate;

  final bool optional;

  /// Overrides the "Siguiente" label for this step.
  final String? nextLabel;

  /// When set, the step is shown as blocked (lock icon) in the progress bar
  /// and this reason is given as its tooltip, e.g. "Primero conecte QuickBooks".
  final String? blockedReason;
}

/// Sequential, validated workflow with progress, Back/Next/Complete and
/// state preserved when going back (step widgets stay alive in an
/// [IndexedStack]). Ctrl+Enter = Siguiente.
class StepWizard extends StatefulWidget {
  const StepWizard({
    super.key,
    required this.steps,
    required this.onComplete,
    this.completeLabel = 'Completar',
    this.onStepChanged,
    this.initialStep = 0,
    this.onCancel,
    this.cancelLabel = 'Cancelar',
    this.busy = false,
  });

  final List<WizardStep> steps;

  /// Called on the last step after validation. May be async.
  final Future<void> Function() onComplete;
  final String completeLabel;
  final void Function(int step)? onStepChanged;
  final int initialStep;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final bool busy;

  @override
  State<StepWizard> createState() => StepWizardState();
}

class StepWizardState extends State<StepWizard> {
  late int _index = widget.initialStep.clamp(0, widget.steps.length - 1);
  List<String> _problems = const [];
  bool _working = false;

  /// The current step failed validation (shown as an error in the stepper
  /// until it validates or the user moves).
  bool _failed = false;

  int get index => _index;

  void goTo(int i) {
    if (i < 0 || i >= widget.steps.length) return;
    setState(() {
      _index = i;
      _problems = const [];
      _failed = false;
    });
    widget.onStepChanged?.call(i);
  }

  bool _validateCurrent() {
    final v = widget.steps[_index].validate;
    final problems = v == null ? const <String>[] : v();
    setState(() {
      _problems = problems;
      _failed = problems.isNotEmpty;
    });
    return problems.isEmpty;
  }

  Future<void> next() async {
    if (_working || widget.busy) return;
    if (!_validateCurrent()) return;
    if (_index < widget.steps.length - 1) {
      goTo(_index + 1);
      return;
    }
    setState(() => _working = true);
    try {
      await widget.onComplete();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void back() => goTo(_index - 1);

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final step = steps[_index];
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isLast = _index == steps.length - 1;
    final busy = _working || widget.busy;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): next,
      },
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Progress(steps: steps, index: _index, failed: _failed, onTap: (i) {
              if (i < _index) goTo(i); // only allow jumping back
            }),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text('Paso ${_index + 1} de ${steps.length}: ${step.title}', style: t.titleLarge),
                    ),
                    const SizedBox(height: 6),
                    Text(step.explanation, style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                    if (step.instructions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (var i = 0; i < step.instructions.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            CircleAvatar(
                                radius: 10,
                                backgroundColor: context.rm.infoBg,
                                child: Text('${i + 1}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.rm.infoText))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(step.instructions[i])),
                          ]),
                        ),
                    ],
                    if (step.example != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.rm.surfaceGuide,
                          borderRadius: BorderRadius.circular(RmRadius.control),
                        ),
                        child: Row(children: [
                          Icon(Icons.tips_and_updates_outlined, size: 18, color: context.rm.infoIcon),
                          const SizedBox(width: 8),
                          Expanded(child: Text(step.example!, style: t.bodyMedium)),
                        ]),
                      ),
                    ],
                    const Divider(height: 32),
                    // Offstage keeps every step's state alive (Atrás never loses data)
                    // while only the current one takes space.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          Offstage(
                            offstage: i != _index,
                            child: TickerMode(
                              enabled: i == _index,
                              child: ExcludeFocus(
                                excluding: i != _index,
                                child: Builder(builder: steps[i].builder),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_problems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.rm.dangerBg,
                            borderRadius: BorderRadius.circular(RmRadius.control),
                            border: Border.all(color: context.rm.dangerIcon.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Antes de continuar, complete lo siguiente:',
                                  style: TextStyle(color: context.rm.dangerText, fontWeight: FontWeight.w600)),
                              for (final p in _problems)
                                Text('• $p', style: TextStyle(color: context.rm.dangerText)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Wrap(spacing: 8, children: [
                  if (widget.onCancel != null)
                    TextButton(onPressed: busy ? null : widget.onCancel, child: Text(widget.cancelLabel)),
                  OutlinedButton.icon(
                    onPressed: _index == 0 || busy ? null : back,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Atrás'),
                  ),
                ]),
                Tooltip(
                  message: 'Ctrl+Enter',
                  child: FilledButton.icon(
                    onPressed: busy ? null : next,
                    icon: busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(isLast ? Icons.check : Icons.arrow_forward),
                    label: Text(isLast ? widget.completeLabel : (step.nextLabel ?? 'Siguiente')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Coherent progress stepper: completed = check, current = filled number,
/// upcoming = outlined number (subdued but readable). Completed steps can be
/// revisited by clicking them.
class _Progress extends StatelessWidget {
  const _Progress({required this.steps, required this.index, required this.failed, required this.onTap});

  final List<WizardStep> steps;
  final int index;
  final bool failed;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progreso: paso ${index + 1} de ${steps.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: (index + 1) / steps.length, minHeight: 4, borderRadius: BorderRadius.circular(2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _StepItem(
                  number: i + 1,
                  title: steps[i].title,
                  optional: steps[i].optional,
                  state: switch (i) {
                    _ when i < index => _StepState.done,
                    _ when i == index => failed ? _StepState.error : _StepState.current,
                    _ when steps[i].blockedReason != null => _StepState.blocked,
                    _ => _StepState.upcoming,
                  },
                  reason: i > index ? steps[i].blockedReason : null,
                  onTap: i < index ? () => onTap(i) : null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// done = check, current = filled number, error = current step with problems,
/// upcoming = outlined number, blocked = lock with a reason tooltip.
enum _StepState { done, current, error, upcoming, blocked }

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.title,
    required this.optional,
    required this.state,
    this.reason,
    this.onTap,
  });

  final String? reason;

  final int number;
  final String title;
  final bool optional;
  final _StepState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rm = context.rm;
    final t = Theme.of(context).textTheme;
    // Pills as in the visual guide: current = filled Primario, done = Éxito,
    // error = Peligro, upcoming = outlined, blocked = grey with a lock.
    final (Color bg, Color fg, Color border, FontWeight weight) = switch (state) {
      _StepState.done => (rm.successBg, rm.successText, rm.successIcon.withValues(alpha: 0.45), FontWeight.w600),
      _StepState.current => (rm.interactive, rm.onInteractive, rm.interactive, FontWeight.w600),
      _StepState.error => (rm.dangerBg, rm.dangerText, rm.dangerIcon, FontWeight.w600),
      _StepState.upcoming => (rm.surface, rm.textSecondary, rm.border, FontWeight.w500),
      _StepState.blocked => (rm.surfaceAlt, rm.textSecondary, rm.border, FontWeight.w500),
    };
    final stateLabel = switch (state) {
      _StepState.done => 'completado',
      _StepState.current => 'actual',
      _StepState.error => 'actual, con datos por corregir',
      _StepState.upcoming => 'pendiente',
      _StepState.blocked => 'bloqueado${reason == null ? '' : ': $reason'}',
    };
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RmRadius.control),
        border: Border.all(color: border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          switch (state) {
            _StepState.done => Icons.check_circle,
            _StepState.current => Icons.radio_button_checked,
            _StepState.error => Icons.error,
            _StepState.blocked => Icons.lock_outline,
            _StepState.upcoming => Icons.radio_button_unchecked,
          },
          size: 16,
          color: state == _StepState.done ? rm.successIcon : fg,
        ),
        const SizedBox(width: 8),
        Text('$number. $title${optional ? ' (opcional)' : ''}',
            style: t.bodyMedium?.copyWith(color: fg, fontWeight: weight)),
      ]),
    );
    return Semantics(
      button: onTap != null,
      label: 'Paso $number, $title, $stateLabel',
      excludeSemantics: true,
      child: onTap == null
          ? (reason == null ? content : Tooltip(message: reason!, child: content))
          : Tooltip(
              message: 'Volver a este paso',
              child: InkWell(
                borderRadius: BorderRadius.circular(RmRadius.control),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}
