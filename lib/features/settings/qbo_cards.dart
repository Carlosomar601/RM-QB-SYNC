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
  bool _showSecret = false;

  @override
  void dispose() {
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  static String _envLabel(String e) => e == 'production' ? 'Producción' : 'Sandbox (pruebas)';

  /// Switching environment changes where journal entries are posted: confirm
  /// right away (not only on save) and explain the effect.
  Future<void> _changeEnv(String next) async {
    if (next == _env) return;
    final conn = ref.read(qboConnectionProvider).value;
    if (conn != null) {
      final ok = await confirmAction(context,
          title: 'Cambiar a ${_envLabel(next)}',
          message: 'Ahora está conectado a "${conn.companyName ?? 'QuickBooks'}" en ${_envLabel(conn.environment)}.',
          bullets: [
            'Después de aplicar deberá volver a conectar QuickBooks en el ambiente ${_envLabel(next)}.',
            'Hasta reconectar, las sincronizaciones (manuales y programadas) seguirán usando la conexión actual.',
            if (next == 'production') 'En Producción los asientos se registran en su contabilidad real.',
          ],
          confirmLabel: 'Cambiar ambiente',
          destructive: true);
      if (!ok) return;
    }
    setState(() => _env = next);
  }

  Future<void> _save(bool hadSecret, String oldEnv) async {
    if (!_form.currentState!.validate()) return;
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
    } catch (e) {
      if (mounted) showSnack(context, 'No se pudieron guardar las credenciales: $e', error: true);
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
                  obscureText: !_showSecret,
                  decoration: InputDecoration(
                    labelText: c.hasSecret ? 'Client Secret' : 'Client Secret *',
                    helperText: c.hasSecret
                        ? 'Guardado de forma cifrada (no se muestra). Déjelo vacío para conservarlo.'
                        : 'Requerido la primera vez.',
                    suffixIcon: IconButton(
                      tooltip: _showSecret ? 'Ocultar lo escrito' : 'Mostrar lo escrito',
                      icon: Icon(_showSecret ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showSecret = !_showSecret),
                    ),
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
                onSelectionChanged: isAdmin ? (s) => _changeEnv(s.first) : null,
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
  bool _testing = false;
  ({bool ok, String message, DateTime at})? _test;

  /// Read-only check: asks QuickBooks for the company name.
  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _test = null;
    });
    try {
      final name = await ref.read(qboApiClientProvider).companyName();
      _test = (ok: true, message: 'QuickBooks respondió: ${name ?? 'compañía conectada'}.', at: DateTime.now());
    } on QboApiException catch (e) {
      _test = (ok: false, message: e.message, at: DateTime.now());
    } catch (e) {
      _test = (ok: false, message: '$e', at: DateTime.now());
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

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
        message: 'RM Ledger Sync dejará de enviar asientos (incluidas las programaciones) hasta que vuelva a conectar.',
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
        else ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.cloud_done_outlined, color: context.rm.successIcon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(c.companyName ?? 'Compañía conectada', style: Theme.of(context).textTheme.titleMedium),
                  const StatusChip(label: 'Conectado', tone: RmTone.success),
                  StatusChip(
                    label: c.environment == 'production' ? 'Producción' : 'Sandbox (pruebas)',
                    tone: c.environment == 'production' ? RmTone.warning : RmTone.info,
                    icon: c.environment == 'production' ? Icons.business_outlined : Icons.science_outlined,
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Realm ${c.realmId} · Conectado: ${Dates.dmyHm(c.connectedAt)}'
                    '${c.refreshTokenExpiresAt != null ? ' · Autorización vigente hasta ${Dates.dmy(c.refreshTokenExpiresAt!)}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ]),
          if (creds != null && creds.environment != c.environment)
            GuidanceBanner(
              kind: GuidanceKind.warning,
              title: 'El ambiente guardado no coincide con la conexión',
              message: 'Las credenciales están en ${creds.environment == 'production' ? 'Producción' : 'Sandbox'}, '
                  'pero la conexión activa es de ${c.environment == 'production' ? 'Producción' : 'Sandbox'}. '
                  'Reconecte para usar el nuevo ambiente.',
            ),
          if (_test != null)
            GuidanceBanner(
              kind: _test!.ok ? GuidanceKind.success : GuidanceKind.error,
              title: _test!.ok ? 'Conexión con QuickBooks verificada' : 'QuickBooks no respondió',
              message: '${_test!.message}\nProbado: ${Dates.dmyHm(_test!.at)}'
                  '${_test!.ok ? '' : '\nSi la autorización venció, use "Reconectar".'}',
            ),
        ],
        if (_waiting)
          const GuidanceBanner(
            kind: GuidanceKind.info,
            title: 'Esperando la autorización en el navegador…',
            message: 'Complete los pasos en la página de Intuit. Cuando vea "¡Conectado!", vuelva a esta ventana.',
          ),
        if (_error != null) GuidanceBanner(kind: GuidanceKind.error, title: 'No se pudo conectar', message: _error),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
          if (c != null)
            OutlinedButton.icon(
              onPressed: _testing || _waiting ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check),
              label: const Text('Probar conexión'),
            ),
          if (isAdmin && c != null)
            OutlinedButton.icon(onPressed: _waiting ? null : _disconnect, icon: const Icon(Icons.link_off), label: const Text('Desconectar')),
          if (isAdmin)
            Tooltip(
              message: hasCreds ? '' : 'Primero guarde el Client ID y el Client Secret.',
              child: FilledButton.icon(
                onPressed: _waiting || !hasCreds ? null : _connect,
                icon: const Icon(Icons.link),
                label: Text(c == null ? 'Conectar con QuickBooks' : 'Reconectar'),
              ),
            ),
        ]),
      ]),
    );
  }
}
