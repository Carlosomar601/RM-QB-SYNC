import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../core/exceptions.dart';
import '../../data/quickbooks/qbo_providers.dart';
import '../../data/secrets/secret_store.dart';
import '../../ui/guided/guided.dart';
import '../../services/service_providers.dart';

/// Intuit Client ID / Secret / Environment (admin).
class QboCredentialsForm extends ConsumerStatefulWidget {
  const QboCredentialsForm({super.key, this.onSaved});
  final VoidCallback? onSaved;

  @override
  ConsumerState<QboCredentialsForm> createState() => _QboCredentialsFormState();
}

class _QboCredentialsFormState extends ConsumerState<QboCredentialsForm> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _secret = TextEditingController();
  String _env = 'sandbox';
  bool _loaded = false;
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _save(bool hadSecret, String oldEnv) async {
    if (!_form.currentState!.validate()) return;
    final conn = ref.read(qboConnectionProvider).value;
    if (conn != null && _env != oldEnv) {
      final ok = await confirmAction(context,
          title: 'Cambiar de ambiente',
          message: 'Está conectado a ${oldEnv == 'production' ? 'Producción' : 'Sandbox'}. '
              'Al cambiar a ${_env == 'production' ? 'Producción' : 'Sandbox'} deberá volver a conectar QuickBooks.',
          confirmLabel: 'Cambiar ambiente');
      if (!ok) return;
    }
    setState(() => _saving = true);
    try {
      final secrets = ref.read(secretStoreProvider);
      await secrets.write(SecretKeys.qboClientId, _id.text.trim());
      if (_secret.text.trim().isNotEmpty) await secrets.write(SecretKeys.qboClientSecret, _secret.text.trim());
      await ref.read(settingsRepositoryProvider).setQboEnvironment(_env);
      await ref.read(auditRepositoryProvider).log(ref.read(sessionProvider)!.username, 'CredencialesQboActualizadas',
          'Ambiente: $_env; secreto ${_secret.text.trim().isEmpty ? 'sin cambios' : 'actualizado'}');
      _secret.clear();
      ref.invalidate(qboCredentialsProvider);
      ref.invalidate(setupStatusProvider);
      setState(() => _saved = true);
      widget.onSaved?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creds = ref.watch(qboCredentialsProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin ?? false;
    return creds.when(
      loading: () => const LoadingBox(),
      error: (e, _) => Text('$e'),
      data: (c) {
        if (!_loaded) {
          _loaded = true;
          _id.text = c.clientId ?? '';
          _env = c.environment;
        }
        return Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!isAdmin) const GuidanceBanner(kind: GuidanceKind.info, title: 'Solo un administrador puede editar las credenciales.'),
            Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(
                width: 360,
                child: TextFormField(
                  controller: _id,
                  enabled: isAdmin,
                  decoration: const InputDecoration(labelText: 'Client ID *', helperText: 'De developer.intuit.com → Keys & credentials'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Escriba el Client ID.' : null,
                ),
              ),
              SizedBox(
                width: 360,
                child: TextFormField(
                  controller: _secret,
                  enabled: isAdmin,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: c.hasSecret ? 'Client Secret' : 'Client Secret *',
                    helperText: c.hasSecret ? 'Guardado. Déjelo vacío para conservarlo.' : 'Requerido la primera vez.',
                  ),
                  validator: (v) => !c.hasSecret && (v ?? '').trim().isEmpty ? 'Escriba el Client Secret.' : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const FieldLabel('Ambiente', required: true,
                  help: 'Sandbox = compañía de pruebas de Intuit. Producción = su contabilidad real.'),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sandbox', label: Text('Sandbox (pruebas)')),
                  ButtonSegment(value: 'production', label: Text('Producción')),
                ],
                selected: {_env},
                onSelectionChanged: isAdmin ? (s) => setState(() => _env = s.first) : null,
              ),
            ]),
            const SizedBox(height: 6),
            Text('URI de redirección registrada en Intuit: http://localhost:5177/oauth/callback',
                style: Theme.of(context).textTheme.bodySmall),
            if (_saved) const GuidanceBanner(kind: GuidanceKind.success, title: 'Credenciales guardadas de forma cifrada.'),
            if (isAdmin)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _save(c.hasSecret, c.environment),
                  icon: const Icon(Icons.save),
                  label: const Text('Aplicar cambios'),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// Connection status + Conectar / Desconectar.
class QboConnectionPanel extends ConsumerStatefulWidget {
  const QboConnectionPanel({super.key, this.onConnected});
  final VoidCallback? onConnected;

  @override
  ConsumerState<QboConnectionPanel> createState() => _QboConnectionPanelState();
}

class _QboConnectionPanelState extends ConsumerState<QboConnectionPanel> {
  bool _waiting = false;
  String? _error;

  Future<void> _connect() async {
    setState(() {
      _waiting = true;
      _error = null;
    });
    try {
      final r = await ref.read(qboConnectionServiceProvider).connect(ref.read(sessionProvider)!.username);
      ref.invalidate(setupStatusProvider);
      if (mounted) showSnack(context, 'Conectado a ${r.companyName ?? 'QuickBooks'}.');
      widget.onConnected?.call();
    } on QboApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  Future<void> _disconnect() async {
    final ok = await confirmAction(context,
        title: 'Desconectar QuickBooks',
        message: 'RMQBsync dejará de enviar asientos (incluidas las programaciones) hasta que vuelva a conectar.',
        confirmLabel: 'Desconectar',
        destructive: true);
    if (!ok) return;
    await ref.read(qboConnectionServiceProvider).disconnect(ref.read(sessionProvider)!.username);
    ref.invalidate(setupStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(qboConnectionProvider);
    final creds = ref.watch(qboCredentialsProvider).value;
    final isAdmin = ref.watch(sessionProvider)?.isAdmin ?? false;
    final hasCreds = creds != null && creds.hasClientId && creds.hasSecret;

    return conn.when(
      loading: () => const LoadingBox(),
      error: (e, _) => Text('$e'),
      data: (c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (c == null)
          GuidanceBanner(
            kind: GuidanceKind.warning,
            title: 'QuickBooks no está conectado',
            message: hasCreds
                ? 'Presione "Conectar con QuickBooks". Se abrirá el navegador: inicie sesión en Intuit, elija la compañía y autorice.'
                : 'Primero guarde el Client ID y el Client Secret de Intuit (abajo).',
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_done, color: Color(0xFF1B7F3B), size: 36),
            title: Text(c.companyName ?? 'Compañía conectada'),
            subtitle: Text('Ambiente: ${c.environment == 'production' ? 'Producción' : 'Sandbox'} · Realm ${c.realmId}\n'
                'Conectado: ${Dates.dmyHm(c.connectedAt)}'
                '${c.refreshTokenExpiresAt != null ? ' · Autorización vigente hasta ${Dates.dmy(c.refreshTokenExpiresAt!)}' : ''}'),
            isThreeLine: true,
          ),
        if (_waiting)
          const GuidanceBanner(
            kind: GuidanceKind.info,
            title: 'Esperando la autorización en el navegador…',
            message: 'Complete los pasos en la página de Intuit. Cuando vea "¡Conectado!", vuelva a esta ventana.',
          ),
        if (_error != null) GuidanceBanner(kind: GuidanceKind.error, title: 'No se pudo conectar', message: _error),
        if (isAdmin)
          Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            if (c != null)
              OutlinedButton.icon(onPressed: _waiting ? null : _disconnect, icon: const Icon(Icons.link_off), label: const Text('Desconectar')),
            FilledButton.icon(
              onPressed: _waiting || !hasCreds ? null : _connect,
              icon: const Icon(Icons.link),
              label: Text(c == null ? 'Conectar con QuickBooks' : 'Reconectar'),
            ),
          ]),
      ]),
    );
  }
}
