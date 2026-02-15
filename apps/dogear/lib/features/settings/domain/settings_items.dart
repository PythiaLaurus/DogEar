import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart' show HotKey;

import 'user_prefs_defaults.dart';

class SettingsCategory {
  final IconData icon;
  final String title;
  final List<SettingsItem> items;

  const SettingsCategory({
    required this.icon,
    required this.title,
    required this.items,
  });
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
    defaultValue: UserPrefsDefaults.dogEarColorArgbDefault,
  ),
  themeMode<void>(function: "App Theme", description: ""),

  // System
  closeToTray<bool>(
    function: "Close to Tray",
    description: "Keep running in background when closed",
    defaultValue: UserPrefsDefaults.closeToTrayDefault,
  ),
  showTrayIcon<bool>(
    function: "Show Tray Icon",
    description: "Show icon in system tray area",
    defaultValue: UserPrefsDefaults.showTrayIconDefault,
  ),
  autostart<bool>(
    function: "Autostart",
    description: "Start Dog Ear automatically on system boot",
    defaultValue: UserPrefsDefaults.autostartDefault,
  ),
  resetUserPrefs<void>(function: "Reset all settings", description: "");

  /// Function name.
  final String function;

  /// Description for the function.
  final String description;

  /// Default values.
  final T? _defaultValue;

  const SettingsItem({
    required this.function,
    required this.description,
    T? defaultValue,
  }) : _defaultValue = defaultValue;

  /// Returns default value for the setting item.
  T? get defaultValue {
    if (_defaultValue != null) return _defaultValue;

    if (this == .shortcut) {
      return UserPrefsDefaults.shortcutDefault as T;
    }

    return null;
  }
}
