import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:win32/win32.dart';

class NativeWindowBridge {
  // Get the handle of the foreground window
  static int get _foregroundWindowHandle => GetForegroundWindow();

  /// Get the handle of the foreground window.
  /// Only the root window is returned.
  /// Return 0 if no window is active.
  static int getForegroundWindowHandle() {
    final hwnd = _foregroundWindowHandle;
    if (hwnd == 0) return 0;

    var candidate = hwnd;

    final root = GetAncestor(candidate, GA_ROOT);
    if (root != 0) candidate = root;

    final rootOwner = GetAncestor(candidate, GA_ROOTOWNER);
    if (rootOwner != 0) candidate = rootOwner;

    return candidate;
  }

  /// Toggle Foreground Window Topmost.
  /// Returns (hwnd, shouldTopmost, isSuccess).<br>
  /// hwnd: The handle of the window.<br>
  /// shouldTopmost: true if the window should be topmost, false otherwise.<br>
  /// isSuccess: true if the window was successfully toggled, false otherwise.
  static (int, bool, bool) toggleForegroundWindowTopmost() {
    final hwnd = getForegroundWindowHandle();

    if (hwnd == 0) {
      return (0, false, false);
    }

    final (shouldTopmost, isSuccess) = toggleTopmost(hwnd);

    return (hwnd, shouldTopmost, isSuccess);
  }

  /// Toggle Topmost.
  /// Returns (shouldTopmost, isSuccess).<br>
  /// shouldTopmost: true if the window should be topmost, false otherwise.<br>
  /// isSuccess: true if the window was successfully toggled, false otherwise.
  static (bool, bool) toggleTopmost(int hwnd) {
    final shouldTopmost = !isTopmost(hwnd);
    final isSuccess = setTopmost(hwnd, topmost: shouldTopmost);

    return (shouldTopmost, isSuccess);
  }

  /// Set or cancel the topmost state of a window.
  /// Returns true if the window was successfully set or canceled as topmost.
  static bool setTopmost(int hwnd, {bool topmost = true}) {
    final insertAfter = topmost ? HWND_TOPMOST : HWND_NOTOPMOST;
    final flags = SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE;

    final result = SetWindowPos(hwnd, insertAfter, 0, 0, 0, 0, flags);

    if (result == 0) {
      final error = GetLastError();
      _log("setTopmost", error);
      return false;
    }

    return true;
  }

  /// Returns true if the window is topmost.
  static bool isTopmost(int hwnd) {
    final exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);

    return (exStyle & WS_EX_TOPMOST) == WS_EX_TOPMOST;
  }

  static void _log(String functionName, int errorCode) {
    assert(() {
      final formatted = _formatError(errorCode);
      debugPrint(
        '[Native Window Bridge] $functionName: failed | Error $errorCode: $formatted',
      );
      return true;
    }());
  }

  static String _formatError(int errorCode) {
    final buffer = calloc<Pointer<Utf16>>();
    const flags =
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS;

    final length = FormatMessage(
      flags,
      nullptr,
      errorCode,
      0,
      buffer.cast(),
      0,
      nullptr,
    );

    if (length == 0) {
      calloc.free(buffer);
      return 'Windows error $errorCode';
    }

    final messagePtr = buffer.value;
    final message = messagePtr.toDartString().trim();
    LocalFree(messagePtr);
    calloc.free(buffer);
    return message;
  }
}
