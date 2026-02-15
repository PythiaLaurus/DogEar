import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_items.dart';
import 'user_preferences_state.dart';

extension UserPreferencesStateExtension on AsyncValue<UserPreferencesState> {
  T getPrefsField<T>(SettingsItem<T> item) {
    return switch (item) {
      _ when T == typeOf<void>() => null as T,

      SettingsItem.shortcut => (value?.shortcut ?? item.defaultValue) as T,
      SettingsItem.dogEarColor =>
        (value?.dogEarColorArgb ?? item.defaultValue) as T,
      SettingsItem.closeToTray =>
        (value?.closeToTray ?? item.defaultValue) as T,
      SettingsItem.showTrayIcon =>
        (value?.showTrayIcon ?? item.defaultValue) as T,
      SettingsItem.autostart => (value?.autostart ?? item.defaultValue) as T,

      _ => item.defaultValue as T,
    };
  }
}

Type typeOf<V>() => V;
