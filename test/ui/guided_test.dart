import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/app_state.dart';
import 'package:rmqbsync/data/db/app_database.dart';
import 'package:rmqbsync/features/help/help_content.dart';
import 'package:rmqbsync/ui/guided/guided.dart';

void main() {
  testWidgets('StepWizard: validation blocks Siguiente, Atrás keeps state, Completar runs', (tester) async {
    final ctl = TextEditingController();
    var completed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StepWizard(
            steps: [
              WizardStep(
                title: 'Nombre',
                explanation: 'Escriba un nombre',
                instructions: const ['Escriba su nombre'],
                validate: () => ctl.text.isEmpty ? ['Falta el nombre.'] : const [],
                builder: (_) => TextField(key: const Key('name'), controller: ctl),
              ),
              WizardStep(title: 'Fin', explanation: 'Listo', builder: (_) => const Text('paso-final')),
            ],
            onComplete: () async => completed = true,
          ),
        ),
      ),
    ));

    expect(find.text('Paso 1 de 2: Nombre'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('• Falta el nombre.'), findsOneWidget);
    expect(find.text('Paso 1 de 2: Nombre'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('name')), 'Ana');
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Paso 2 de 2: Fin'), findsOneWidget);

    await tester.tap(find.text('Atrás'));
    await tester.pump();
    expect(find.text('Paso 1 de 2: Nombre'), findsOneWidget);
    expect(ctl.text, 'Ana');
    expect(find.widgetWithText(TextField, 'Ana'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.tap(find.text('Completar'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('GuidanceBanner shows fix action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GuidanceBanner(
          kind: GuidanceKind.error,
          title: 'Error X',
          message: 'detalle',
          actionLabel: 'Cómo resolverlo',
          onAction: () => tapped = true,
        ),
      ),
    ));
    await tester.tap(find.text('Cómo resolverlo'));
    expect(tapped, isTrue);
  });

  test('every screen route has a contextual help article', () {
    for (final r in [
      Routes.dashboard,
      Routes.sincronizaciones,
      Routes.reportes,
      Routes.vistaPrevia,
      Routes.mapeo,
      Routes.configuracion,
      Routes.historial,
      Routes.auditoria,
      Routes.usuarios,
      Routes.ayuda,
      Routes.login,
      Routes.asistente,
    ]) {
      expect(HelpContent.screens.containsKey(r), isTrue, reason: r);
    }
    expect(HelpContent.forRoute('/vista-previa?desde=2026-01-01').id, 'preview');
    expect(HelpContent.forRoute('/configuracion').title, 'Configuración');
  });

  test('recommended next action follows setup order', () {
    SetupStatus s({bool pos = false, bool creds = false, bool conn = false, int mapped = 0, bool sched = false, DateTime? last}) =>
        SetupStatus(
          posConfigured: pos,
          qboCredentials: creds,
          qboConnected: conn,
          mappedCount: mapped,
          totalCategories: 10,
          scheduleEnabled: sched,
          lastSyncAt: last,
        );
    expect(recommendedNextAction(s()).label, contains('API del POS'));
    expect(recommendedNextAction(s(pos: true)).label, contains('credenciales'));
    expect(recommendedNextAction(s(pos: true, creds: true)).label, contains('Conectar'));
    expect(recommendedNextAction(s(pos: true, creds: true, conn: true, mapped: 7)).why, contains('3 categoría'));
    expect(recommendedNextAction(s(pos: true, creds: true, conn: true, mapped: 10)).route, '/vista-previa');
    expect(recommendedNextAction(s(pos: true, creds: true, conn: true, mapped: 10, last: DateTime(2026))).route, '/sincronizaciones');
    expect(s(pos: true, creds: true, conn: true, mapped: 10).ready, isTrue);
  });

  SyncHistoryRow run(int id, String status, {String trigger = 'Scheduled', int day = 1}) => SyncHistoryRow(
        id: id,
        ranAt: DateTime(2026, 11, day, 10, 55),
        trigger: trigger,
        performedBy: 'Sistema',
        fromDate: DateTime(2026, 11, day),
        toDate: DateTime(2026, 11, day),
        status: status,
        errorMessage: status == 'Failed' ? 'Error 401 de QuickBooks' : null,
      );

  test('SyncHealth separates operational health from setup', () {
    // Newest first, as watchRecent returns them.
    final h = SyncHealth.fromRows([
      run(5, 'Running', day: 5),
      run(4, 'Failed', day: 4),
      run(3, 'Failed', trigger: 'Manual', day: 3),
      run(2, 'Success', day: 2),
      run(1, 'Failed', day: 1),
    ]);
    expect(h.lastRun!.id, 4, reason: 'running rows are ignored');
    expect(h.lastFailed, isTrue);
    expect(h.lastSuccess!.id, 2);
    expect(h.failuresSinceSuccess, 2);
    expect(h.lastScheduled!.id, 4);

    final none = SyncHealth.fromRows(const []);
    expect(none.lastRun, isNull);
    expect(none.neverSucceeded, isTrue);
    expect(none.failuresSinceSuccess, 0);
  });

  test('recommended next action reflects failed runs and expired authorization', () {
    final now = DateTime(2026, 11, 4);
    final ready = SetupStatus(
      posConfigured: true,
      qboCredentials: true,
      qboConnected: true,
      mappedCount: 10,
      totalCategories: 10,
      scheduleEnabled: true,
      lastSyncAt: DateTime(2026, 11, 2),
      authExpiresAt: DateTime(2027, 2, 13),
    );
    final failing = SyncHealth.fromRows([run(2, 'Failed', day: 3), run(1, 'Failed', day: 2)]);
    final a = recommendedNextAction(ready, failing, now);
    expect(a.route, Routes.historial);
    expect(a.why, contains('2 sincronizaciones fallaron'));

    final healthy = SyncHealth.fromRows([run(1, 'Success', day: 3)]);
    expect(recommendedNextAction(ready, healthy, now).label, 'Revisar Vista Previa');

    // Never a "first sync" suggestion when it has only ever failed? It must
    // point to the error instead.
    final neverOk = SetupStatus(
      posConfigured: true,
      qboCredentials: true,
      qboConnected: true,
      mappedCount: 10,
      totalCategories: 10,
      scheduleEnabled: true,
    );
    expect(recommendedNextAction(neverOk, SyncHealth.fromRows([run(1, 'Failed')]), now).route, Routes.historial);

    final expired = SetupStatus(
      posConfigured: true,
      qboCredentials: true,
      qboConnected: true,
      mappedCount: 10,
      totalCategories: 10,
      scheduleEnabled: true,
      authExpiresAt: DateTime(2026, 11, 1),
    );
    expect(recommendedNextAction(expired, healthy, now).label, 'Reconectar QuickBooks');
    final soon = SetupStatus(
      posConfigured: true,
      qboCredentials: true,
      qboConnected: true,
      mappedCount: 10,
      totalCategories: 10,
      scheduleEnabled: true,
      authExpiresAt: DateTime(2026, 11, 10),
    );
    expect(recommendedNextAction(soon, healthy, now).why, contains('6 día'));
  });

  testWidgets('StepWizard marks a failed step and explains blocked steps', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StepWizard(
            steps: [
              WizardStep(title: 'Uno', explanation: 'x', validate: () => ['Falta algo.'], builder: (_) => const SizedBox()),
              WizardStep(
                  title: 'Dos', explanation: 'y', blockedReason: 'Primero conecte QuickBooks.', builder: (_) => const SizedBox()),
            ],
            onComplete: () async {},
          ),
        ),
      ),
    ));
    expect(find.bySemanticsLabel(RegExp('Paso 2, Dos, bloqueado: Primero conecte QuickBooks')), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('• Falta algo.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Paso 1, Uno, actual, con datos por corregir')), findsOneWidget);
  });
}
