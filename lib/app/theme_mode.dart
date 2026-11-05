import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/repositories.dart';
import '../services/service_providers.dart';
import 'providers.dart';

/// Appearance preference: Automático (follows Windows) by default, with an
/// explicit Claro / Oscuro override. Saved per user, plus a device default
/// (the last choice on this computer) used before login and for users who
/// have not chosen yet.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final user = ref.watch(sessionProvider)?.username;
    _load(user);
    return stateOrNull ?? ThemeMode.system;
  }

  Future<void> _load(String? user) async {
    final repo = ref.read(settingsRepositoryProvider);
    final saved = (user == null ? null : await repo.get(SettingKeys.themeMode(user))) ??
        await repo.get(SettingKeys.themeModeDevice);
    // Ignore a late answer if the session changed meanwhile.
    if (ref.read(sessionProvider)?.username != user) return;
    state = parse(saved);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final repo = ref.read(settingsRepositoryProvider);
    final user = ref.read(sessionProvider)?.username;
    if (user != null) await repo.set(SettingKeys.themeMode(user), mode.name);
    await repo.set(SettingKeys.themeModeDevice, mode.name);
  }

  static ThemeMode parse(String? v) =>
      ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);

  static String label(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Automático (igual que Windows)',
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Oscuro',
      };

  static IconData icon(ThemeMode m) => switch (m) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Visible theme switch (app bar, login, setup): Automático / Claro / Oscuro.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final short = switch (mode) {
      ThemeMode.system => 'Automático',
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Oscuro',
    };
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Tema: $short',
      icon: Icon(ThemeModeController.icon(mode)),
      initialValue: mode,
      onSelected: (m) => ref.read(themeModeProvider.notifier).set(m),
      itemBuilder: (_) => [
        const PopupMenuItem(enabled: false, height: 32, child: Text('Tema de la aplicación')),
        for (final m in const [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
          CheckedPopupMenuItem(
            value: m,
            checked: m == mode,
            child: Row(children: [
              Icon(ThemeModeController.icon(m), size: 18),
              const SizedBox(width: 10),
              Text(ThemeModeController.label(m)),
            ]),
          ),
      ],
    );
  }
}
