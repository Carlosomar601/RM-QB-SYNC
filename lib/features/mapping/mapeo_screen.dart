import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../app/providers.dart';
import '../../core/account_mapping.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/pos/pos_providers.dart';
import '../../data/quickbooks/qbo_models.dart';
import '../../data/quickbooks/qbo_providers.dart';
import '../../services/service_providers.dart';
import '../../ui/guided/guided.dart';
import '../help/help_content.dart';
import '../onboarding/tour.dart';

/// Amounts per category over the last 30 days (to show which have movement).
final last30DaysProvider = FutureProvider<Map<String, double>>((ref) async {
  final today = Dates.today(ref.watch(clockProvider)());
  final s = await ref.watch(posClientProvider).getSalesSummary(Dates.addDays(today, -30), today);
  return {for (final c in s.categories) c.category: c.amount};
});

/// Editable draft row.
class _Row {
  _Row(this.category);
  final String category;
  String? accountId;
  String? accountName;
  PostingSide side = PostingSide.debit;
  String description = '';
  EntityType? entityType;
  String? entityId;
  String? entityName;

  bool get complete => (accountId ?? '').isNotEmpty && (entityType == null || (entityId ?? '').isNotEmpty);

  static _Row from(String category, AccountMapping? m) {
    final r = _Row(category);
    r.side = PosCategories.groupOf(category) == PosGroups.ventas ? PostingSide.credit : PostingSide.debit;
    if (m != null) {
      r.accountId = m.accountId;
      r.accountName = m.accountName;
      r.side = m.side;
      r.description = m.description ?? '';
      r.entityType = m.entityType;
      r.entityId = m.entityId;
      r.entityName = m.entityName;
    }
    return r;
  }

  AccountMapping toMapping() => AccountMapping(
        category: category,
        accountId: accountId!,
        accountName: accountName ?? '',
        side: side,
        description: description.trim().isEmpty ? null : description.trim(),
        entityType: entityType,
        entityId: entityType == null ? null : entityId,
        entityName: entityType == null ? null : entityName,
      );

  Map<String, Object?> toJson() => {
        'accountId': accountId,
        'accountName': accountName,
        'side': side.qboName,
        'description': description,
        'entityType': entityType?.qboName,
        'entityId': entityId,
        'entityName': entityName,
      };

  void applyJson(Map<String, Object?> j) {
    accountId = j['accountId'] as String?;
    accountName = j['accountName'] as String?;
    side = PostingSide.parse((j['side'] as String?) ?? side.qboName);
    description = (j['description'] as String?) ?? '';
    entityType = EntityType.tryParse(j['entityType'] as String?);
    entityId = j['entityId'] as String?;
    entityName = j['entityName'] as String?;
  }
}

class MapeoScreen extends ConsumerWidget {
  const MapeoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PageBody(children: [
      ScreenHeader(
        icon: Icons.lan_outlined,
        title: 'Mapeo de Cuentas',
        purpose: 'Indique a qué cuenta de QuickBooks va cada categoría del POS y si va al Debe o al Haber.',
        nextHint: 'Al terminar, revise el asiento en Vista Previa.',
      ),
      MappingEditor(),
    ]);
  }
}

class MappingEditor extends ConsumerStatefulWidget {
  const MappingEditor({super.key, this.onApplied});
  final VoidCallback? onApplied;

  @override
  ConsumerState<MappingEditor> createState() => _MappingEditorState();
}

class _MappingEditorState extends ConsumerState<MappingEditor> {
  static const _draftKey = 'mapeo';
  Map<String, _Row>? _rows;
  bool _restored = false;
  ({int saved})? _done;

  /// Field errors appear only after the user tried to continue (not on load).
  bool _showErrors = false;

  Future<void> _init(Map<String, AccountMapping> saved) async {
    final cats = {...PosCategories.all, ...saved.keys}.toList();
    final rows = {for (final c in cats) c: _Row.from(c, saved[c])};
    final draft = await ref.read(draftStoreProvider).read(_draftKey);
    if (draft != null) {
      for (final e in draft.entries) {
        if (rows.containsKey(e.key) && e.value is Map) rows[e.key]!.applyJson((e.value as Map).cast());
      }
      _restored = true;
    }
    if (mounted) setState(() => _rows = rows);
  }

  void _changed() {
    setState(() {});
    ref.read(draftStoreProvider).save(_draftKey, {for (final r in _rows!.values) r.category: r.toJson()});
  }

