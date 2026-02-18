import 'dart:ui' show Color;

import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/hotkeys/hotkeys.dart';
import '../../../core/storage/storage.dart';
import '../../../services/platform/autostart.dart';
import '../../../services/platform/tray.dart';
import '../../topmost_overlay_orchestration/application/topmost_overlay_orchestrator.dart';
import '../domain/user_preferences_state.dart';

export '../domain/settings_items.dart';
export '../domain/user_preferences_state.dart';
export '../domain/user_prefs_extention.dart';

part 'user_preferences.g.dart';

@Riverpod(keepAlive: true)
class UserPreferences extends _$UserPreferences {
  static const String _kStorage = "settings.userPreferences";

  @override
  UserPreferencesState build() {
    _init();
    return UserPreferencesState.initialize();
  }

  /// Asynchronous initialize.
  Future<void> _init() async {
    final savedPrefsJson = await appStorage.getJson(_kStorage);

    if (savedPrefsJson != null) {
      final savedPrefs = UserPreferencesState.fromJson(savedPrefsJson);
      _applyAll(savedPrefs);

      state = savedPrefs;
      return;
    }

    final prefs = UserPreferencesState.initialize();
    _applyAll(prefs);
    _saveUserPrefs(prefs);
  }

  /// Updates shortcut.
  void updateShortcut(HotKey? hotkey) {
    final prevPrefs = state;
    if (prevPrefs.shortcut == hotkey) return;

    _applyShortcut(hotkey);
    _saveUserPrefs(prevPrefs.copyWith(shortcut: hotkey));
  }

  void _applyShortcut(HotKey? newKey) {
    final prevKey = state.shortcut;

    if (prevKey != null) {
      appHotKeys.unregister(prevKey);
    }

    if (newKey == null) return;

    final orchestrator = ref.read(topmostOverlayOrchestratorProvider.notifier);
    final newHotkeyBinding = HotKeyBinding(
      hotKey: newKey,
      keyDownHandler: (hotkey) {
        orchestrator.autoAddRemoveUnderCursorWindow();
      },
    );
    appHotKeys.register(newHotkeyBinding);
  }

  /// Updates dog ear color.
  void updateDogEarColor(int newColorARGB) {
    final prevPrefs = state;
    if (prevPrefs.dogEarColorArgb == newColorARGB) return;

    _applyDogEarColor(newColorARGB);
    _saveUserPrefs(prevPrefs.copyWith(dogEarColorArgb: newColorARGB));
  }

  void _applyDogEarColor(int newColorARGB) {
    final orchestrator = ref.read(topmostOverlayOrchestratorProvider.notifier);
    orchestrator.updateOverlayColor(Color(newColorARGB));
  }

  /// Reapplies dog ear color.
  ///
  /// Used after color picking dialog is closed without confirmation.
  void reapplyDogEarColor() {
    final prevPrefs = state;
    _applyDogEarColor(prevPrefs.dogEarColorArgb);
  }

  /// Updates should app be closed to tray when clicking
  /// on the close button on app bar.
  void updateCloseToTray(bool value) {
    final prevPrefs = state;
    if (prevPrefs.closeToTray == value) return;

    _applyCloseToTray(value);
    _saveUserPrefs(prevPrefs.copyWith(closeToTray: value));
  }

  void _applyCloseToTray(bool newValue) {
    appTray.setCloseToTray(newValue);
  }

  /// Shows tray icon.
  void updateShowTrayIcon(bool value) {
    final prevPrefs = state;
    if (prevPrefs.showTrayIcon == value) return;

    _applyShowTrayIcon(value);
    _saveUserPrefs(prevPrefs.copyWith(showTrayIcon: value));
  }

  void _applyShowTrayIcon(bool newValue) {
    newValue ? appTray.showTray() : appTray.hideTray();
  }

  /// Updates if app should autostart on system boot.
  ///
  /// Will be auto applied by [AppAutostart].
  void updateAutostart(bool value) {
    final prevPrefs = state;
    if (prevPrefs.autostart == value) return;

    _applyAutostart(value);
    _saveUserPrefs(prevPrefs.copyWith(autostart: value));
  }

  void _applyAutostart(bool newValue) {
    appAutostart.setAutostart(newValue);
  }

  /// Resets All User Preferences.
  void resetUserPrefs() {
    final initPrefs = UserPreferencesState.initialize();
    _applyAll(initPrefs);
    _saveUserPrefs(initPrefs);
  }

  /// Saves All User Preferences.
  void _saveUserPrefs(UserPreferencesState newPrefs) {
    state = newPrefs;
    appStorage.setJson(_kStorage, newPrefs.toJson());
  }

  /// Applies All User Preferences.
  Future<void> _applyAll(UserPreferencesState prefs) async {
    _applyShortcut(prefs.shortcut);
    _applyDogEarColor(prefs.dogEarColorArgb);
    _applyAutostart(prefs.autostart);

    await _initTray();
    _applyCloseToTray(prefs.closeToTray);
    _applyShowTrayIcon(prefs.showTrayIcon);
  }

  // Checks if tray is Initialized and initialize it if not.
  Future<void> _initTray() async {
    if (!appTray.isInitialized) {
      await appTray.initSystemTray();
    }
  }
}
