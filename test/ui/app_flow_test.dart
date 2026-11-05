import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/app.dart';
import 'package:rmqbsync/app/providers.dart';
import 'package:rmqbsync/data/db/repositories.dart';
import 'package:rmqbsync/data/pos/pos_providers.dart';
import 'package:rmqbsync/features/onboarding/tour.dart';
import 'package:rmqbsync/features/settings/pos_api_form.dart';
import 'package:rmqbsync/services/auth_service.dart';
import 'package:rmqbsync/services/service_providers.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_container.dart';

/// Pumps the real app with an in-memory DB.
Future<TestEnv> pumpApp(WidgetTester tester, {FakeAdapter? adapter}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final t = makeContainer(
    adapter: adapter ?? FakeAdapter((o) async => const FakeResponse(200, [])),
    overrides: [passwordHasherProvider.overrideWithValue(PasswordHasher(iterations: 1000))],
  );
  addTearDown(() async {
    t.container.dispose();
    await t.db.close();
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: t.container, child: const RmqbApp()));
  await tester.pumpAndSettle();
  return t;
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

Future<void> settle(WidgetTester tester) async {
  // Drift / async DB work completes outside the fake clock.
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('first-time user: login → forced password change → setup assistant', (tester) async {
    late String temp;
    final t = await pumpApp(tester);
    await tester.runAsync(() async {
      temp = (await t.container.read(authServiceProvider).ensureSeedAdmin(writeFile: false))!;
    });
    t.container.read(firstRunPasswordProvider.notifier).set(temp);
    await settle(tester);

    expect(find.text('Primer uso'), findsOneWidget);
    expect(find.textContaining('Contraseña temporal: $temp'), findsOneWidget);

    // Wrong password → Spanish error with remaining attempts.
    await tester.enterText(find.widgetWithText(TextFormField, 'Usuario *'), 'admin');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña *'), 'mala');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await settle(tester);
    expect(find.textContaining('Le quedan 4 intento'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña *'), temp);
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await settle(tester);
    expect(find.text('Cambiar contraseña'), findsWidgets);
    expect(find.textContaining('reemplazar la contraseña temporal'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña temporal *'), temp);
    await tester.enterText(find.widgetWithText(TextFormField, 'Nueva contraseña *'), 'Tienda2026');
    await tester.enterText(find.widgetWithText(TextFormField, 'Repita la nueva contraseña *'), 'Tienda2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar contraseña'));
    await settle(tester);

    // Admin is taken to the setup assistant.
    expect(find.text('Asistente de configuración'), findsWidgets);
    expect(find.text('Paso 1 de 6: Bienvenida'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Siguiente'));
    await settle(tester);
    expect(find.text('Paso 2 de 6: API del POS'), findsOneWidget);

    // Cannot continue without a POS address.
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Siguiente'));
    await settle(tester);
    expect(find.text('• Aplique una dirección del POS.'), findsOneWidget);

    // Help panel (F1 equivalent) shows the article for this route without losing state.
    await tester.tap(find.byTooltip('Ayuda de esta pantalla (F1)'));
    await settle(tester);
    expect(find.text('Ayuda: Asistente de configuración'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar ayuda (Esc)'));
    await settle(tester);
    expect(find.text('Paso 2 de 6: API del POS'), findsOneWidget);
  });

  testWidgets('POS form validates host/port, warns on public IP and applies live', (tester) async {
    final adapter = FakeAdapter((o) async => const FakeResponse(200, []));
    final t = await pumpApp(tester, adapter: adapter);
    late AppUser admin;
    await tester.runAsync(() async {
      final auth = t.container.read(authServiceProvider);
      final temp = (await auth.ensureSeedAdmin(writeFile: false))!;
      admin = await auth.login('admin', temp);
      admin = await auth.changePassword(admin, temp, 'Tienda2026');
      await t.container.read(settingsRepositoryProvider).setBool(SettingKeys.setupWizardDone, true);
      await t.container.read(settingsRepositoryProvider).setBool(SettingKeys.tourDone('admin'), true);
    });
    t.container.read(sessionProvider.notifier).set(admin);
    await settle(tester);
    expect(find.text('Hola, Administrador'), findsOneWidget);

    await tester.tap(find.text('Configuración').first);
    await settle(tester);
    expect(find.byType(PosApiForm), findsOneWidget);

    final host = find.byKey(const Key('pos-host'));
    final port = find.byKey(const Key('pos-port'));
    await tester.ensureVisible(host);
    await tester.enterText(host, '300.1.1.1');
    await tester.enterText(port, '70000');
    await settle(tester);
    expect(find.textContaining('Dirección no válida'), findsOneWidget);
    expect(find.text('El puerto debe ser un número entre 1 y 65535.'), findsOneWidget);

    await tester.enterText(host, '8.8.8.8');
    await tester.enterText(port, '8180');
    await settle(tester);
    expect(find.text('La dirección no es de la red local'), findsOneWidget);
    expect(find.text('http://8.8.8.8:8180'), findsOneWidget);

    await tester.enterText(host, '192.168.100.175');
    await settle(tester);
    expect(find.text('La dirección no es de la red local'), findsNothing);

    await tester.ensureVisible(find.text('Probar conexión'));
    await tester.tap(find.text('Probar conexión'));
    await settle(tester);
    expect(find.text('Conexión exitosa'), findsOneWidget);

    await tester.ensureVisible(find.text('Aplicar cambios').last);
    await tester.tap(find.text('Aplicar cambios').last);
    await settle(tester);
    expect(find.text('Cambios aplicados'), findsOneWidget);
    expect(t.container.read(posDioProvider)?.options.baseUrl, 'http://192.168.100.175:8180');

    // "Guíame" guides the current screen (Configuración), not the global tour.
    await tester.tap(find.text('Guíame'));
    await settle(tester);
    expect(find.text('Guía 1 de 4'), findsOneWidget);
    expect(find.text('QuickBooks Online'), findsWidgets);
    await tester.tap(find.text('Cerrar').last);
    await settle(tester);
    expect(find.textContaining('Guía '), findsNothing);
  });

  testWidgets('onboarding tour: skip persists, restart shows it again', (tester) async {
    final t = await pumpApp(tester);
    late AppUser admin;
    await tester.runAsync(() async {
      final auth = t.container.read(authServiceProvider);
      final temp = (await auth.ensureSeedAdmin(writeFile: false))!;
      admin = await auth.changePassword(await auth.login('admin', temp), temp, 'Tienda2026');
      await t.container.read(settingsRepositoryProvider).setBool(SettingKeys.setupWizardDone, true);
    });
    t.container.read(sessionProvider.notifier).set(admin);
    await settle(tester);

    expect(find.text('Recorrido 1 de ${tourSteps.length}'), findsOneWidget);
    await tester.tap(find.text('Siguiente').last);
    await settle(tester);
    expect(find.text('Recorrido 2 de ${tourSteps.length}'), findsOneWidget);
    await tester.tap(find.text('Omitir'));
    await settle(tester);
    expect(find.textContaining('Recorrido '), findsNothing);

    late bool done;
    await tester.runAsync(() async {
      done = await t.container.read(settingsRepositoryProvider).getBool(SettingKeys.tourDone('admin'));
    });
    expect(done, isTrue);

    // Restart from the "Guíame" button resumes at the beginning.
    await tester.runAsync(() => t.container.read(tourProvider.notifier).restart());
    await settle(tester);
    expect(find.text('Recorrido 1 de ${tourSteps.length}'), findsOneWidget);
    await tester.tap(find.text('Pausar'));
    await settle(tester);
    expect(find.textContaining('Recorrido '), findsNothing);
  });
}