  List<String> _problems(Iterable<String> cats) {
    final p = [
      for (final c in cats)
        if ((_rows![c]!.accountId ?? '').isEmpty)
          '${PosCategories.label(c)}: elija una cuenta.'
        else if (!_rows![c]!.complete)
          '${PosCategories.label(c)}: elija el ${_rows![c]!.entityType!.label.toLowerCase()}.',
    ];
    if (p.isNotEmpty && !_showErrors) setState(() => _showErrors = true);
    return p;
  }

  Future<void> _apply() async {
    final repo = ref.read(mappingRepositoryProvider);
    var n = 0;
    for (final r in _rows!.values) {
      if (r.complete) {
        await repo.upsert(r.toMapping());
        n++;
      }
    }
    await ref.read(auditRepositoryProvider).log(ref.read(sessionProvider)!.username, 'MapeoActualizado', '$n categorías');
    await ref.read(draftStoreProvider).clear(_draftKey);
    ref.invalidate(mappingsProvider);
    ref.invalidate(setupStatusProvider);
    setState(() {
      _done = (saved: n);
      _restored = false;
    });
    widget.onApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(qboConnectionProvider).value;
    if (conn == null) {
      return GuidanceBanner(
        kind: GuidanceKind.warning,
        title: 'Primero conecte QuickBooks',
        message: 'Para elegir cuentas necesitamos leer el catálogo de cuentas de su compañía en QuickBooks.',
        actionLabel: 'Ir a Configuración',
        onAction: () => context.go(Routes.configuracion),
      );
    }
    final saved = ref.watch(mappingsProvider);
    final accounts = ref.watch(qboAccountsProvider);
    final isAdmin = ref.watch(sessionProvider)?.isAdmin ?? false;

    if (saved.isLoading || accounts.isLoading) return const LoadingBox(message: 'Leyendo cuentas de QuickBooks…');
    if (accounts.hasError) {
      return GuidanceBanner(
        kind: GuidanceKind.error,
        title: 'No se pudieron leer las cuentas de QuickBooks',
        message: '${accounts.error}',
        actionLabel: 'Reintentar',
        onAction: () => ref.invalidate(qboAccountsProvider),
      );
    }
    if (_rows == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_rows == null) _init(saved.value ?? {});
      });
      return const LoadingBox();
    }

    if (_done != null) {
      return CompletionSummary(
        title: 'Mapeo guardado',
        message: 'Las cuentas quedaron asignadas y se usarán en la próxima vista previa y sincronización.',
        items: [
          SummaryItem('Categorías guardadas', '${_done!.saved}'),
          SummaryItem('Pendientes', '${_rows!.values.where((r) => !r.complete).length}'),
        ],
        nextActionLabel: 'Revisar el asiento en Vista Previa',
        onNextAction: () => context.go(Routes.vistaPrevia),
        secondaryLabel: 'Seguir editando',
        onSecondary: () => setState(() => _done = null),
      );
    }

    final last30 = ref.watch(last30DaysProvider);
    final accountList = accounts.value!;
    final ventas = _rows!.keys.where((c) => PosCategories.groupOf(c) == PosGroups.ventas).toList();
    final pagos = _rows!.keys.where((c) => PosCategories.groupOf(c) != PosGroups.ventas).toList();

    Widget group(List<String> cats) => Column(children: [
          for (final c in cats)
            _MappingRowEditor(
              row: _rows![c]!,
              accounts: accountList,
              amount30: last30.value?[c],
              enabled: isAdmin,
              showErrors: _showErrors,
              onChanged: _changed,
            ),
        ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!isAdmin)
        const GuidanceBanner(kind: GuidanceKind.info, title: 'Solo lectura', message: 'Solo un administrador puede cambiar el mapeo.'),
      if (_restored)
        GuidanceBanner(
          kind: GuidanceKind.info,
          title: 'Se restauró un borrador sin aplicar',
          message: 'Sus cambios anteriores siguen aquí. Termine y presione "Aplicar mapeo", o descarte el borrador.',
          actionLabel: 'Descartar borrador',
          onAction: () async {
            await ref.read(draftStoreProvider).clear(_draftKey);
            setState(() {
              _rows = null;
              _restored = false;
            });
          },
        ),
      if (last30.hasError)
        GuidanceBanner(
            kind: GuidanceKind.warning,
            title: 'No se pudieron leer los montos de los últimos 30 días del POS',
            message: '${last30.error}\nPuede mapear igualmente.'),
      TourTarget(
        id: 'mapeo:accounts',
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
          Text('${accountList.length} cuentas activas en QuickBooks', style: Theme.of(context).textTheme.bodySmall),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(qboAccountsProvider);
              ref.invalidate(qboCustomersProvider);
              ref.invalidate(qboVendorsProvider);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Volver a leer de QuickBooks'),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      TourTarget(id: 'mapeo:wizard', child: _wizard(ventas, pagos, group, isAdmin)),
    ]);
  }

  Widget _wizard(List<String> ventas, List<String> pagos, Widget Function(List<String>) group, bool isAdmin) {
    return StepWizard(
        completeLabel: 'Aplicar mapeo',
        steps: [
          WizardStep(
            title: 'Ventas',
            explanation: 'Montos que el POS reporta como ventas e impuestos. Normalmente van al Haber.',
            instructions: const [
              'Para cada categoría elija la cuenta de QuickBooks (puede escribir para buscar).',
              'Deje el lado recomendado (Haber) salvo que su contador indique otra cosa.',
              'Si la cuenta es de Cuentas por Cobrar, elija tipo "Cliente" y el cliente genérico.',
            ],
            example: 'Ej.: Venta neta → "Ventas"; IVU estatal → "IVU por pagar – Estatal".',
            validate: () => _problems(ventas),
            builder: (_) => group(ventas),
          ),
          WizardStep(
            title: 'Pagos',
            explanation: 'Formas de pago recibidas. Normalmente van al Debe (dinero que entra).',
            instructions: const [
              'Elija la cuenta donde se deposita cada forma de pago.',
              '"Pendiente de cobro" son ventas a crédito: use Cuentas por Cobrar con un Cliente.',
            ],
            example: 'Ej.: Efectivo → "Caja"; Tarjeta de crédito → "Depósitos por liquidar – Tarjetas".',
            validate: () => _problems(pagos),
            builder: (_) => group(pagos),
          ),
          WizardStep(
            title: 'Revisar y aplicar',
            explanation: 'Confirme el resumen. Al aplicar, el mapeo se usa de inmediato.',
            builder: (_) => _Review(rows: _rows!.values.toList()),
            validate: () => isAdmin ? const [] : ['Solo un administrador puede aplicar cambios.'],
          ),
        ],
        onComplete: _apply,
      );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.rows});
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(columns: const [
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Cuenta')),
          DataColumn(label: Text('Lado')),
          DataColumn(label: Text('Entidad')),
          DataColumn(label: Text('Estado')),
        ], rows: [
          for (final r in rows)
            DataRow(cells: [
              DataCell(Text(PosCategories.label(r.category))),
              DataCell(Text(r.accountName ?? '—')),
              DataCell(Text(r.side.label)),
              DataCell(Text(r.entityType == null ? '—' : '${r.entityType!.label}: ${r.entityName ?? '—'}')),
              DataCell(r.complete
                  ? const StatusChip(label: 'Completo', tone: RmTone.success)
                  : const StatusChip(label: 'Incompleto', tone: RmTone.warning)),
            ]),
        ]),
      );
}

