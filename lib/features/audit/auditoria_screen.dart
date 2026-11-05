import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../data/db/app_database.dart';
import '../../ui/guided/guided.dart';
import '../onboarding/tour.dart';

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
      'UsuarioAdministradorInicialCreado' => 'Administrador inicial creado',
      'MigracionVersionAnterior' => 'Datos importados de la versión anterior',
      _ => a,
    };

/// Outcome tone and icon for an audit action (icon + text, never color alone).
(RmTone, IconData) auditActionStyle(String a) {
  if (a.contains('Fallid') || a.contains('Bloquead')) return (RmTone.danger, Icons.error_outline);
  if (a.contains('Omitida')) return (RmTone.warning, Icons.skip_next_outlined);
  if (a.contains('Exitosa') || a.contains('Conectado') || a.contains('Creado')) return (RmTone.success, Icons.check_circle_outline);
  if (a.startsWith('InicioSesion') || a.startsWith('CierreSesion')) return (RmTone.neutral, Icons.login);
  if (a.contains('Contrasena') || a.startsWith('Usuario')) return (RmTone.neutral, Icons.person_outline);
  return (RmTone.info, Icons.edit_note);
}

/// Readable detail: JSON objects become "clave: valor" lines; keys that look
/// like secrets are never shown.
String auditDetailText(String? details) {
  if (details == null || details.isEmpty) return '';
  final t = details.trim();
  if (!t.startsWith('{')) return details;
  try {
    final m = jsonDecode(t);
    if (m is! Map) return details;
    String fmt(Object? v) => v is Map
        ? v.entries.where((e) => !_secretKey('${e.key}')).map((e) => '${e.key}=${e.value}').join(', ')
        : '$v';
    return m.entries.where((e) => !_secretKey('${e.key}')).map((e) => '${e.key}: ${fmt(e.value)}').join('\n');
  } catch (_) {
    return details;
  }
}

bool _secretKey(String k) {
  final l = k.toLowerCase();
  return l.contains('secret') || l.contains('password') || l.contains('contrasena') || l.contains('token') || l == 'apikeyvalue';
}

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
    final rm = context.rm;
    final t = Theme.of(context).textTheme;
    return PageBody(children: [
      ScreenHeader(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Auditoría',
        purpose: 'Las últimas 300 acciones registradas: quién hizo qué y cuándo.',
        nextHint: 'Escriba en el filtro para encontrar una acción, un usuario o una fecha.',
        actions: [IconButton(tooltip: 'Actualizar', onPressed: () => ref.invalidate(auditProvider), icon: const Icon(Icons.refresh))],
      ),
      TourTarget(
        id: 'auditoria:filter',
        child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Filtrar por usuario, acción, fecha o detalle'),
          onChanged: (v) => setState(() => _filter = v.toLowerCase()),
        ),
      ),
      const SizedBox(height: 12),
      rows.when(
        loading: () => const LoadingBox(),
        error: (e, _) => GuidanceBanner(kind: GuidanceKind.error, title: 'No se pudo leer la auditoría', message: '$e'),
        data: (list) {
          final f = list
              .where((r) =>
                  _filter.isEmpty ||
                  '${r.username} ${auditActionLabel(r.action)} ${r.action} ${Dates.dmyHm(r.timestamp)} ${r.details ?? ''}'
                      .toLowerCase()
                      .contains(_filter))
              .toList();
          if (f.isEmpty) {
            return Card(
              child: EmptyState(
                icon: Icons.manage_search,
                title: list.isEmpty ? 'Todavía no hay acciones registradas' : 'Ninguna acción coincide con el filtro',
              ),
            );
          }
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < f.length; i++) ...[
                if (i > 0) Divider(height: 1, color: rm.border),
                Builder(builder: (context) {
                  final r = f[i];
                  final (tone, icon) = auditActionStyle(r.action);
                  final c = rm.tone(tone);
                  final detail = auditDetailText(r.details);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
                        child: Icon(icon, size: 18, color: c.icon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            Text(auditActionLabel(r.action), style: t.titleSmall),
                            Text('·  ${r.username}', style: t.bodyMedium?.copyWith(color: rm.textSecondary)),
                          ]),
                          if (detail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            SelectableText(detail, style: t.bodyMedium),
                          ],
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Text(Dates.dmyHm(r.timestamp), style: t.bodySmall?.copyWith(fontFeatures: tabularFigures)),
                    ]),
                  );
                }),
              ],
            ]),
          );
        },
      ),
    ]);
  }
}
