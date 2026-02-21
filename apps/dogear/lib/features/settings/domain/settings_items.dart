import 'package:flutter/material.dart' show IconData, Icons;
import 'package:hotkey_manager/hotkey_manager.dart' show HotKey;

enum SettingsCategory {
  shortcut(icon: Icons.keyboard, items: [SettingsItem.shortcut]),
  appearance(
    icon: Icons.palette,
    items: [SettingsItem.dogEarColor, SettingsItem.themeMode],
  ),
  system(
    icon: Icons.settings,
    items: [
      SettingsItem.closeToTray,
      SettingsItem.showTrayIcon,
      SettingsItem.autostart,
      SettingsItem.resetUserPrefs,
    ],
  );

  final IconData icon;
  final List<SettingsItem> items;

  String get title => name[0].toUpperCase() + name.substring(1);

  const SettingsCategory({required this.icon, required this.items});
}

enum SettingsItem<T> {
  // Shortcut
  shortcut<HotKey?>(
    function: "Pin Active Window",
    description: "Global hotkey to pin/unpin windows",
  ),

  // Appearance
  dogEarColor<int>(
    function: "Dog Ear Color",
    description: "Color of the overlay indicator",
  ),
  themeMode<void>(function: "App Theme", description: ""),

  // System
  closeToTray<bool>(
    function: "Close to Tray",
    description: "Keep running in background when closed",
  ),
  showTrayIcon<bool>(
    function: "Show Tray Icon",
    description: "Show icon in system tray area",
  ),
  autostart<bool>(
    function: "Autostart",
    description: "Start Dog Ear automatically on system boot",
  ),
  resetUserPrefs<void>(function: "Reset all settings", description: "");

  /// Function name.
  final String function;

  /// Description for the function.
  final String description;

  const SettingsItem({required this.function, required this.description});
}
