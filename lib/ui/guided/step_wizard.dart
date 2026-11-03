import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  int get index => _index;

  void goTo(int i) {
    if (i < 0 || i >= widget.steps.length) return;
    setState(() {
      _index = i;
      _problems = const [];
    });
    widget.onStepChanged?.call(i);
  }

  bool _validateCurrent() {
    final v = widget.steps[_index].validate;
    final problems = v == null ? const <String>[] : v();
    setState(() => _problems = problems);
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
            _Progress(steps: steps, index: _index, onTap: (i) {
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
                                backgroundColor: cs.primaryContainer,
                                child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer))),
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
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.tips_and_updates_outlined, size: 18, color: cs.primary),
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
                          decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Antes de continuar, complete lo siguiente:',
                                  style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600)),
                              for (final p in _problems)
                                Text('• $p', style: TextStyle(color: cs.onErrorContainer)),
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

class _Progress extends StatelessWidget {
  const _Progress({required this.steps, required this.index, required this.onTap});

  final List<WizardStep> steps;
  final int index;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Progreso: paso ${index + 1} de ${steps.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: (index + 1) / steps.length, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < steps.length; i++)
                InputChip(
                  avatar: Icon(
                    i < index ? Icons.check_circle : (i == index ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    size: 18,
                    color: i <= index ? cs.primary : cs.outline,
                  ),
                  label: Text('${i + 1}. ${steps[i].title}${steps[i].optional ? ' (opcional)' : ''}'),
                  selected: i == index,
                  showCheckmark: false,
                  onPressed: i < index ? () => onTap(i) : null,
                  tooltip: i < index ? 'Volver a este paso' : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
