import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:hotkey_manager/hotkey_manager.dart' show HotKey, HotKeyModifier;

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
