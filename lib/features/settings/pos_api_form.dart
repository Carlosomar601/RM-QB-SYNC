import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../core/pos_address.dart';
import '../../data/pos/pos_client.dart';
import '../../data/pos/pos_dtos.dart';
import '../../data/pos/pos_providers.dart';
import '../../services/service_providers.dart';
import '../../ui/guided/guided.dart';

/// "Acceso a la API del POS": edit protocol / host / port (+ advanced),
/// test the connection, and apply live. Admin-only edits.
class PosApiForm extends ConsumerStatefulWidget {
  const PosApiForm({super.key, this.onApplied});

  final void Function(PosAddress address)? onApplied;

  @override
  ConsumerState<PosApiForm> createState() => PosApiFormState();
}

class PosApiFormState extends ConsumerState<PosApiForm> {
  final _form = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '8180');
  final _basePath = TextEditingController();
  final _timeout = TextEditingController();
  final _keyHeader = TextEditingController(text: 'X-Api-Key');
  final _keyValue = TextEditingController();
  String _protocol = 'http';
  bool _useApiKey = false;
  bool _loaded = false;
  bool _restoredDraft = false;
  bool _testing = false;
  bool _saving = false;
  PosConnectionTestResult? _test;
  String? _testedUrl;
  String? _applied;

  static const _draftKey = 'posApi';

  @override
  void dispose() {
    for (final c in [_host, _port, _basePath, _timeout, _keyHeader, _keyValue]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(PosAddress a) {
    _protocol = a.protocol;
    _host.text = a.host;
    _port.text = '${a.port}';
    _basePath.text = a.basePath;
    _timeout.text = a.timeoutSeconds?.toString() ?? '';
  }

  Future<void> _load(PosConfig cfg) async {
    _loaded = true;
    if (cfg.address != null) _fill(cfg.address!);
    _useApiKey = cfg.hasApiKey;
    if (cfg.apiKeyHeader != null) _keyHeader.text = cfg.apiKeyHeader!;
    final draft = await ref.read(draftStoreProvider).read(_draftKey);
    if (draft != null && mounted) {
      final d = PosAddress.fromJson(draft);
      if (d.isConfigured && d != cfg.address) {
        _fill(d);
        _restoredDraft = true;
      }
    }
    if (mounted) setState(() {});
  }

  /// Current form value, or null when invalid.
  PosAddress? get value {
    if (PosAddressValidator.validateHost(_host.text) != null || PosAddressValidator.validatePort(_port.text) != null) {
      return null;
    }
    var host = _host.text.trim();
    if (host.startsWith('[') && host.endsWith(']')) host = host.substring(1, host.length - 1);
    return PosAddress(
      protocol: _protocol,
      host: host,
      port: int.parse(_port.text.trim()),
      basePath: PosAddressValidator.normalizeBasePath(_basePath.text),
      timeoutSeconds: int.tryParse(_timeout.text.trim()),
    );
  }

  void _changed() {
    setState(() {});
    final v = value;
    if (v != null) ref.read(draftStoreProvider).save(_draftKey, v.toJson());
  }

  Future<void> _testConnection() async {
    if (!_form.currentState!.validate()) return;
    final addr = value!;
    setState(() {
      _testing = true;
      _test = null;
    });
    final client = RetailManagerPosClient(
      buildPosDio(addr,
          apiKeyHeader: _useApiKey ? _keyHeader.text.trim() : null,
          apiKeyValue: _useApiKey && _keyValue.text.isNotEmpty ? _keyValue.text : ref.read(posConfigProvider).value?.apiKeyValue,
          adapter: ref.read(httpAdapterProvider)),
      clock: ref.read(clockProvider),
    );
    final r = await client.testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _test = r;
      _testedUrl = addr.baseUrl;
    });
  }

  Future<void> _apply() async {
    if (!_form.currentState!.validate()) return;
    final addr = value!;
    final user = ref.read(sessionProvider)!;
    final testedOk = _test?.ok == true && _testedUrl == addr.baseUrl;
    if (!testedOk) {
      final go = await confirmAction(context,
          title: 'Aplicar sin una prueba exitosa',
          message: 'No ha probado esta dirección o la prueba falló. Si la dirección es incorrecta, '
              'las sincronizaciones fallarán hasta que la corrija.',
          confirmLabel: 'Aplicar de todas formas');
      if (!go) return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(posConfigProvider.notifier).save(
            address: addr,
            username: user.username,
            apiKeyHeader: _useApiKey ? _keyHeader.text.trim() : '',
            apiKeyValue: _useApiKey && _keyValue.text.isNotEmpty ? _keyValue.text : null,
          );
      await ref.read(draftStoreProvider).clear(_draftKey);
      _keyValue.clear();
      if (!mounted) return;
      setState(() {
        _applied = addr.baseUrl;
        _restoredDraft = false;
      });
      ref.invalidate(setupStatusProvider);
      widget.onApplied?.call(addr);
    } catch (e) {
      if (mounted) showSnack(context, 'No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfgAsync = ref.watch(posConfigProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin ?? false;
    final cfg = cfgAsync.value;
    if (cfg == null) return const LoadingBox();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(cfg));
    }

    final v = value;
    final hostValid = PosAddressValidator.validateHost(_host.text) == null;
    final publicWarning = hostValid && !PosAddressValidator.isPrivateLan(_host.text);

    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isAdmin)
            const GuidanceBanner(
                kind: GuidanceKind.info,
                title: 'Solo lectura',
                message: 'Solo un administrador puede cambiar la dirección del POS.'),
          if (_restoredDraft)
            GuidanceBanner(
              kind: GuidanceKind.info,
              title: 'Se restauró un borrador sin aplicar',
              message: 'Estos valores aún no están en uso. Pruébelos y presione "Aplicar cambios", o descarte el borrador.',
              actionLabel: 'Descartar borrador',
              onAction: () async {
                await ref.read(draftStoreProvider).clear(_draftKey);
                if (cfg.address != null) _fill(cfg.address!);
                setState(() => _restoredDraft = false);
              },
            ),
          Text('Actualmente en uso: ${cfg.address?.baseUrl ?? 'ninguna (sin configurar)'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (cfg.history.isNotEmpty) ...[
            const FieldLabel('Direcciones recientes', help: 'Toque una para llenar el formulario. No se aplica hasta presionar "Aplicar cambios".'),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final h in cfg.history)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(h.shortLabel),
                  tooltip: h.baseUrl,
                  onPressed: isAdmin
                      ? () {
                          _fill(h);
                          _changed();
                        }
                      : null,
                ),
            ]),
            const SizedBox(height: 16),
          ],
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.start, children: [
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                key: ValueKey('proto-$_protocol'),
                isExpanded: true,
                initialValue: _protocol,
                decoration: const InputDecoration(labelText: 'Protocolo *'),
                items: const [
                  DropdownMenuItem(value: 'http', child: Text('http')),
                  DropdownMenuItem(value: 'https', child: Text('https')),
                ],
                onChanged: isAdmin
                    ? (x) {
                        _protocol = x ?? 'http';
                        _changed();
                      }
                    : null,
              ),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                key: const Key('pos-host'),
                controller: _host,
                enabled: isAdmin,
                decoration: const InputDecoration(
                  labelText: 'Host / IP *',
                  hintText: '192.168.100.175',
                  helperText: 'IPv4, IPv6 o nombre del equipo del POS',
                ),
                validator: PosAddressValidator.validateHost,
                onChanged: (_) => _changed(),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextFormField(
                key: const Key('pos-port'),
                controller: _port,
                enabled: isAdmin,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Puerto *', hintText: '8180', helperText: '1 – 65535'),
                validator: PosAddressValidator.validatePort,
                onChanged: (_) => _changed(),
              ),
            ),
          ]),
          AdvancedOptions(children: [
            Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(
                width: 220,
                child: TextFormField(
                  controller: _basePath,
                  enabled: isAdmin,
                  decoration: const InputDecoration(labelText: 'Ruta base (opcional)', hintText: '/api'),
                  validator: PosAddressValidator.validateBasePath,
                  onChanged: (_) => _changed(),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextFormField(
                  controller: _timeout,
                  enabled: isAdmin,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Tiempo de espera (seg.)', hintText: '60', helperText: 'Vacío = 60 s de respuesta'),
                  validator: PosAddressValidator.validateTimeout,
                  onChanged: (_) => _changed(),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _useApiKey,
              onChanged: isAdmin ? (x) => setState(() => _useApiKey = x) : null,
              title: const Text('Enviar clave de API en un encabezado'),
              subtitle: const Text('Desactivado por defecto. La clave se guarda cifrada en Windows.'),
            ),
            if (_useApiKey)
              Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _keyHeader,
                    enabled: isAdmin,
                    decoration: const InputDecoration(labelText: 'Nombre del encabezado'),
                    validator: (x) => _useApiKey && (x ?? '').trim().isEmpty ? 'Requerido.' : null,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: _keyValue,
                    enabled: isAdmin,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Clave',
                      helperText: cfg.hasApiKey ? 'Vacío = conservar la clave guardada' : null,
                    ),
                    validator: (x) => _useApiKey && !cfg.hasApiKey && (x ?? '').isEmpty ? 'Escriba la clave.' : null,
                  ),
                ),
              ]),
          ]),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'URL resultante (solo lectura)', prefixIcon: Icon(Icons.link)),
            child: SelectableText(v?.baseUrl ?? '—'),
          ),
          if (publicWarning)
            const GuidanceBanner(
              kind: GuidanceKind.warning,
              title: 'La dirección no es de la red local',
              message: 'El POS normalmente está en la red de la tienda (10.x, 172.16–31.x o 192.168.x). '
                  'Verifique que no sea un error; los datos viajarían por Internet sin cifrar si usa http.',
            ),
          if (_test != null)
            GuidanceBanner(
              kind: _test!.ok ? GuidanceKind.success : GuidanceKind.error,
              title: _test!.ok ? 'Conexión exitosa' : 'No se pudo conectar',
              message: '${_test!.message}${_testedUrl != null ? '\nProbado: $_testedUrl' : ''}',
            ),
          if (_applied != null)
            GuidanceBanner(
              kind: GuidanceKind.success,
              title: 'Cambios aplicados',
              message: 'Desde ahora RM Ledger Sync usa $_applied. No necesita reiniciar.',
            ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
            OutlinedButton.icon(
              onPressed: _testing || v == null ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check),
              label: const Text('Probar conexión'),
            ),
            if (isAdmin)
              FilledButton.icon(
                onPressed: _saving || v == null ? null : _apply,
                icon: const Icon(Icons.save),
                label: const Text('Aplicar cambios'),
              ),
          ]),
        ],
      ),
    );
  }
}
