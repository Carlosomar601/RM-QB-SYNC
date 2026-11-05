import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme_mode.dart';
import '../../data/db/repositories.dart';
import '../../services/auth_service.dart';
import '../../services/service_providers.dart';
import '../../ui/brand.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _remember = true;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (ref.read(firstRunPasswordProvider) != null) _user.text = AuthService.seedAdminUsername;
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final u = await ref.read(authServiceProvider).login(_user.text, _pass.text, remember: _remember);
      ref.read(sessionProvider.notifier).set(u);
      if (!mounted) return;
      if (!u.mustChangePassword && u.isAdmin && !await ref.read(settingsRepositoryProvider).getBool(SettingKeys.setupWizardDone)) {
        if (mounted) context.go(Routes.asistente);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temp = ref.watch(firstRunPasswordProvider);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shape: const Border(),
        actions: const [ThemeModeButton(), SizedBox(width: 8)],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BrandHeader(compact: true, subtitle: 'Ventas del POS Retail Manager → QuickBooks Online'),
                        const SizedBox(height: 16),
                        Text('Inicie sesión con su usuario de RM Ledger Sync (no el de QuickBooks).', style: t.bodyMedium),
                        const SizedBox(height: 12),
                        if (temp != null)
                          GuidanceBanner(
                            kind: GuidanceKind.info,
                            title: 'Primer uso',
                            message: 'Usuario: admin\nContraseña temporal: $temp\n\n'
                                'También quedó guardada en ${AuthService.firstAccessFile}. '
                                'Se le pedirá cambiarla al entrar.',
                            actionLabel: 'Copiar contraseña',
                            onAction: () {
                              Clipboard.setData(ClipboardData(text: temp));
                              showSnack(context, 'Contraseña temporal copiada.');
                            },
                          ),
                        TextFormField(
                          controller: _user,
                          autofocus: true,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(labelText: 'Usuario *', prefixIcon: Icon(Icons.person_outline)),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Escriba su usuario.' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Contraseña *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) => (v ?? '').isEmpty ? 'Escriba su contraseña.' : null,
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _remember,
                          onChanged: (v) => setState(() => _remember = v ?? false),
                          title: const Text('Recordarme en este equipo (30 días)'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (_error != null) GuidanceBanner(kind: GuidanceKind.error, title: _error!),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Iniciar sesión'),
                        ),
                        const SizedBox(height: 8),
                        Text('¿Olvidó su contraseña? Pida a un administrador que la restablezca en Usuarios.',
                            textAlign: TextAlign.center, style: t.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
