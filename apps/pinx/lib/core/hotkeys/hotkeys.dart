import 'dart:async';

import 'package:hotkey_manager/hotkey_manager.dart';

/// Hotkeys manager class
class AppHotKeys {
  AppHotKeys._();
  static final instance = AppHotKeys._();

  /// All hot keys registered will be saved here.
  List<HotKey> get allHotKeys => hotKeyManager.registeredHotKeyList;

  /// Register a hotkey
  Future<void> register(HotKeyBinding hotKeyBinding) async {
    if (allHotKeys.contains(hotKeyBinding.hotKey)) {
      await hotKeyManager.unregister(hotKeyBinding.hotKey);
    }

    await hotKeyManager.register(
      hotKeyBinding.hotKey,
      keyDownHandler: hotKeyBinding.keyDownHandler,
      keyUpHandler: hotKeyBinding.keyUpHandler,
    );
  }

  /// Unregister a hotkey
  Future<void> unregister(HotKey hotkey) async {
    if (!allHotKeys.contains(hotkey)) return;

    await hotKeyManager.unregister(hotkey);
  }

  /// Register hot keys from a list.
  Future<void> registerAll(List<HotKeyBinding> hotKeyBindingList) async {
    for (final hotKeyBinding in hotKeyBindingList) {
      await hotKeyManager.register(
        hotKeyBinding.hotKey,
        keyDownHandler: hotKeyBinding.keyDownHandler,
        keyUpHandler: hotKeyBinding.keyUpHandler,
      );
    }
  }

  /// Unregister all hot keys.
  /// Call this when recording shortcut, so shortcuts already registered won't be triggered.
  /// This is alse for debugging purposes, need to be called to support hot reload.<br>
  /// Call in main function:<br>
  /// ```dart
  /// await AppHotKeys.unregisterAll();
  /// ```
  Future<void> unregisterAll() async {
    await hotKeyManager.unregisterAll();
  }
}

class HotKeyBinding {
  final HotKey hotKey;
  final void Function(HotKey hotKey)? keyDownHandler;
  final void Function(HotKey hotKey)? keyUpHandler;

  const HotKeyBinding({
    required this.hotKey,
    this.keyDownHandler,
    this.keyUpHandler,
  });
}

final appHotKeys = AppHotKeys.instance;
