import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/audit/auditoria_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/help/help_content.dart';
import '../features/help/help_screen.dart';
import '../features/history/historial_screen.dart';
import '../features/login/change_password_screen.dart';
import '../features/login/login_screen.dart';
import '../features/mapping/mapeo_screen.dart';
import '../features/preview/vista_previa_screen.dart';
import '../features/reports/reportes_screen.dart';
import '../features/settings/configuracion_screen.dart';
import '../features/setup/setup_wizard_screen.dart';
import '../features/sync/sincronizaciones_screen.dart';
import '../features/users/usuarios_screen.dart';
import '../services/service_providers.dart';
import 'shell.dart';

/// Bridges Riverpod session changes to go_router refreshes.
class _SessionListenable extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable();
  ref.listen(sessionProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(sessionProvider);
      final loc = state.matchedLocation;
      if (user == null) return loc == Routes.login ? null : Routes.login;
      if (user.mustChangePassword) return loc == Routes.cambiarContrasena ? null : Routes.cambiarContrasena;
      if (loc == Routes.login) return Routes.dashboard;
      if (loc == Routes.usuarios && !user.isAdmin) return Routes.dashboard;
      if (loc == Routes.asistente && !user.isAdmin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', redirect: (_, _) => Routes.dashboard),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: Routes.cambiarContrasena, builder: (_, _) => const ChangePasswordScreen()),
          GoRoute(path: Routes.asistente, builder: (_, _) => const SetupWizardScreen()),
          GoRoute(path: Routes.dashboard, builder: (_, _) => const DashboardScreen()),
          GoRoute(path: Routes.sincronizaciones, builder: (_, _) => const SincronizacionesScreen()),
          GoRoute(path: Routes.reportes, builder: (_, _) => const ReportesScreen()),
          GoRoute(
            path: Routes.vistaPrevia,
            builder: (_, s) => VistaPreviaScreen(
              initialFrom: DateTime.tryParse(s.uri.queryParameters['desde'] ?? ''),
              initialTo: DateTime.tryParse(s.uri.queryParameters['hasta'] ?? ''),
            ),
          ),
          GoRoute(path: Routes.mapeo, builder: (_, _) => const MapeoScreen()),
          GoRoute(path: Routes.configuracion, builder: (_, _) => const ConfiguracionScreen()),
          GoRoute(path: Routes.historial, builder: (_, _) => const HistorialScreen()),
          GoRoute(path: Routes.auditoria, builder: (_, _) => const AuditoriaScreen()),
          GoRoute(path: Routes.usuarios, builder: (_, _) => const UsuariosScreen()),
          GoRoute(path: Routes.ayuda, builder: (_, _) => const HelpScreen()),
        ],
      ),
    ],
  );
});
