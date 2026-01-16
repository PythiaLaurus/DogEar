import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/hotkeys/hotkeys.dart';
import '../../../core/storage/storage.dart';
import '../../../services/platform/native_window_bridge.dart';
import '../../../services/platform/tray.dart';
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

  /// Shortcut
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

    final newHotkeyBinding = HotKeyBinding(
      hotKey: newKey,
      keyDownHandler: (hotkey) {
        nativeWindowBridge.toggleForegroundWindowTopmost();
      },
    );
    appHotKeys.register(newHotkeyBinding);
  }

  /// Dog Ear Color
  void updateDogEarColor(int newColorARGB) {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;
    if (prevPrefs.dogEarColorARGB == newColorARGB) return;

    _saveUserPrefs(prevPrefs.copyWith(dogEarColorARGB: newColorARGB));
    _applyDogEarColor(newColorARGB);
  }

  void _applyDogEarColor(int newColorARGB) {
    // TODO:  implement
  }

  /// Close to tray
  void updateCloseToTray(bool value) {
    final prevPrefs = state.value;

    if (prevPrefs == null) return;
    if (prevPrefs.closeToTray == value) return;

    _saveUserPrefs(prevPrefs.copyWith(closeToTray: value));

    // Will be auto applied by [NormalAppBar]
    // _applyCloseToTray(value);
  }

  // Will be auto applied by [NormalAppBar]
  // void _applyCloseToTray(bool value) {}

  /// Show tray icon
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

  /// Reset All User Preferences
  void resetUserPrefs() {
    final initPrefs = UserPreferencesState.initialize();
    _saveUserPrefs(initPrefs);
    _applyAll(initPrefs);
  }

  /// Save All User Preferences
  void _saveUserPrefs(UserPreferencesState newPrefs) {
    state = AsyncValue.data(newPrefs);
    appStorage.setJson(_kStorage, newPrefs.toJson());
  }

  /// Apply All User Preferences
  Future<void> _applyAll(UserPreferencesState prefs) async {
    _applyShortcut(prefs.shortcut);
    _applyDogEarColor(prefs.dogEarColorARGB);
    // _applyCloseToTray(prefs.closeToTray);

    await _initTray();
    _applyShowTrayIcon(prefs.showTrayIcon);
  }

  // Check if tray is Initialized and initialize it if not
  Future<void> _initTray() async {
    if (!appTray.isInitialized) {
      await appTray.initSystemTray();
    }
  }
}
