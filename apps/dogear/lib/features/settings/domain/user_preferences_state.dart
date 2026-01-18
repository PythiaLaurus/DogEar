import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

part 'user_preferences_state.freezed.dart';
part 'user_preferences_state.g.dart';

@freezed
abstract class UserPreferencesState with _$UserPreferencesState {
  const factory UserPreferencesState({
    HotKey? shortcut,
    @Default(0xFF8F4C33) int dogEarColorARGB,
    @Default(true) bool closeToTray,
    @Default(true) bool showTrayIcon,
  }) = _UserPreferencesState;

  factory UserPreferencesState.initialize() => UserPreferencesState(
    shortcut: HotKey(
      key: LogicalKeyboardKey.home,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ),
  );

  factory UserPreferencesState.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesStateFromJson(json);
}
