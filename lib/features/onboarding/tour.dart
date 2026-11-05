import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/tokens.dart';
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

/// Task guidance for a single screen ("Guíame" pressed on that screen).
/// Targets that are not on screen (e.g. admin-only controls) are skipped.
const screenTours = <String, List<TourStep>>{
  '/inicio': [
    TourStep('inicio:next', 'Siguiente paso recomendado',
        'Se calcula con el estado real: configuración, autorización de QuickBooks y el resultado de la última sincronización.'),
    TourStep('inicio:status', 'Estado de las conexiones',
        'QuickBooks, el POS y el resultado de la última sincronización. Toque una tarjeta para ver el detalle.'),
  ],
  '/sincronizaciones': [
    TourStep('sync:presets', '1. Elija el rango', 'Toque un atajo como "Ayer". Se enviará un solo asiento con la fecha del último día.'),
    TourStep('sync:actions', '2. Revise y envíe',
        'Si es la primera vez, revise antes en Vista Previa. "Sincronizar ahora" pide confirmación antes de enviar.'),
    TourStep('sync:schedule', 'Sincronización automática',
        'Aquí ve si la programación está activa, cuándo corre y el resultado de la última ejecución.'),
  ],
  '/vista-previa': [
    TourStep('preview:wizard', 'Tres pasos',
        '1) Elija el rango. 2) Revise que el asiento esté balanceado. 3) Confirme y envíe. Nada se envía hasta que confirme.'),
  ],
  '/mapeo': [
    TourStep('mapeo:accounts', 'Cuentas de QuickBooks',
        'Se leen de QuickBooks. Si creó una cuenta nueva, use "Volver a leer de QuickBooks".'),
    TourStep('mapeo:wizard', 'Asigne cada categoría',
        'Para cada categoría del POS elija la cuenta y el lado (Debe o Haber). Al final revise y aplique.'),
  ],
  '/configuracion': [
    TourStep('config:qbo', 'QuickBooks Online',
        'Conecte, pruebe o reconecte QuickBooks. Aquí ve el ambiente y hasta cuándo vale la autorización.'),
    TourStep('config:creds', 'Credenciales de Intuit', 'Client ID y Client Secret de developer.intuit.com. El secreto nunca se muestra.'),
    TourStep('config:pos', 'API del POS', 'Dirección del servidor Retail Manager. Pruebe la conexión antes de aplicar.'),
  ],
  '/historial': [
    TourStep('historial:filters', 'Buscar y filtrar', 'Filtre por estado u origen, o busque por fecha, usuario o mensaje.'),
    TourStep('historial:table', 'Resultado de cada envío',
        'Toque una fila para ver el detalle. En las fallidas, "Ver error" explica la causa y cómo resolverla.'),
  ],
  '/auditoria': [
    TourStep('auditoria:filter', 'Buscar acciones', 'Escriba un usuario, una acción o parte del detalle para filtrar.'),
  ],
  '/usuarios': [
    TourStep('usuarios:create', 'Crear usuario', 'Se genera una contraseña temporal que el usuario deberá cambiar al entrar.'),
  ],
  '/ayuda': [
    TourStep('ayuda:tabs', 'Centro de ayuda', 'Referencia rápida, tutoriales, preguntas frecuentes, solución de problemas y la versión.'),
  ],
};

class TourState {
  const TourState({this.active = false, this.step = 0, this.steps = tourSteps});
  final bool active;
  final int step;

  /// Steps being shown: the global tour or a screen tour.
  final List<TourStep> steps;

  bool get isGlobal => identical(steps, tourSteps);
}

class TourController extends Notifier<TourState> {
  @override
  TourState build() => const TourState();

  String get _user => ref.read(sessionProvider)?.username ?? '_';

  Future<bool> isDone() => ref.read(settingsRepositoryProvider).getBool(SettingKeys.tourDone(_user));

  Future<void> startIfFirstTime() async {
    if (!await isDone()) await resume();
  }

  /// "Guíame": guidance for the screen at [location]; the global tour when
  /// the screen has none (or none of its targets are visible).
  Future<void> guide(String location) async {
    final entry = screenTours.entries.where((e) => location.startsWith(e.key)).firstOrNull;
    final visible =
        entry?.value.where((st) => TourTargets.key(st.targetId).currentContext != null).toList() ?? const <TourStep>[];
    if (visible.isEmpty) return resume();
    state = TourState(active: true, steps: [
      ...visible,
      const TourStep('appbar:help', 'Ayuda de esta pantalla', 'Presione F1 o este botón para ver la ayuda sin perder su trabajo.'),
    ]);
  }

  /// Starts or resumes the global tour from the paused step.
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
    if (state.step >= state.steps.length - 1) return finish();
    state = TourState(active: true, step: state.step + 1, steps: state.steps);
    if (state.isGlobal) await ref.read(settingsRepositoryProvider).set('tour.step.$_user', '${state.step}');
  }

  void previous() {
    if (state.step > 0) state = TourState(active: true, step: state.step - 1, steps: state.steps);
  }

  /// Hides the tour but remembers the step ("Pausar").
  Future<void> pause() async {
    if (!state.isGlobal) {
      state = const TourState();
      return;
    }
    await ref.read(settingsRepositoryProvider).set('tour.step.$_user', '${state.step}');
    state = TourState(active: false, step: state.step);
  }

  /// "Omitir" / finished: never auto-start again for this user.
  Future<void> finish() async {
    if (!state.isGlobal) {
      state = const TourState();
      return;
    }
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
    final steps = s.steps;
    final step = steps[s.step.clamp(0, steps.length - 1)];
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
            child: CustomPaint(painter: _ScrimPainter(target, context.rm.focus)),
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
                    Text('${s.isGlobal ? 'Recorrido' : 'Guía'} ${s.step + 1} de ${steps.length}',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(step.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(step.text),
                    const SizedBox(height: 12),
                    Wrap(spacing: 4, runSpacing: 4, alignment: WrapAlignment.end, children: [
                      TextButton(onPressed: ctl.finish, child: Text(s.isGlobal ? 'Omitir' : 'Cerrar')),
                      if (s.isGlobal) TextButton(onPressed: ctl.pause, child: const Text('Pausar')),
                      if (s.step > 0) OutlinedButton(onPressed: ctl.previous, child: const Text('Atrás')),
                      FilledButton(
                        autofocus: true,
                        onPressed: ctl.next,
                        child: Text(s.step == steps.length - 1 ? 'Terminar' : 'Siguiente'),
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
    final scrim = Paint()..color = RmColors.scrim;
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
