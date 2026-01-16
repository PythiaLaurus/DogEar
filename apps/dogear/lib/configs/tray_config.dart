import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'app_config.dart';

class TrayConfig {
  static const String tooltip = AppConfig.appName;

  static final List<MenuItem> menuItems = [
    MenuItem(label: '打开主面板', onClick: (menuItem) => windowManager.show()),
    MenuItem(label: '隐藏主面板', onClick: (menuItem) => windowManager.hide()),
    MenuItem(label: '退出', onClick: (menuItem) => windowManager.close()),
  ];
}
