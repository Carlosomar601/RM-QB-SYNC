import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/app/theme.dart';
import 'package:rmqbsync/app/theme_mode.dart';
import 'package:rmqbsync/data/db/repositories.dart';
import 'package:rmqbsync/app/providers.dart';
import 'package:rmqbsync/services/auth_service.dart';
import 'package:rmqbsync/services/service_providers.dart';

import '../helpers/test_container.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, b, t) in [
    ('claro', Brightness.light, RmTokens.light),
    ('oscuro', Brightness.dark, RmTokens.dark),
  ]) {
    group('Tema $name', () {
      test('construye y expone RmTokens', () {
        final theme = buildTheme(b);
        expect(theme.brightness, b);
        expect(theme.extension<RmTokens>(), same(t));
        expect(theme.scaffoldBackgroundColor, t.background);
        expect(theme.colorScheme.primary, t.interactive);
      });

      test('texto cumple WCAG AA (4.5:1) sobre todas las superficies', () {
        for (final fg in [t.textPrimary, t.textSecondary, t.textMuted]) {
          for (final bg in [t.background, t.sidebar, t.surface, t.surfaceAlt, t.surfaceGuide, t.navSelected]) {
            expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg sobre $bg');
          }
        }
      });

      test('enlaces y texto secundario cumplen AA sobre las superficies', () {
        // In the dark theme the status tints are mid-tones (Guía Visual), so
        // content on them uses the status text color (checked below) instead
        // of links / secondary text.
        for (final bg in [
          t.background, t.sidebar, t.surface, t.surfaceAlt, t.surfaceGuide, t.navSelected,
          if (b == Brightness.light) ...[t.successBg, t.warningBg, t.dangerBg, t.infoBg],
        ]) {
          expect(contrast(t.link, bg), greaterThanOrEqualTo(4.5), reason: 'enlace sobre $bg');
          expect(contrast(t.textSecondary, bg), greaterThanOrEqualTo(4.5), reason: 'secundario sobre $bg');
        }
      });

      test('texto de estado cumple AA sobre su fondo y sobre la superficie', () {
        for (final (fg, bg) in [
          (t.successText, t.successBg),
          (t.warningText, t.warningBg),
          (t.dangerText, t.dangerBg),
          (t.infoText, t.infoBg),
        ]) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg sobre $bg');
          expect(contrast(fg, t.surface), greaterThanOrEqualTo(4.5), reason: '$fg sobre surface');
        }
      });

      test('iconos de estado y botón primario cumplen contraste', () {
        for (final (i, own) in [
          (t.successIcon, t.successBg),
          (t.warningIcon, t.warningBg),
          (t.dangerIcon, t.dangerBg),
          (t.infoIcon, t.infoBg),
        ]) {
          expect(contrast(i, t.surface), greaterThanOrEqualTo(3), reason: '$i');
          if (b == Brightness.dark) expect(contrast(i, own), greaterThanOrEqualTo(3), reason: '$i sobre $own');
        }
        expect(contrast(t.successIcon, t.successBg), greaterThanOrEqualTo(2.5), reason: 'icono de paso completado');
        for (final fill in [t.interactive, t.interactiveHover, t.interactivePressed]) {
          expect(contrast(t.onInteractive, fill), greaterThanOrEqualTo(4.5), reason: 'texto sobre $fill');
        }
        expect(contrast(t.focus, t.surface), greaterThanOrEqualTo(3), reason: 'anillo de foco');
      });
    });
  }

  group('Apariencia por usuario', () {
    const ana = AppUser(id: 1, username: 'ana', displayName: 'Ana', isAdmin: false, isActive: true, mustChangePassword: false);
    const luis = AppUser(id: 2, username: 'luis', displayName: 'Luis', isAdmin: false, isActive: true, mustChangePassword: false);

    test('por defecto sigue a Windows; la elección se guarda por usuario', () async {
      final env = makeContainer();
      final c = env.container;
      addTearDown(() async {
        c.dispose();
        await env.db.close();
      });
      c.listen(themeModeProvider, (_, _) {});
      expect(c.read(themeModeProvider), ThemeMode.system);

      c.read(sessionProvider.notifier).set(ana);
      await c.read(themeModeProvider.notifier).set(ThemeMode.dark);
      expect(await c.read(settingsRepositoryProvider).get(SettingKeys.themeMode('ana')), 'dark');

      // Luis has his own saved choice, so Ana's does not leak to him.
      await c.read(settingsRepositoryProvider).set(SettingKeys.themeMode('luis'), 'system');
      c.read(sessionProvider.notifier).set(luis);
      await pumpEventQueue();
      expect(c.read(themeModeProvider), ThemeMode.system);

      c.read(sessionProvider.notifier).set(ana);
      await pumpEventQueue();
      expect(c.read(themeModeProvider), ThemeMode.dark);
    });

    test('la elección antes de iniciar sesión queda como predeterminada del equipo', () async {
      final env = makeContainer();
      final c = env.container;
      addTearDown(() async {
        c.dispose();
        await env.db.close();
      });
      c.listen(themeModeProvider, (_, _) {});
      await c.read(themeModeProvider.notifier).set(ThemeMode.light);
      expect(await c.read(settingsRepositoryProvider).get(SettingKeys.themeModeDevice), 'light');

      // A user without their own choice inherits the device default…
      c.read(sessionProvider.notifier).set(luis);
      await pumpEventQueue();
      expect(c.read(themeModeProvider), ThemeMode.light);

      // …and a user's own choice wins over it.
      await c.read(settingsRepositoryProvider).set(SettingKeys.themeMode('ana'), 'dark');
      c.read(sessionProvider.notifier).set(ana);
      await pumpEventQueue();
      expect(c.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
