import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../configs/tray_config.dart';

Future<void> initSystemTray() async {
  // Set the system tray icon
  String iconPath = 'assets/system/tray.ico';
  await trayManager.setIcon(iconPath);

  // Set the system tray title and tooltip
  if (!Platform.isLinux) {
    await trayManager.setToolTip(TrayConfig.tooltip);
  }

  // create context menu
  Menu menu = Menu(items: TrayConfig.menuItems);

  // set context menu
  await trayManager.setContextMenu(menu);

  // handle system tray event
  trayManager.addListener(SystemTrayListener());
}

class SystemTrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) {
      windowManager.show();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows) {
      trayManager.popUpContextMenu();
    } else {
      windowManager.show();
    }
  }
}
