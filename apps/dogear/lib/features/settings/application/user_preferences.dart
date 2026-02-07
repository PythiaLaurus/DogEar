import 'dart:ui' show Color;

import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/hotkeys/hotkeys.dart';
import '../../../core/storage/storage.dart';
import '../../../services/platform/autostart.dart';
import '../../../services/platform/tray.dart';
import '../../topmost_overlay_orchestration/application/topmost_overlay_orchestrator.dart';
import '../domain/user_preferences_state.dart';

part 'user_preferences.g.dart';

@Riverpod(keepAlive: true)
class UserPreferences extends _$UserPreferences {
  static const String _kStorage = "settings.userPreferences";

  @override
  FutureOr<UserPreferencesState> build() async {
    final savedPrefsJson = await appStorage.getJson(_kStorage);

    if (savedPrefsJson != null) {
      final savedPrefs = UserPreferencesState.fromJson(savedPrefsJson);
      _applyAll(savedPrefs);

      return savedPrefs;
    }

    final prefs = UserPreferencesState.initialize();
    _saveUserPrefs(prefs);
    _applyAll(prefs);

    return prefs;
  }

  /// Updates shortcut.
  void updateShortcut(HotKey? hotkey) {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;
    if (prevPrefs.shortcut == hotkey) return;

    _saveUserPrefs(prevPrefs.copyWith(shortcut: hotkey));
    _applyShortcut(hotkey);
  }

  void _applyShortcut(HotKey? newKey) {
    final prevKey = state.value?.shortcut;

    if (prevKey != null) {
      appHotKeys.unregister(prevKey);
    }

    if (newKey == null) return;

    final orchestrator = ref.read(topmostOverlayOrchestratorProvider.notifier);
    final newHotkeyBinding = HotKeyBinding(
      hotKey: newKey,
      keyDownHandler: (hotkey) {
        orchestrator.autoAddRemoveForegroundWindow();
      },
    );
    appHotKeys.register(newHotkeyBinding);
  }

  /// Updates dog ear color.
  void updateDogEarColor(int newColorARGB) {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;
    if (prevPrefs.dogEarColorARGB == newColorARGB) return;

    _saveUserPrefs(prevPrefs.copyWith(dogEarColorARGB: newColorARGB));
    _applyDogEarColor(newColorARGB);
  }

  void _applyDogEarColor(int newColorARGB) {
    final orchestrator = ref.read(topmostOverlayOrchestratorProvider.notifier);
    orchestrator.updateOverlayColor(Color(newColorARGB));
  }

  /// Reapplies dog ear color.
  ///
  /// Used after color picking dialog is closed without confirmation.
  void reapplyDogEarColor() {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;

    _applyDogEarColor(prevPrefs.dogEarColorARGB);
  }

  /// Updates should app be closed to tray when clicking
  /// on the close button on app bar.
  void updateCloseToTray(bool value) {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;
    if (prevPrefs.closeToTray == value) return;

    _saveUserPrefs(prevPrefs.copyWith(closeToTray: value));
    _applyCloseToTray(value);
  }

  void _applyCloseToTray(bool newValue) {
    appTray.setCloseToTray(newValue);
  }

  /// Shows tray icon.
  void updateShowTrayIcon(bool value) {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;
    if (prevPrefs.showTrayIcon == value) return;

    _saveUserPrefs(prevPrefs.copyWith(showTrayIcon: value));
    _applyShowTrayIcon(value);
  }

  void _applyShowTrayIcon(bool newValue) {
    newValue ? appTray.showTray() : appTray.hideTray();
  }

  /// Updates if app should autostart on system boot.
  ///
  /// Will be auto applied by [AppAutostart].
  void updateAutostart(bool value) {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;
    if (prevPrefs.autostart == value) return;

    _saveUserPrefs(prevPrefs.copyWith(autostart: value));
    _applyAutostart(value);
  }

  void _applyAutostart(bool newValue) {
    appAutostart.setAutostart(newValue);
  }

  /// Resets All User Preferences.
  void resetUserPrefs() {
    final initPrefs = UserPreferencesState.initialize();
    _saveUserPrefs(initPrefs);
    _applyAll(initPrefs);
  }

  /// Saves All User Preferences.
  void _saveUserPrefs(UserPreferencesState newPrefs) {
    state = AsyncValue.data(newPrefs);
    appStorage.setJson(_kStorage, newPrefs.toJson());
  }

  /// Applies All User Preferences.
  Future<void> _applyAll(UserPreferencesState prefs) async {
    _applyShortcut(prefs.shortcut);
    _applyDogEarColor(prefs.dogEarColorARGB);
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
