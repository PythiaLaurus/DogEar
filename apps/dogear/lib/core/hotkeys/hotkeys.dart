import 'dart:async';

import 'package:hotkey_manager/hotkey_manager.dart';

/// Hotkeys manager class
class AppHotKeys {
  AppHotKeys._();
  static final instance = AppHotKeys._();

  bool _isPaused = false;

  /// Whether hotkeys are paused.
  bool get isPaused => _isPaused;

  /// All hot keys registered will be saved here.
  final hotKeyToBindings = <HotKey, HotKeyBinding>{};

  /// Register a hotkey.
  ///
  /// Note: When [isPaused] is true, the hotkey will not be registered
  /// immediately until [resume] is called.
  Future<void> register(HotKeyBinding hotKeyBinding) async {
    final hotKey = hotKeyBinding.hotKey;
    if (hotKeyToBindings[hotKey] != null) {
      await hotKeyManager.unregister(hotKey);
      hotKeyToBindings.remove(hotKey);
    }

    if (!_isPaused) {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: hotKeyBinding.keyDownHandler,
        keyUpHandler: hotKeyBinding.keyUpHandler,
      );
    }
    hotKeyToBindings[hotKey] = hotKeyBinding;
  }

  /// Unregister a hotkey.
  ///
  /// Note: When [isPaused] is true, the hotkey will not be unregistered again,
  /// since it is already unregistered when [pause] is called. Instead, it will
  /// simply not be registered again when [resume] is called.
  Future<void> unregister(HotKey hotkey) async {
    if (hotKeyToBindings[hotkey] == null) return;

    if (!_isPaused) {
      await hotKeyManager.unregister(hotkey);
    }
    hotKeyToBindings.remove(hotkey);
  }

  /// Register hot keys from a list.
  ///
  /// Note: When [isPaused] is true, the hotkeys will not be registered
  /// immediately until [resume] is called.
  Future<void> registerAll(List<HotKeyBinding> hotKeyBindingList) async {
    if (_isPaused) {
      for (final hotKeyBinding in hotKeyBindingList) {
        hotKeyToBindings[hotKeyBinding.hotKey] = hotKeyBinding;
      }
    } else {
      for (final hotKeyBinding in hotKeyBindingList) {
        final hotKey = hotKeyBinding.hotKey;
        if (hotKeyToBindings[hotKey] != null) {
          await hotKeyManager.unregister(hotKey);
          hotKeyToBindings.remove(hotKey);
        }

        await hotKeyManager.register(
          hotKey,
          keyDownHandler: hotKeyBinding.keyDownHandler,
          keyUpHandler: hotKeyBinding.keyUpHandler,
        );
        hotKeyToBindings[hotKey] = hotKeyBinding;
      }
    }
  }

  /// Unregister all hot keys.
  /// Call this when recording shortcut, so shortcuts already registered won't be triggered.
  /// This is also for debugging purposes, need to be called to support hot reload.
  ///
  /// Call in main function:
  ///
  /// ```dart
  /// await AppHotKeys.unregisterAll();
  /// ```
  ///
  /// Note: When [isPaused] is true, the hotkeys will not be unregistered again,
  /// since they are already unregistered when [pause] is called. Instead, they will
  /// simply not be registered again when [resume] is called.
  Future<void> unregisterAll() async {
    await hotKeyManager.unregisterAll();
    hotKeyToBindings.clear();
  }

  /// Pauses all hotkeys.
  ///
  /// This will unregister all hotkeys and prevent them from being triggered.
  /// If any hotkey is registered during paused, it will not be registered
  /// immediately until [resume] is called.
  Future<void> pause() async {
    if (_isPaused) return;

    _isPaused = true;
    await hotKeyManager.unregisterAll();
  }

  /// Resumes all hotkeys from pause.
  Future<void> resume() async {
    if (!_isPaused) return;

    for (final hotKeyBinding in hotKeyToBindings.values) {
      await hotKeyManager.register(
        hotKeyBinding.hotKey,
        keyDownHandler: hotKeyBinding.keyDownHandler,
        keyUpHandler: hotKeyBinding.keyUpHandler,
      );
    }
    _isPaused = false;
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
