import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/db/repositories.dart';
import '../../services/auth_service.dart';
import '../../services/service_providers.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(sessionProvider)!;
    final wasForced = user.mustChangePassword;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref.read(authServiceProvider).changePassword(user, _current.text, _new.text);
      ref.read(firstRunPasswordProvider.notifier).set(null);
      setState(() => _done = true);
      ref.read(sessionProvider.notifier).set(updated);
      if (wasForced && updated.isAdmin && mounted) {
        final wizardDone = await ref.read(settingsRepositoryProvider).getBool(SettingKeys.setupWizardDone);
        if (!wizardDone && mounted) context.go(Routes.asistente);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final forced = user?.mustChangePassword ?? false;
    return PageBody(maxWidth: 560, children: [
      ScreenHeader(
        icon: Icons.password,
        title: 'Cambiar contraseña',
        purpose: forced
            ? 'Por seguridad debe reemplazar la contraseña temporal antes de continuar.'
            : 'Cambie la contraseña de su usuario de RM Ledger Sync.',
        nextHint: forced ? 'Después le guiaremos para configurar la aplicación.' : null,
      ),
      if (_done)
        CompletionSummary(
          title: 'Contraseña actualizada',
          items: [SummaryItem('Usuario', user?.username ?? '')],
          nextActionLabel: 'Ir a Inicio',
          onNextAction: () => context.go(Routes.dashboard),
        )
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(labelText: forced ? 'Contraseña temporal *' : 'Contraseña actual *'),
                  validator: (v) => (v ?? '').isEmpty ? 'Requerida.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _new,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña *',
                    helperText: 'Mínimo 8 caracteres, con letras y números.',
                  ),
                  validator: (v) => AuthService.validatePasswordPolicy(v ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Repita la nueva contraseña *'),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => v != _new.text ? 'Las contraseñas no coinciden.' : null,
                ),
                if (_error != null) GuidanceBanner(kind: GuidanceKind.error, title: _error!),
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
                  if (!forced) TextButton(onPressed: () => context.go(Routes.dashboard), child: const Text('Cancelar')),
                  FilledButton(onPressed: _busy ? null : _submit, child: const Text('Guardar contraseña')),
                ]),
              ]),
            ),
          ),
        ),
    ]);
  }
}
