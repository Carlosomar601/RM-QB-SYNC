import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/help/help_content.dart';
import '../features/help/help_panel.dart';
import '../features/onboarding/tour.dart';
import '../services/service_providers.dart';
import '../core/constants.dart';
import '../ui/brand.dart';
import '../ui/guided/guided.dart';
import 'theme_mode.dart';

class NavItem {
  const NavItem(this.route, this.label, this.icon, this.selectedIcon, {this.adminOnly = false});
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool adminOnly;
}

/// Sidebar order from the spec. One outline icon family (Material outlined,
/// mapped to the spec's meanings: layout-dashboard, refresh-cw, chart-column,
/// file-search, network, settings, history, clipboard-check, users,
/// circle-help). Selection is shown by the indicator tint, not a filled glyph.
const navItems = <NavItem>[
  NavItem(Routes.dashboard, 'Inicio', Icons.dashboard_outlined, Icons.dashboard_outlined),
  NavItem(Routes.sincronizaciones, 'Sincronizaciones', Icons.sync, Icons.sync),
  NavItem(Routes.reportes, 'Reportes', Icons.bar_chart, Icons.bar_chart),
  NavItem(Routes.vistaPrevia, 'Vista Previa', Icons.find_in_page_outlined, Icons.find_in_page_outlined),
  NavItem(Routes.mapeo, 'Mapeo de Cuentas', Icons.lan_outlined, Icons.lan_outlined),
  NavItem(Routes.configuracion, 'Configuración', Icons.settings_outlined, Icons.settings_outlined),
  NavItem(Routes.historial, 'Historial', Icons.history, Icons.history),
  NavItem(Routes.auditoria, 'Auditoría', Icons.assignment_turned_in_outlined, Icons.assignment_turned_in_outlined),
  NavItem(Routes.usuarios, 'Usuarios', Icons.group_outlined, Icons.group_outlined, adminOnly: true),
  NavItem(Routes.ayuda, 'Ayuda', Icons.help_outline, Icons.help_outline),
];

class OpenHelpIntent extends Intent {
  const OpenHelpIntent();
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openHelp() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final items = navItems.where((i) => !i.adminOnly || (user?.isAdmin ?? false)).toList();
    var selected = items.indexWhere((i) => widget.location.startsWith(i.route));
    if (selected < 0) selected = 0;
    final current = items[selected];

