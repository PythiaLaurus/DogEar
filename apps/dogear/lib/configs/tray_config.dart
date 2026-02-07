import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'app_config.dart';

class TrayConfig {
  static const String tooltip = AppConfig.appName;
  static const String iconPath = "assets/system/tray_icon.ico";

  static bool? closeToTray;

  static final List<MenuItem> menuItems = [
    MenuItem(label: "Open panel", onClick: (menuItem) => windowManager.show()),
    MenuItem(label: "Hide panel", onClick: (menuItem) => windowManager.hide()),
    MenuItem(label: "Exit", onClick: (menuItem) => windowManager.close()),
  ];
}
