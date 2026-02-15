import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'user_prefs_defaults.dart';

part 'user_preferences_state.freezed.dart';
part 'user_preferences_state.g.dart';

@freezed
abstract class UserPreferencesState with _$UserPreferencesState {
  const factory UserPreferencesState({
    HotKey? shortcut,
    @Default(UserPrefsDefaults.dogEarColorArgbDefault) int dogEarColorArgb,
    @Default(UserPrefsDefaults.closeToTrayDefault) bool closeToTray,
    @Default(UserPrefsDefaults.showTrayIconDefault) bool showTrayIcon,
    @Default(UserPrefsDefaults.autostartDefault) bool autostart,
  }) = _UserPreferencesState;

  factory UserPreferencesState.initialize() =>
      UserPreferencesState(shortcut: UserPrefsDefaults.shortcutDefault);

  factory UserPreferencesState.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesStateFromJson(json);
}
