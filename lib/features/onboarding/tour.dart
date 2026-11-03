import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/repositories.dart';
import '../../services/service_providers.dart';

class TourStep {
  const TourStep(this.targetId, this.title, this.text);
  final String targetId;
  final String title;
  final String text;
}

/// Global keys for highlightable elements.
abstract final class TourTargets {
  static final Map<String, GlobalKey> _keys = {};
  static GlobalKey key(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'tour:$id'));
}

const tourSteps = <TourStep>[
  TourStep('nav:/inicio', 'Inicio', 'Aquí ve el estado general y lo que falta configurar. Siempre le sugiere el siguiente paso.'),
  TourStep('nav:/vista-previa', 'Vista Previa',
      'Antes de enviar, revise aquí el asiento que se creará en QuickBooks. Si no cuadra, puede diagnosticar la diferencia.'),
  TourStep('nav:/sincronizaciones', 'Sincronizaciones', 'Envíe ahora un rango de fechas o programe envíos automáticos diarios, semanales o mensuales.'),
  TourStep('nav:/mapeo', 'Mapeo de Cuentas', 'Indique a qué cuenta de QuickBooks va cada categoría del POS (Debe o Haber).'),
  TourStep('nav:/configuracion', 'Configuración', 'Conecte QuickBooks y escriba la IP y el puerto de la API del POS.'),
  TourStep('nav:/historial', 'Historial', 'Consulte el resultado de cada envío y el detalle de errores.'),
  TourStep('appbar:help', 'Ayuda en cada pantalla', 'Presione este botón o F1 para ver la ayuda de la pantalla actual sin perder su trabajo.'),
  TourStep('appbar:guide', 'Guíame', 'Puede reanudar este recorrido cuando quiera desde aquí o desde Ayuda.'),
];

class TourState {
  const TourState({this.active = false, this.step = 0});
  final bool active;
  final int step;
}

class TourController extends Notifier<TourState> {
  @override
  TourState build() => const TourState();

  String get _user => ref.read(sessionProvider)?.username ?? '_';

  Future<bool> isDone() => ref.read(settingsRepositoryProvider).getBool(SettingKeys.tourDone(_user));

  Future<void> startIfFirstTime() async {
    if (!await isDone()) await resume();
  }

  /// Starts or resumes from the paused step.
  Future<void> resume() async {
    final saved = int.tryParse(await ref.read(settingsRepositoryProvider).get('tour.step.$_user') ?? '') ?? 0;
    state = TourState(active: true, step: saved.clamp(0, tourSteps.length - 1));
  }

  Future<void> restart() async {
    await ref.read(settingsRepositoryProvider).set('tour.step.$_user', '0');
    await ref.read(settingsRepositoryProvider).setBool(SettingKeys.tourDone(_user), false);
    state = const TourState(active: true, step: 0);
  }

  Future<void> next() async {
    if (state.step >= tourSteps.length - 1) return finish();
    state = TourState(active: true, step: state.step + 1);
    await ref.read(settingsRepositoryProvider).set('tour.step.$_user', '${state.step}');
  }

  void previous() {
    if (state.step > 0) state = TourState(active: true, step: state.step - 1);
  }

  /// Hides the tour but remembers the step ("Pausar").
  Future<void> pause() async {
    await ref.read(settingsRepositoryProvider).set('tour.step.$_user', '${state.step}');
    state = TourState(active: false, step: state.step);
  }

  /// "Omitir" / finished: never auto-start again for this user.
  Future<void> finish() async {
    await ref.read(settingsRepositoryProvider).setBool(SettingKeys.tourDone(_user), true);
    await ref.read(settingsRepositoryProvider).set('tour.step.$_user', '0');
    state = const TourState();
  }
}

final tourProvider = NotifierProvider<TourController, TourState>(TourController.new);

/// Wraps a widget so the tour can highlight it.
class TourTarget extends StatelessWidget {
  const TourTarget({super.key, required this.id, required this.child});
  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: TourTargets.key(id), child: child);
}

/// Coach-mark overlay. Place it above the shell content in a Stack.
class TourOverlay extends ConsumerStatefulWidget {
  const TourOverlay({super.key});

  @override
  ConsumerState<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends ConsumerState<TourOverlay> {
  Rect? _lastTarget;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(tourProvider);
    if (!s.active) return const SizedBox.shrink();
    final step = tourSteps[s.step];
    final ctl = ref.read(tourProvider.notifier);

    return LayoutBuilder(builder: (context, constraints) {
      Rect? target;
      final ctx = TourTargets.key(step.targetId).currentContext;
      final overlayBox = context.findRenderObject() as RenderBox?;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && overlayBox != null && overlayBox.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
        target = (topLeft & box.size).inflate(6);
      }
      // Re-measure after layout (first frame / window resize / route change).
      final measured = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final b = TourTargets.key(step.targetId).currentContext?.findRenderObject() as RenderBox?;
        final o = context.findRenderObject() as RenderBox?;
        if (b == null || o == null || !b.hasSize || !o.hasSize) return;
        final r = (b.localToGlobal(Offset.zero, ancestor: o) & b.size).inflate(6);
        if (r != measured && r != _lastTarget) setState(() => _lastTarget = r);
      });
      final size = constraints.biggest;
      const cardW = 360.0;
      double left;
      double top;
      if (target == null) {
        left = (size.width - cardW) / 2;
        top = size.height / 3;
      } else if (target.right + cardW + 16 < size.width) {
        left = target.right + 16;
        top = target.top.clamp(16, size.height - 240);
      } else {
        left = (target.left - cardW - 16).clamp(16, size.width - cardW - 16);
        top = (target.bottom + 12).clamp(16, size.height - 240);
      }

      return Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            child: CustomPaint(painter: _ScrimPainter(target, Theme.of(context).colorScheme.primary)),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: cardW,
          child: Semantics(
            liveRegion: true,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recorrido ${s.step + 1} de ${tourSteps.length}', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(step.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(step.text),
                    const SizedBox(height: 12),
                    Wrap(spacing: 4, runSpacing: 4, alignment: WrapAlignment.end, children: [
                      TextButton(onPressed: ctl.finish, child: const Text('Omitir')),
                      TextButton(onPressed: ctl.pause, child: const Text('Pausar')),
                      if (s.step > 0) OutlinedButton(onPressed: ctl.previous, child: const Text('Atrás')),
                      FilledButton(
                        autofocus: true,
                        onPressed: ctl.next,
                        child: Text(s.step == tourSteps.length - 1 ? 'Terminar' : 'Siguiente'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.hole, this.color);
  final Rect? hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()..addRect(Offset.zero & size);
    if (hole != null) {
      path
        ..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(10)))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, scrim);
    if (hole != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(10)),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}
