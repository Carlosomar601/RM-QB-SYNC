import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../data/db/repositories.dart';
import '../../ui/brand.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';
import '../mapping/mapeo_screen.dart';
import '../settings/pos_api_form.dart';
import '../settings/qbo_cards.dart';
import '../sync/sincronizaciones_screen.dart';

/// First-run "Asistente de configuración".
class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  static const _draftKey = 'asistente';
  int? _initialStep;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    ref.read(draftStoreProvider).read(_draftKey).then((d) {
      if (mounted) setState(() => _initialStep = (d?['step'] as num?)?.toInt() ?? 0);
    });
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).setBool(SettingKeys.setupWizardDone, true);
    await ref.read(draftStoreProvider).clear(_draftKey);
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(setupStatusProvider).value;
    if (_initialStep == null) return const LoadingBox();

    if (_finished && status != null) {
      final next = recommendedNextAction(status);
      return PageBody(children: [
        CompletionSummary(
          success: status.ready,
          title: status.ready ? '¡RM Ledger Sync está listo!' : 'Asistente terminado con pendientes',
          message: status.ready
              ? 'Ya puede revisar y enviar sus ventas a QuickBooks.'
              : 'Puede completar lo pendiente cuando quiera; la pantalla de Inicio le indicará qué falta.',
          items: [
            SummaryItem('API del POS', status.posConfigured ? (status.posUrl ?? 'Configurada') : 'Pendiente'),
            SummaryItem('QuickBooks', status.qboConnected ? (status.companyName ?? 'Conectado') : 'Pendiente'),
            SummaryItem('Mapeo de cuentas', '${status.mappedCount} de ${status.totalCategories}'),
            SummaryItem('Programación', status.scheduleEnabled ? 'Activa' : 'No programada'),
          ],
          nextActionLabel: next.label,
          onNextAction: () => context.go(next.route),
          secondaryLabel: 'Ir a Inicio',
          onSecondary: () => context.go(Routes.dashboard),
        ),
      ]);
    }

    Widget check(bool ok, String text) => ListTile(
          dense: true,
          leading: Icon(ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: ok ? context.rm.successIcon : context.rm.textMuted,
              semanticLabel: ok ? 'Listo' : 'Pendiente'),
          title: Text(text),
        );

    return PageBody(children: [
      ScreenHeader(
        icon: Icons.auto_fix_high_outlined,
        title: 'Asistente de configuración',
        purpose: 'Le guiamos paso a paso para dejar RM Ledger Sync listo. Puede salir y volver; su avance se guarda.',
        actions: [TextButton(onPressed: () => context.go(Routes.dashboard), child: const Text('Salir del asistente'))],
      ),
      StepWizard(
        initialStep: _initialStep!,
        completeLabel: 'Terminar',
        onStepChanged: (i) => ref.read(draftStoreProvider).save(_draftKey, {'step': i}),
        steps: [
          WizardStep(
            title: 'Bienvenida',
            explanation: 'RM Ledger Sync lee los totales de ventas y pagos del POS Retail Manager y crea un asiento de diario '
                'balanceado en QuickBooks Online.',
            instructions: const [
              'Tenga a mano la IP y el puerto del servidor del POS.',
              'Tenga el Client ID y Client Secret de Intuit (si el instalador los trajo, ya están guardados).',
              'Tenga un usuario administrador de QuickBooks Online para autorizar.',
            ],
            example: 'Tiempo estimado: 10 minutos.',
            builder: (_) => Column(children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(
                  child: SizedBox(width: 420, child: BrandHeader(subtitle: 'Bienvenido. Configuremos la conexión paso a paso.')),
                ),
              ),
              check(status?.posConfigured ?? false, 'API del POS configurada'),
              check(status?.qboCredentials ?? false, 'Credenciales de Intuit guardadas'),
              check(status?.qboConnected ?? false, 'QuickBooks conectado'),
              check(status?.mappingsComplete ?? false, 'Mapeo de cuentas completo'),
              check(status?.scheduleEnabled ?? false, 'Programación (opcional)'),
            ]),
          ),
          WizardStep(
            title: 'API del POS',
            explanation: 'Indique dónde está el servidor del POS en la red de la tienda.',
            instructions: const [
              'Escriba la IP (ej.: 192.168.100.175) y el puerto (normalmente 8180).',
              'Presione "Probar conexión" y espere el mensaje verde.',
              'Presione "Aplicar cambios".',
            ],
            validate: () => (status?.posConfigured ?? false) ? const [] : ['Aplique una dirección del POS.'],
            builder: (_) => PosApiForm(onApplied: (_) => ref.invalidate(setupStatusProvider)),
          ),
          WizardStep(
            title: 'QuickBooks',
            explanation: 'Autorice a RM Ledger Sync para crear asientos en su compañía de QuickBooks Online.',
            instructions: const [
              'Si las credenciales no están guardadas, escriba Client ID y Client Secret y presione "Aplicar cambios".',
              'Presione "Conectar con QuickBooks" y complete la autorización en el navegador.',
            ],
            example: 'Use "Sandbox" para pruebas y "Producción" para su contabilidad real.',
            optional: true,
            builder: (_) => const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              QboConnectionPanel(),
              Divider(height: 32),
              QboCredentialsForm(),
            ]),
          ),
          WizardStep(
            title: 'Mapeo de cuentas',
            explanation: 'Asigne una cuenta de QuickBooks a cada categoría del POS.',
            optional: true,
            builder: (_) => const MappingEditor(),
          ),
          WizardStep(
            title: 'Programación',
            explanation: 'Opcional: envíe automáticamente cada día, semana o mes.',
            optional: true,
            builder: (_) => const ScheduleWizard(compact: true),
          ),
          WizardStep(
            title: 'Resumen',
            explanation: 'Esto es lo que quedó configurado. Lo pendiente se puede completar después.',
            builder: (_) => Column(children: [
              check(status?.posConfigured ?? false, 'API del POS: ${status?.posUrl ?? 'pendiente'}'),
              check(status?.qboConnected ?? false, 'QuickBooks: ${status?.companyName ?? (status?.qboConnected ?? false ? 'conectado' : 'pendiente')}'),
              check(status?.mappingsComplete ?? false, 'Mapeo: ${status?.mappedCount ?? 0} de ${status?.totalCategories ?? 0}'),
              check(status?.scheduleEnabled ?? false, 'Programación: ${(status?.scheduleEnabled ?? false) ? 'activa' : 'no programada'}'),
            ]),
          ),
        ],
        onComplete: _finish,
      ),
    ]);
  }
}
