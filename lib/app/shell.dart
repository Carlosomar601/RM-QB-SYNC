import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/help/help_content.dart';
import '../features/help/help_panel.dart';
import '../features/onboarding/tour.dart';
import '../services/service_providers.dart';
import '../ui/guided/guided.dart';

class NavItem {
  const NavItem(this.route, this.label, this.icon, this.selectedIcon, {this.adminOnly = false});
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool adminOnly;
}

/// Sidebar order from the spec.
const navItems = <NavItem>[
  NavItem(Routes.dashboard, 'Inicio', Icons.dashboard_outlined, Icons.dashboard),
  NavItem(Routes.sincronizaciones, 'Sincronizaciones', Icons.sync_outlined, Icons.sync),
  NavItem(Routes.reportes, 'Reportes', Icons.bar_chart_outlined, Icons.bar_chart),
  NavItem(Routes.vistaPrevia, 'Vista Previa', Icons.preview_outlined, Icons.preview),
  NavItem(Routes.mapeo, 'Mapeo de Cuentas', Icons.account_tree_outlined, Icons.account_tree),
  NavItem(Routes.configuracion, 'Configuración', Icons.settings_outlined, Icons.settings),
  NavItem(Routes.historial, 'Historial', Icons.history, Icons.history),
  NavItem(Routes.auditoria, 'Auditoría', Icons.fact_check_outlined, Icons.fact_check),
  NavItem(Routes.usuarios, 'Usuarios', Icons.group_outlined, Icons.group, adminOnly: true),
  NavItem(Routes.ayuda, 'Ayuda', Icons.help_outline, Icons.help),
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
                    title: Row(children: [
                      Image.asset('assets/icons/app_icon.png', width: 26, height: 26, semanticLabel: 'RMQBsync'),
                      const SizedBox(width: 10),
                      Flexible(child: Text('RMQBsync · ${current.label}', overflow: TextOverflow.ellipsis)),
                    ]),
                    actions: [
                      TourTarget(
                        id: 'appbar:guide',
                        child: compact
                            ? IconButton(
                                tooltip: 'Guíame (recorrido guiado)',
                                icon: const Icon(Icons.explore_outlined),
                                onPressed: () => ref.read(tourProvider.notifier).resume(),
                              )
                            : TextButton.icon(
                                onPressed: () => ref.read(tourProvider.notifier).resume(),
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
                        const VerticalDivider(width: 1),
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
          const Padding(padding: EdgeInsets.all(16), child: Text('RMQBsync')),
          for (final i in items)
            NavigationDrawerDestination(icon: Icon(i.icon), selectedIcon: Icon(i.selectedIcon), label: Text(i.label)),
        ],
      );
}

class _UserMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    if (user == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Opciones de usuario',
      icon: CircleAvatar(radius: 15, child: Text(user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase())),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${user.displayName} (${user.username})${user.isAdmin ? ' · Administrador' : ''}'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.password), title: Text('Cambiar contraseña'))),
        const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Cerrar sesión'))),
      ],
      onSelected: (v) async {
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
