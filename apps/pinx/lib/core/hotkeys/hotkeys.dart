import 'dart:async';

import 'package:hotkey_manager/hotkey_manager.dart';

/// Hotkeys manager class
class AppHotKeys {
  /// All hotkeys registered will be saved here.
  static List<HotKey> get allHotKeys => hotKeyManager.registeredHotKeyList;

  /// Register a hotkey
  static Future<void> register(HotkeyBinding hotkeyBinding) async {
    if (allHotKeys.contains(hotkeyBinding.hotKey)) {
      await hotKeyManager.unregister(hotkeyBinding.hotKey);
    }

    await hotKeyManager.register(
      hotkeyBinding.hotKey,
      keyDownHandler: hotkeyBinding.keyDownHandler,
      keyUpHandler: hotkeyBinding.keyUpHandler,
    );
  }

  /// Unregister a hotkey
  static Future<void> unregister(HotKey hotkey) async {
    if (!allHotKeys.contains(hotkey)) return;

    await hotKeyManager.unregister(hotkey);
  }

  /// Register hotkeys from a list.
  static Future<void> registerAll(List<HotkeyBinding> hotKeyBindingList) async {
    for (final hotKeyBinding in hotKeyBindingList) {
      await hotKeyManager.register(
        hotKeyBinding.hotKey,
        keyDownHandler: hotKeyBinding.keyDownHandler,
        keyUpHandler: hotKeyBinding.keyUpHandler,
      );
    }
  }

  /// Unregister all hotkeys.
  /// Call this when recording shortcut, so shortcuts already registered won't be triggered.
  /// This is alse for debugging purposes, need to be called to support hot reload.<br>
  /// Call in main function:<br>
  /// ```dart
  /// await AppHotKeys.unregisterAll();
  /// ```
  static Future<void> unregisterAll() async {
    await hotKeyManager.unregisterAll();
  }
}

class HotkeyBinding {
  final HotKey hotKey;
  final void Function(HotKey hotKey)? keyDownHandler;
  final void Function(HotKey hotKey)? keyUpHandler;

  const HotkeyBinding({
    required this.hotKey,
    this.keyDownHandler,
    this.keyUpHandler,
  });
}
