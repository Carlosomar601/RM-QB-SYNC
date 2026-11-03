import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/core/account_mapping.dart';
import 'package:rmqbsync/core/exceptions.dart';
import 'package:rmqbsync/core/journal_entry.dart';
import 'package:rmqbsync/core/pos_sales_summary.dart';

/// Port of the legacy C# JournalEntryBuilderTests (same fixture values).
void main() {
  final from = DateTime(2025, 5, 1);
  final to = DateTime(2025, 5, 21);
  const builder = JournalEntryBuilder();

  Map<String, AccountMapping> mappings() {
    AccountMapping m(String cat, String id, String name, PostingSide side,
            {EntityType? et, String? eid, String? ename}) =>
        AccountMapping(
          category: cat,
          accountId: id,
          accountName: name,
          side: side,
          entityType: et,
          entityId: eid,
          entityName: ename,
        );
    final list = [
      m('VentaNeta', '1', 'Venta Neta', PostingSide.debit),
      m('Fletes', '2', 'Fletes', PostingSide.debit),
      m('APMunTax', '3', 'AP Mun Tax', PostingSide.credit),
      m('APStateTax', '4', 'AP State Tax', PostingSide.credit),
      m('Efectivo', '5', 'Efectivo', PostingSide.credit),
      m('Tarjetas', '6', 'Tarjetas', PostingSide.credit),
      m('TarjetasDynamics', '7', 'Tarjetas Dynamics', PostingSide.credit),
      m('Cheques', '8', 'Cheques', PostingSide.credit),
      m('DynamicsRM', '9', 'Dynamics RM', PostingSide.credit),
      m('CuentasACobrar', '10', 'Cuentas a Cobrar', PostingSide.credit,
          et: EntityType.customer, eid: '1', ename: 'Cliente Generico'),
      m('Devoluciones', '11', 'Devoluciones', PostingSide.credit),
    ];
    return {for (final x in list) x.category: x};
  }

  PosSalesSummary screenshotSummary({double cuentasACobrar = 300}) => PosSalesSummary(
        fromDate: from,
        toDate: to,
        categories: [
          const PosCategoryAmount('Ventas', 'VentaNeta', 12450),
          const PosCategoryAmount('Ventas', 'Fletes', 350),
          const PosCategoryAmount('Ventas', 'APMunTax', 620),
          const PosCategoryAmount('Ventas', 'APStateTax', 390),
          const PosCategoryAmount('Pagos', 'Efectivo', 3000),
          const PosCategoryAmount('Pagos', 'Tarjetas', 6000),
          const PosCategoryAmount('Pagos', 'TarjetasDynamics', 1000),
          const PosCategoryAmount('Pagos', 'Cheques', 600),
          const PosCategoryAmount('Pagos', 'DynamicsRM', 800),
          PosCategoryAmount('Pagos', 'CuentasACobrar', cuentasACobrar),
          const PosCategoryAmount('Pagos', 'Devoluciones', 90),
        ],
      );

  test('Build_WithBalancedScreenshotData_ProducesBalancedEntry', () {
    final draft = builder.build(screenshotSummary(), mappings(), 'Ventas test');
    expect(draft.lines, hasLength(11));
    expect(draft.totalDebit, 12800.00);
    expect(draft.totalCredit, 12800.00);
    expect(draft.difference, 0);
    expect(draft.isBalanced, isTrue);
    expect(draft.canSubmit, isTrue);
    expect(draft.txnDate, to);
  });

  test('Build_WithUnbalancedData_ReturnsDraftMarkedNotBalanced', () {
    final draft = builder.build(screenshotSummary(cuentasACobrar: 250), mappings(), 'x');
    expect(draft.isBalanced, isFalse);
    expect(draft.difference, 50.00);
    expect(draft.canSubmit, isFalse);
  });

  test('Build_WithMissingMapping_ThrowsAccountMappingNotFoundException', () {
    final summary = PosSalesSummary(
      fromDate: from,
      toDate: to,
      categories: const [PosCategoryAmount('Ventas', 'UnknownCategory', 100)],
    );
    expect(
      () => builder.build(summary, mappings(), 'x'),
      throwsA(isA<AccountMappingNotFoundException>()
          .having((e) => e.category, 'category', 'UnknownCategory')),
    );
  });

  test('Build_SkipsZeroAmountCategories', () {
    final summary = PosSalesSummary(
      fromDate: from,
      toDate: to,
      categories: const [
        PosCategoryAmount('Ventas', 'VentaNeta', 100),
        PosCategoryAmount('Ventas', 'Fletes', 0),
      ],
    );
    final draft = builder.build(summary, mappings(), 'x');
    expect(draft.lines, hasLength(1));
    expect(draft.lines.single.category, 'VentaNeta');
  });

  test('Build_PreservesEntityInfoForARAndAPLines', () {
    final summary = PosSalesSummary(
      fromDate: from,
      toDate: to,
      categories: const [PosCategoryAmount('Pagos', 'CuentasACobrar', 700)],
    );
    final line = builder.build(summary, mappings(), 'x').lines.single;
    expect(line.entityType, EntityType.customer);
    expect(line.entityId, '1');
    expect(line.entityName, 'Cliente Generico');
  });

  test('uses absolute amounts and mapping description fallback', () {
    final m = mappings()
      ..['Devoluciones'] = mappings()['Devoluciones']!.copyWith(description: () => 'Devoluciones del período');
    final summary = PosSalesSummary(
      fromDate: from,
      toDate: to,
      categories: const [
        PosCategoryAmount('Pagos', 'Devoluciones', -90.456),
        PosCategoryAmount('Pagos', 'Efectivo', 10),
      ],
    );
    final draft = builder.build(summary, m, 'x');
    expect(draft.lines[0].amount, 90.46);
    expect(draft.lines[0].description, 'Devoluciones del período');
    expect(draft.lines[1].description, 'Efectivo');
  });

  test('missing required entity blocks submit', () {
    final m = mappings()..['CuentasACobrar'] = mappings()['CuentasACobrar']!.copyWith(entityId: () => '');
    final summary = PosSalesSummary(
      fromDate: from,
      toDate: to,
      categories: const [
        PosCategoryAmount('Ventas', 'VentaNeta', 700),
        PosCategoryAmount('Pagos', 'CuentasACobrar', 700),
      ],
    );
    final draft = builder.build(summary, m, 'x');
    expect(draft.isBalanced, isTrue);
    expect(draft.hasMissingEntities, isTrue);
    expect(draft.canSubmit, isFalse);
  });

  test('summary rejects toDate before fromDate and totals by group', () {
    expect(() => PosSalesSummary(fromDate: to, toDate: from, categories: const []), throwsArgumentError);
    expect(screenshotSummary().totalByGroup('ventas'), 13810);
    expect(screenshotSummary().totalByGroup('Pagos'), 11790);
  });

  test('default description format', () {
    expect(JournalEntryDraft.defaultDescription(from, to), 'Ventas del 01/05/2025 al 21/05/2025');
  });
}
