import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../services/desktop_integration.dart';
import 'router.dart';
import 'theme.dart';
import 'theme_mode.dart';

class RmqbApp extends ConsumerWidget {
  const RmqbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppInfo.displayName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: const Duration(milliseconds: 150),
      locale: const Locale('es', 'PR'),
      supportedLocales: const [Locale('es', 'PR'), Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      // The native title bar follows the effective theme (incl. Automático).
      builder: (context, child) {
        DesktopIntegration.current?.syncBrightness(Theme.of(context).brightness);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
