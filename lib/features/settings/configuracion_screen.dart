import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/repositories.dart';
import '../../services/desktop_integration.dart';
import '../../services/service_providers.dart';
import '../../ui/guided/guided.dart';
import 'pos_api_form.dart';
import 'qbo_cards.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PageBody(children: [
      ScreenHeader(
        icon: Icons.settings,
        title: 'Configuración',
        purpose: 'Conecte QuickBooks Online e indique dónde está la API del POS.',
        nextHint: 'Cuando todo esté en verde, vaya a Mapeo de Cuentas.',
      ),
      SectionCard(
        title: 'QuickBooks Online',
        icon: Icons.cloud_outlined,
        help: 'La autorización se renueva automáticamente. Dura unos 100 días sin uso.',
        child: QboConnectionPanel(),
      ),
      SectionCard(
        title: 'Credenciales de Intuit',
        icon: Icons.key_outlined,
        subtitle: 'Identifican a RMQBsync ante Intuit. Se guardan cifradas en Windows.',
        child: QboCredentialsForm(),
      ),
      SectionCard(
        title: 'Acceso a la API del POS',
        icon: Icons.point_of_sale,
        subtitle: 'Dirección del servidor Retail Manager en la red de la tienda. Los cambios se aplican al instante.',
        help: 'Ejemplo: protocolo http, IP 192.168.100.175, puerto 8180.',
        child: PosApiForm(),
      ),
      SectionCard(
        title: 'Aplicación',
        icon: Icons.desktop_windows_outlined,
        child: _AppOptions(),
      ),
    ]);
  }
}

class _AppOptions extends ConsumerStatefulWidget {
  const _AppOptions();

  @override
  ConsumerState<_AppOptions> createState() => _AppOptionsState();
}

class _AppOptionsState extends ConsumerState<_AppOptions> {
  bool? _startup;

  @override
  void initState() {
    super.initState();
    DesktopIntegration.isLaunchAtStartupEnabled().then((v) {
      if (mounted) setState(() => _startup = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(sessionProvider)?.isAdmin ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _startup ?? false,
        onChanged: _startup == null || !isAdmin
            ? null
            : (v) async {
                try {
                  await DesktopIntegration.setLaunchAtStartup(v);
                  await ref.read(settingsRepositoryProvider).setBool(SettingKeys.launchAtStartup, v);
                  setState(() => _startup = v);
                } catch (e) {
                  if (context.mounted) showSnack(context, 'No se pudo cambiar: $e', error: true);
                }
              },
        title: const Text('Iniciar con Windows (minimizado en la bandeja)'),
        subtitle: const Text('Recomendado: las sincronizaciones programadas solo se ejecutan con la aplicación abierta.'),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline),
        title: Text('Cerrar la ventana no detiene RMQBsync'),
        subtitle: Text('La aplicación sigue en la bandeja del sistema (junto al reloj). Para salir por completo use '
            'el menú del icono → "Salir".'),
      ),
    ]);
  }
}
