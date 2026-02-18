import 'settings_items.dart';
import 'user_preferences_state.dart';

extension UserPreferencesStateExtension on UserPreferencesState {
  T getPrefsField<T>(SettingsItem<T> item) {
    return switch (item) {
      .shortcut => shortcut as T,
      .dogEarColor => dogEarColorArgb as T,
      .closeToTray => closeToTray as T,
      .showTrayIcon => showTrayIcon as T,
      .autostart => autostart as T,

      .themeMode || .resetUserPrefs => null as T,
    };
  }
}

Type typeOf<V>() => V;
