import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:hotkey_manager/hotkey_manager.dart' show HotKey, HotKeyModifier;

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

final class UserPrefsDefaults {
  static final shortcutDefault = HotKey(
    key: LogicalKeyboardKey.home,
    modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
  );
  static const dogEarColorArgbDefault = 0xFF8F4C33;
  static const closeToTrayDefault = true;
  static const showTrayIconDefault = true;
  static const autostartDefault = false;
}
