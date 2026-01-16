import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

part 'user_preferences_model.freezed.dart';
part 'user_preferences_model.g.dart';

@freezed
abstract class UserPreferencesModel with _$UserPreferencesModel {
  const factory UserPreferencesModel({
    HotKey? shortcut,
    @Default(0xFFBCAAA4) int dogEarColorARGB,
    @Default(true) bool closeToTray,
    @Default(true) bool showTrayIcon,
  }) = _UserPreferencesModel;

  factory UserPreferencesModel.initialize() => UserPreferencesModel(
    shortcut: HotKey(
      key: LogicalKeyboardKey.home,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ),
  );

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesModelFromJson(json);
}