class _MappingRowEditor extends ConsumerWidget {
  const _MappingRowEditor({
    required this.row,
    required this.accounts,
    required this.amount30,
    required this.enabled,
    required this.onChanged,
    this.showErrors = false,
  });

  final _Row row;
  final List<QboAccount> accounts;
  final double? amount30;
  final bool enabled;
  final bool showErrors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommended = PosCategories.groupOf(row.category) == PosGroups.ventas ? PostingSide.credit : PostingSide.debit;
    final t = Theme.of(context).textTheme;
    final entities = row.entityType == EntityType.customer
        ? ref.watch(qboCustomersProvider)
        : row.entityType == EntityType.vendor
            ? ref.watch(qboVendorsProvider)
            : null;

    final missingAccount = (row.accountId ?? '').isEmpty;
    final (chipLabel, chipTone) = row.complete
        ? ('Completo', RmTone.success)
        : missingAccount
            ? ('Falta cuenta', RmTone.warning)
            : ('Falta ${row.entityType?.label.toLowerCase() ?? 'entidad'}', RmTone.warning);

    // Neutral card; only the fields that need attention get warning/error styling.
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(PosCategories.label(row.category), style: t.titleMedium),
            Text('(${row.category})', style: t.bodySmall),
            StatusChip(label: chipLabel, tone: chipTone),
            if (amount30 != null)
              Money.toCents(amount30!) == 0
                  ? Text('·  Sin movimiento en 30 días', style: t.bodySmall)
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('·  Últimos 30 días: ', style: t.bodySmall),
                      MoneyText(amount30!, style: t.bodySmall),
                    ]),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            DropdownMenu<String>(
              key: ValueKey('acct-${row.category}-${row.accountId}'),
              width: 380,
              enabled: enabled,
              enableFilter: true,
              requestFocusOnTap: true,
              menuHeight: 360,
              initialSelection: accounts.any((a) => a.id == row.accountId) ? row.accountId : null,
              label: const Text('Cuenta de QuickBooks *'),
              hintText: 'Escriba para buscar…',
              errorText: showErrors && missingAccount ? 'Requerida: elija una cuenta' : null,
              dropdownMenuEntries: [
                for (final a in accounts)
                  DropdownMenuEntry(value: a.id, label: a.displayName, labelWidget: Text('${a.displayName}  ·  ${a.accountType ?? ''}')),
              ],
              onSelected: (id) {
                final a = accounts.firstWhere((x) => x.id == id);
                row.accountId = a.id;
                row.accountName = a.fullyQualifiedName ?? a.name;
                if (a.accountType == 'Accounts Receivable' && row.entityType == null) row.entityType = EntityType.customer;
                if (a.accountType == 'Accounts Payable' && row.entityType == null) row.entityType = EntityType.vendor;
                onChanged();
              },
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              SegmentedButton<PostingSide>(
                segments: const [
                  ButtonSegment(value: PostingSide.debit, label: Text('Debe')),
                  ButtonSegment(value: PostingSide.credit, label: Text('Haber')),
                ],
                selected: {row.side},
                onSelectionChanged: enabled
                    ? (s) {
                        row.side = s.first;
                        onChanged();
                      }
                    : null,
              ),
              HelpTip('Indica en qué lado del asiento contable se registrará esta categoría. '
                  'Recomendado: ${recommended.label}. Consulte a su contador si necesita cambiarlo.'),
            ]),
            if (row.side != recommended)
              Text('Diferente al recomendado (${recommended.label})',
                  style: t.bodySmall?.copyWith(color: context.rm.warningText)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<EntityType?>(
                isExpanded: true,
                key: ValueKey('et-${row.category}-${row.entityType}'),
                initialValue: row.entityType,
                decoration: const InputDecoration(labelText: 'Entidad'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Ninguna')),
                  DropdownMenuItem(value: EntityType.customer, child: Text('Cliente')),
                  DropdownMenuItem(value: EntityType.vendor, child: Text('Suplidor')),
                ],
                onChanged: enabled
                    ? (v) {
                        row.entityType = v;
                        row.entityId = null;
                        row.entityName = null;
                        onChanged();
                      }
                    : null,
              ),
            ),
            if (entities != null)
              entities.when(
                loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 18, color: context.rm.dangerIcon),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text('No se pudo leer la lista de ${row.entityType!.label.toLowerCase()}s.',
                        style: TextStyle(color: context.rm.dangerText)),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(row.entityType == EntityType.customer ? qboCustomersProvider : qboVendorsProvider),
                    child: const Text('Reintentar'),
                  ),
                ]),
                data: (list) => DropdownMenu<String>(
                  key: ValueKey('ent-${row.category}-${row.entityType}-${row.entityId}'),
                  width: 320,
                  enabled: enabled,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  menuHeight: 320,
                  initialSelection: list.any((x) => x.id == row.entityId) ? row.entityId : null,
                  label: Text('${row.entityType!.label} *'),
                  errorText: showErrors && (row.entityId ?? '').isEmpty ? 'Requerido' : null,
                  dropdownMenuEntries: [for (final x in list) DropdownMenuEntry(value: x.id, label: x.displayName)],
                  onSelected: (id) {
                    final x = list.firstWhere((e) => e.id == id);
                    row.entityId = x.id;
                    row.entityName = x.displayName;
                    onChanged();
                  },
                ),
              ),
            SizedBox(
              width: 320,
              child: TextFormField(
                initialValue: row.description,
                enabled: enabled,
                decoration: InputDecoration(
                  labelText: 'Descripción de la línea (opcional)',
                  hintText: row.category,
                ),
                onChanged: (v) {
                  row.description = v;
                  onChanged();
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
