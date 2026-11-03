import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/app_state.dart';
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
}
