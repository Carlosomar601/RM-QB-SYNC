import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../data/db/app_database.dart';
import '../../ui/guided/guided.dart';

final auditProvider = FutureProvider<List<AuditLogRow>>((ref) => ref.watch(auditRepositoryProvider).recent(300));

/// Human readable Spanish label for audit action codes.
String auditActionLabel(String a) => switch (a) {
      'InicioSesion' => 'Inicio de sesión',
      'InicioSesionFallido' => 'Inicio de sesión fallido',
      'CuentaBloqueada' => 'Cuenta bloqueada',
      'CierreSesion' => 'Cierre de sesión',
      'ContrasenaCambiada' => 'Contraseña cambiada',
      'ContrasenaRestablecida' => 'Contraseña restablecida',
      'UsuarioCreado' => 'Usuario creado',
      'UsuarioActivado' => 'Usuario activado',
      'UsuarioDesactivado' => 'Usuario desactivado',
      'UsuarioPromovidoAdmin' => 'Usuario hecho administrador',
      'UsuarioQuitadoAdmin' => 'Usuario ya no es administrador',
      'ConfiguracionApiPosActualizada' => 'API del POS actualizada',
      'QuickBooksConectado' => 'QuickBooks conectado',
      'QuickBooksDesconectado' => 'QuickBooks desconectado',
      'CredencialesQboActualizadas' => 'Credenciales de Intuit actualizadas',
      'MapeoActualizado' => 'Mapeo de cuentas actualizado',
      'ProgramacionActualizada' => 'Programación actualizada',
      'SincronizacionManualExitosa' => 'Sincronización manual exitosa',
      'SincronizacionManualFallida' => 'Sincronización manual fallida',
      'SincronizacionManualOmitidaDuplicado' => 'Sincronización manual omitida (duplicado)',
      'SincronizacionProgramadaExitosa' => 'Sincronización programada exitosa',
      'SincronizacionProgramadaFallida' => 'Sincronización programada fallida',
      'SincronizacionProgramadaOmitidaDuplicado' => 'Sincronización programada omitida (duplicado)',
      _ => a,
    };

class AuditoriaScreen extends ConsumerStatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  ConsumerState<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends ConsumerState<AuditoriaScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(auditProvider);
    return PageBody(children: [
      ScreenHeader(
        icon: Icons.fact_check,
        title: 'Auditoría',
        purpose: 'Las últimas 300 acciones registradas: quién hizo qué y cuándo.',
        actions: [IconButton(tooltip: 'Actualizar', onPressed: () => ref.invalidate(auditProvider), icon: const Icon(Icons.refresh))],
      ),
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Filtrar por usuario, acción o detalle'),
        onChanged: (v) => setState(() => _filter = v.toLowerCase()),
      ),
      const SizedBox(height: 12),
      rows.when(
        loading: () => const LoadingBox(),
        error: (e, _) => GuidanceBanner(kind: GuidanceKind.error, title: 'Error', message: '$e'),
        data: (list) {
          final f = list
              .where((r) =>
                  _filter.isEmpty ||
                  '${r.username} ${auditActionLabel(r.action)} ${r.action} ${r.details ?? ''}'.toLowerCase().contains(_filter))
              .toList();
          return Card(
            child: Column(children: [
              for (final r in f)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.circle, size: 10),
                  title: Text('${auditActionLabel(r.action)} · ${r.username}'),
                  subtitle: Text('${Dates.dmyHm(r.timestamp)}${r.details == null ? '' : '\n${r.details}'}'),
                  isThreeLine: r.details != null,
                ),
              if (f.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Sin resultados.')),
            ]),
          );
        },
      ),
    ]);
  }
}
