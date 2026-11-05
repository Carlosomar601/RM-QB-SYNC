import 'dart:async';
import 'dart:io';
import 'dart:ui' show Brightness, Size;

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
// ignore: deprecated_member_use
import 'package:window_manager/legacy.dart' as legacy show windowManager;
import 'package:window_manager/window_manager.dart';

import 'app_logger.dart';

/// Ensures one running instance. A second launch asks the first to show
/// its window and then exits.
class SingleInstance {
  static const port = 51777;
  static ServerSocket? _server;

  /// Returns false if another instance is already running.
  static Future<bool> acquire(void Function() onActivate) async {
    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      _server!.listen((s) {
        s.listen((data) {
          if (String.fromCharCodes(data).trim() == 'show') onActivate();
        }, onDone: s.destroy, onError: (_) => s.destroy());
      });
      return true;
    } on SocketException {
      try {
        final s = await Socket.connect(InternetAddress.loopbackIPv4, port, timeout: const Duration(seconds: 2));
        s.write('show\n');
        await s.flush();
        await s.close();
      } catch (_) {}
      return false;
    }
  }
}

/// Window + system tray + start-with-Windows (window_manager / tray_manager
/// native API).
class DesktopIntegration {
  DesktopIntegration({required this.onSyncNow});

  final Future<void> Function() onSyncNow;
  Window? _window;
  tray.TrayIcon? _tray;
  bool _quitting = false;

  /// The running integration (null in tests / before [init]).
  static DesktopIntegration? current;
  Brightness? _brightness;

  /// Keeps the native title bar in the same light/dark mode as the app
  /// (Automático, Claro or Oscuro). Best effort: ignored if unsupported.
  void syncBrightness(Brightness b) {
    if (_brightness == b) return;
    _brightness = b;
    try {
      // ignore: deprecated_member_use
      legacy.windowManager.setBrightness(b).catchError((Object e) {
        AppLogger.error('No se pudo aplicar el tema a la barra de título', e);
      });
    } catch (e, st) {
      AppLogger.error('No se pudo aplicar el tema a la barra de título', e, st);
    }
  }

  Future<void> init({required bool startMinimized}) async {
    current = this;
    _window = WindowManager.instance.getCurrent();
    final w = _window;
    if (w != null) {
      w.title = 'RM Ledger Sync';
      w.minimumSize = const Size(560, 520).toNative();
      if (startMinimized) w.hide();
      // Close button hides to the tray so schedules keep running.
      w.addListener((event) {
        if (event is WindowCloseRequestedEvent && !_quitting) {
          event.request.cancel();
          w.hide();
        }
      });
    }

    try {
      final icon = tray.TrayIcon.create();
      if (icon != null) {
        icon.icon = tray.ImageAsset.fromAsset('assets/icons/app_icon.png');
        icon.setTooltip('RM Ledger Sync – sincronización POS → QuickBooks');
        final menu = tray.Menu.create()!;
        void item(String label, FutureOr<void> Function() onClick) {
          final it = tray.MenuItem.createWithLabelAndType(label, tray.MenuItemType.normal);
          if (it == null) return;
          it.addListener((e) {
            if (e is tray.MenuItemClickedEvent) return onClick();
          });
          menu.addItem(it);
        }

        item('Abrir RM Ledger Sync', showWindow);
        item('Sincronizar ahora (hoy)', onSyncNow);
        menu.addSeparator();
        item('Salir (detiene las sincronizaciones programadas)', quit);
        icon.setContextMenu(menu);
        icon.setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked);
        icon.addListener((e) {
          if (e is tray.TrayIconClickedEvent || e is tray.TrayIconDoubleClickedEvent) showWindow();
        });
        icon.setVisible(true);
        _tray = icon;
      }
    } catch (e, st) {
      AppLogger.error('No se pudo crear el icono de la bandeja', e, st);
    }

    launchAtStartup.setup(
      appName: 'RMQBsync',
      appPath: Platform.resolvedExecutable,
      args: const ['--minimized'],
    );
  }

  void setTooltip(String text) => _tray?.setTooltip(text.length > 120 ? text.substring(0, 120) : text);

  static Future<bool> isLaunchAtStartupEnabled() async {
    try {
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  static Future<void> setLaunchAtStartup(bool enabled) async {
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }

  void showWindow() {
    final w = _window;
    if (w == null) return;
    w.show();
    w.restore();
    w.focus();
  }

  Future<void> quit() async {
    _quitting = true;
    AppLogger.info('Aplicación cerrada desde la bandeja.');
    _tray?.setVisible(false);
    _tray?.dispose();
    exit(0);
  }
}
