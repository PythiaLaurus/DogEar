import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../theme/theme.dart';

class ShortcutRecorder extends ConsumerStatefulWidget {
  final HotKey? hotkeyDisplayed;
  final ValueChanged<HotKey?> onChanged;
  const ShortcutRecorder({
    super.key,
    this.hotkeyDisplayed,
    required this.onChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ShortcutRecorderState();
}

class _ShortcutRecorderState extends ConsumerState<ShortcutRecorder> {
  late final FocusNode _focusNode;
  bool _isRecording = false;
  HotKey? _editingHotKey;

  void _onFocusChange() {
    if (_isRecording != _focusNode.hasFocus) {
      setState(() {
        _isRecording = _focusNode.hasFocus;
        if (!_isRecording) {
          _editingHotKey = null;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // Handle keyboard events
  void _handleKeyboardEvent(KeyEvent event) async {
    if (event is! KeyDownEvent) {
      if (event is KeyUpEvent) {
        setState(() {
          _editingHotKey = null;
        });
      }
      return;
    }

    List<HotKeyModifier> modifiers = [];
    if (HardwareKeyboard.instance.isControlPressed) {
      modifiers.add(HotKeyModifier.control);
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      modifiers.add(HotKeyModifier.alt);
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      modifiers.add(HotKeyModifier.shift);
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      modifiers.add(HotKeyModifier.meta);
    }

    // Ignore modifier-only presses
    final key = event.logicalKey;

    setState(() {
      _editingHotKey = HotKey(key: key, modifiers: modifiers);
    });

    if (_isModifier(key)) return;

    // Handle delete
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      widget.onChanged(null);
      _focusNode.unfocus();
      return;
    }

    // It is a system shortcut by default
    final newKey = HotKey(
      key: key,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );

    widget.onChanged(newKey);

    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _isRecording ? _handleKeyboardEvent : null,
      child: TapRegion(
        onTapInside: (_) {
          _focusNode.requestFocus();
        },
        onTapOutside: (event) {
          _focusNode.unfocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isRecording
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.2)
                : appColors.primary,
            border: Border.all(
              color: _isRecording
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: _isRecording ? 1 : 0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _isRecording
                ? _editingHotKey == null
                      ? "Press any key..."
                      : _formatHotKey(_editingHotKey)
                : _formatHotKey(widget.hotkeyDisplayed),
            style: appTextStyles.body.copyWith(
              color: _isRecording
                  ? Theme.of(context).colorScheme.primary
                  : appColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatHotKey(HotKey? hotKey) {
    if (hotKey == null) return "No Shortcut";
    List<String> parts = [];
    if (hotKey.modifiers != null) {
      for (var m in hotKey.modifiers!) {
        // macOS: Command, Windows: Control
        parts.add(_getModifierLabel(m));
      }
    }

    if (!_isModifier(hotKey.key)) {
      parts.add(hotKey.key.keyLabel);
    }

    return parts.join(" + ");
  }

  bool _isModifier(KeyboardKey key) {
    return (key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight);
  }

  String _getModifierLabel(HotKeyModifier modifier) {
    switch (modifier) {
      case HotKeyModifier.alt:
        return 'Alt';
      case HotKeyModifier.control:
        return 'Ctrl';
      case HotKeyModifier.shift:
        return 'Shift';
      case HotKeyModifier.meta:
        return 'Meta';
      default:
        return modifier.toString().split('.').last;
    }
  }
}
