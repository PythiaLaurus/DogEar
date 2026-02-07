import 'package:flutter/material.dart';

enum SettingsItemType {
  shortcut,
  dogEarColor,
  themeMode,
  closeToTray,
  showTrayIcon,
  autostart,
  resetUserPrefs,
}

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

class SettingsItem {
  final SettingsItemType type;
  final String function;
  final String description;

  const SettingsItem({
    required this.type,
    required this.function,
    required this.description,
  });
}