    return Shortcuts(
      shortcuts: const {SingleActivator(LogicalKeyboardKey.f1): OpenHelpIntent()},
      child: Actions(
        actions: {OpenHelpIntent: CallbackAction<OpenHelpIntent>(onInvoke: (_) => _openHelp())},
        child: FocusScope(
          autofocus: true,
          child: Stack(
            children: [
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 1100;
                final compact = c.maxWidth < 640;
                return Scaffold(
                  key: _scaffoldKey,
                  endDrawer: HelpPanel(location: widget.location),
                  appBar: AppBar(
                    // Brand lives in the sidebar (and the native title bar);
                    // the app bar names where the user is.
                    title: Row(children: [
                      if (compact) ...[const BrandIcon(size: 24), const SizedBox(width: 10)],
                      Flexible(
                        child: Semantics(
                          header: true,
                          child: Text(current.label, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ]),
                    actions: [
                      TourTarget(
                        id: 'appbar:guide',
                        child: compact
                            ? IconButton(
                                tooltip: 'Guíame: cómo usar esta pantalla',
                                icon: const Icon(Icons.explore_outlined),
                                onPressed: () => ref.read(tourProvider.notifier).guide(widget.location),
                              )
                            : TextButton.icon(
                                onPressed: () => ref.read(tourProvider.notifier).guide(widget.location),
                                icon: const Icon(Icons.explore_outlined),
                                label: const Text('Guíame'),
                              ),
                      ),
                      TourTarget(
                        id: 'appbar:help',
                        child: IconButton(
                          tooltip: 'Ayuda de esta pantalla (F1)',
                          icon: const Icon(Icons.help_outline),
                          onPressed: _openHelp,
                        ),
                      ),
                      const TourTarget(id: 'appbar:theme', child: ThemeModeButton()),
                      _UserMenu(),
                      const SizedBox(width: 8),
                    ],
                  ),
                  bottomNavigationBar: compact
                      ? NavigationBar(
                          selectedIndex: selected.clamp(0, 4),
                          destinations: [
                            for (final i in items.take(5))
                              NavigationDestination(icon: Icon(i.icon), selectedIcon: Icon(i.selectedIcon), label: i.label),
                          ],
                          onDestinationSelected: (i) => context.go(items[i].route),
                        )
                      : null,
                  drawer: compact ? _CompactDrawer(items: items, selected: selected) : null,
                  body: Row(
                    children: [
                      if (!compact) ...[
                        NavigationRail(
                          scrollable: true,
                          extended: wide,
                          minExtendedWidth: 220,
                          labelType: wide ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                          leading: _SidebarBrand(extended: wide),
                          selectedIndex: selected,
                          onDestinationSelected: (i) => context.go(items[i].route),
                          destinations: [
                            for (final i in items)
                              NavigationRailDestination(
                                icon: TourTarget(id: 'nav:${i.route}', child: Tooltip(message: i.label, child: Icon(i.icon))),
                                selectedIcon: TourTarget(id: 'nav:${i.route}', child: Icon(i.selectedIcon)),
                                label: Text(i.label),
                              ),
                          ],
                        ),
                        VerticalDivider(width: 1, color: context.rm.border),
                      ],
                      Expanded(child: widget.child),
                    ],
                  ),
                );
              }),
              const Positioned.fill(child: TourOverlay()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact branding at the top of the sidebar.
class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final icon = const BrandIcon(size: 30);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: extended
          ? SizedBox(
              width: 196,
              child: Row(children: [
                icon,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppInfo.displayName,
                        style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    Text('Retail Manager', style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ]),
            )
          : Tooltip(message: AppInfo.displayName, child: icon),
    );
  }
}

class _CompactDrawer extends StatelessWidget {
  const _CompactDrawer({required this.items, required this.selected});
  final List<NavItem> items;
  final int selected;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
        selectedIndex: selected,
        onDestinationSelected: (i) {
          Navigator.of(context).pop();
          context.go(items[i].route);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const BrandIcon(size: 28),
              const SizedBox(width: 10),
              Text(AppInfo.displayName, style: Theme.of(context).textTheme.titleMedium),
            ]),
          ),
          for (final i in items)
            NavigationDrawerDestination(icon: Icon(i.icon), selectedIcon: Icon(i.selectedIcon), label: Text(i.label)),
        ],
      );
}

class _UserMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeModeProvider);
    if (user == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Opciones de usuario',
      icon: CircleAvatar(
          radius: 15,
          backgroundColor: context.rm.navSelected,
          foregroundColor: context.rm.textPrimary,
          child: Text(user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase())),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${user.displayName} (${user.username})${user.isAdmin ? ' · Administrador' : ''}'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(enabled: false, height: 32, child: Text('Tema de la aplicación')),
        for (final (mode, label, icon) in const [
          (ThemeMode.system, 'Automático (igual que Windows)', Icons.brightness_auto_outlined),
          (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
          (ThemeMode.dark, 'Oscuro', Icons.dark_mode_outlined),
        ])
          CheckedPopupMenuItem(
            value: 'theme:${mode.name}',
            checked: themeMode == mode,
            child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)]),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.password), title: Text('Cambiar contraseña'))),
        const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Cerrar sesión'))),
      ],
      onSelected: (v) async {
        if (v.startsWith('theme:')) {
          await ref.read(themeModeProvider.notifier).set(ThemeModeController.parse(v.substring(6)));
          return;
        }
        if (v == 'password') context.go(Routes.cambiarContrasena);
        if (v == 'logout') {
          final ok = await confirmAction(context,
              title: 'Cerrar sesión',
              message: 'Las sincronizaciones programadas seguirán ejecutándose mientras la aplicación esté abierta.',
              confirmLabel: 'Cerrar sesión');
          if (!ok) return;
          await ref.read(authServiceProvider).logout(user);
          ref.read(sessionProvider.notifier).set(null);
        }
      },
    );
  }
}
