import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../services/auth_service.dart';
import '../../services/service_providers.dart';
import '../../ui/guided/guided.dart';
import '../onboarding/tour.dart';

final usersProvider = FutureProvider<List<AppUser>>((ref) => ref.watch(authServiceProvider).allUsers());

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  Future<void> _guard(BuildContext context, WidgetRef ref, Future<void> Function() f, String ok) async {
    try {
      await f();
      ref.invalidate(usersProvider);
      if (context.mounted) showSnack(context, ok);
    } on AuthException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider)!;
    final users = ref.watch(usersProvider);
    final auth = ref.read(authServiceProvider);

    return PageBody(children: [
      ScreenHeader(
        icon: Icons.group_outlined,
        title: 'Usuarios',
        purpose: 'Cree usuarios, actívelos o desactívelos y restablezca contraseñas.',
        nextHint: 'Entregue la contraseña temporal al usuario; deberá cambiarla al entrar.',
        actions: [
          TourTarget(
            id: 'usuarios:create',
            child: FilledButton.icon(
              onPressed: () => _createUser(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Crear usuario'),
            ),
          ),
        ],
      ),
      users.when(
        loading: () => const LoadingBox(),
        error: (e, _) => GuidanceBanner(kind: GuidanceKind.error, title: 'No se pudieron leer los usuarios', message: '$e'),
        data: (list) => Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final u in list)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: context.rm.navSelected,
                  foregroundColor: context.rm.textPrimary,
                  child: Text(u.displayName.isEmpty ? '?' : u.displayName[0].toUpperCase()),
                ),
                title: Text('${u.displayName} (${u.username})${u.id == me.id ? ' · usted' : ''}'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    StatusChip(
                      label: u.isAdmin ? 'Administrador' : 'Usuario',
                      tone: u.isAdmin ? RmTone.info : RmTone.neutral,
                      icon: u.isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                    ),
                    StatusChip(
                      label: u.isActive ? 'Activo' : 'Desactivado',
                      tone: u.isActive ? RmTone.success : RmTone.danger,
                      icon: u.isActive ? Icons.check_circle_outline : Icons.block,
                    ),
                    if (u.mustChangePassword)
                      const StatusChip(label: 'Debe cambiar contraseña', tone: RmTone.warning, icon: Icons.password),
                    Text('Último acceso: ${u.lastLoginAt == null ? 'nunca' : Dates.dmyHm(u.lastLoginAt!)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
                trailing: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Tooltip(
                    message: u.isActive ? 'Desactivar' : 'Activar',
                    child: Switch(
                      value: u.isActive,
                      onChanged: (v) async {
                        final ok = v
                            ? await confirmAction(context,
                                title: 'Activar usuario',
                                message: '${u.username} podrá volver a iniciar sesión con su contraseña actual.',
                                confirmLabel: 'Activar')
                            : await confirmAction(context,
                                title: 'Desactivar usuario',
                                message: '${u.username} no podrá iniciar sesión.',
                                confirmLabel: 'Desactivar',
                                destructive: true);
                        if (!ok) return;
                        if (context.mounted) {
                          await _guard(context, ref, () => auth.setActive(by: me, userId: u.id, active: v),
                              v ? 'Usuario activado.' : 'Usuario desactivado.');
                        }
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Más acciones',
                    onSelected: (a) async {
                      if (a == 'reset') await _resetPassword(context, ref, u);
                      if (a == 'admin' && context.mounted) {
                        final ok = await confirmAction(context,
                            title: u.isAdmin ? 'Quitar administrador' : 'Hacer administrador',
                            message: u.isAdmin
                                ? '${u.username} ya no podrá cambiar configuración, mapeo ni usuarios.'
                                : '${u.username} podrá cambiar la configuración, el mapeo, la programación y los usuarios.',
                            confirmLabel: u.isAdmin ? 'Quitar administrador' : 'Hacer administrador',
                            destructive: u.isAdmin);
                        if (!ok || !context.mounted) return;
                        await _guard(context, ref, () => auth.setAdmin(by: me, userId: u.id, isAdmin: !u.isAdmin),
                            u.isAdmin ? 'Ya no es administrador.' : 'Ahora es administrador.');
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'reset', child: Text('Restablecer contraseña')),
                      PopupMenuItem(value: 'admin', child: Text(u.isAdmin ? 'Quitar administrador' : 'Hacer administrador')),
                    ],
                  ),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _showTemp(BuildContext context, String user, String temp) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle_outline, color: context.rm.successIcon),
          title: const Text('Contraseña temporal'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Usuario: $user'),
            SelectableText('Contraseña temporal: $temp', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Entréguela al usuario. Se le pedirá cambiarla al iniciar sesión.'),
          ]),
          actions: [
            TextButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: temp)), child: const Text('Copiar')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Listo')),
          ],
        ),
      );

  Future<void> _resetPassword(BuildContext context, WidgetRef ref, AppUser u) async {
    final ok = await confirmAction(context,
        title: 'Restablecer contraseña',
        message: 'Se generará una contraseña temporal para ${u.username}. La actual dejará de funcionar.',
        confirmLabel: 'Restablecer');
    if (!ok || !context.mounted) return;
    final temp = AuthService.generateTemporaryPassword();
    try {
      await ref.read(authServiceProvider).resetPassword(by: ref.read(sessionProvider)!, userId: u.id, temporaryPassword: temp);
      if (context.mounted) await _showTemp(context, u.username, temp);
    } on AuthException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _createUser(BuildContext context, WidgetRef ref) async {
    final form = GlobalKey<FormState>();
    final user = TextEditingController();
    final name = TextEditingController();
    var admin = false;
    String? error;
    final created = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Crear usuario'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: user,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Usuario *', helperText: 'Ej.: maria.lopez (sin espacios)'),
                  validator: (v) => RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch((v ?? '').trim())
                      ? null
                      : '3–32 caracteres: letras, números, punto, guion o guion bajo.',
                ),
                const SizedBox(height: 12),
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nombre a mostrar')),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: admin,
                  onChanged: (v) => setS(() => admin = v ?? false),
                  title: const Text('Administrador'),
                  subtitle: const Text('Puede cambiar configuración, mapeo y usuarios.'),
                ),
                const Text('Se generará una contraseña temporal que el usuario cambiará al entrar.'),
                if (error != null) GuidanceBanner(kind: GuidanceKind.error, title: error!),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final temp = AuthService.generateTemporaryPassword();
                try {
                  await ref.read(authServiceProvider).createUser(
                      by: ref.read(sessionProvider)!,
                      username: user.text,
                      displayName: name.text,
                      password: temp,
                      isAdmin: admin);
                  if (ctx.mounted) Navigator.of(ctx).pop((user.text.trim(), temp));
                } on AuthException catch (e) {
                  setS(() => error = e.message);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    user.dispose();
    name.dispose();
    ref.invalidate(usersProvider);
    if (created != null && context.mounted) await _showTemp(context, created.$1, created.$2);
  }
}
