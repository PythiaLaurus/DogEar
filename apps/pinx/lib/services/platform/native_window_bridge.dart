// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:win32/win32.dart';

// Callback types
typedef WinEventProc =
    Void Function(
      IntPtr hWinEventHook,
      Int32 event,
      IntPtr hwnd,
      Int32 idObject,
      Int32 idChild,
      Int32 dwEventThread,
      Int32 dwmsEventTime,
    );

const int EVENT_OBJECT_LOCATIONCHANGE = 0x800B;
const int WINEVENT_OUTOFCONTEXT = 0x0000;

class NativeWindowBridge {
  NativeWindowBridge._();
  static final instance = NativeWindowBridge._();

  final _user32 = DynamicLibrary.open('user32.dll');

  /// Get the handle of the foreground window.
  int get _foregroundWindowHandle => GetForegroundWindow();

  /// Toggles Foreground Window Topmost.
  /// Returns (hwnd, shouldTopmost, isSuccess).<br>
  /// hwnd: The handle of the window.<br>
  /// shouldTopmost: true if the window should be topmost, false otherwise.<br>
  /// isSuccess: true if the window was successfully toggled, false otherwise.
  ({int hwnd, bool shouldTopmost, bool isSuccess})
  toggleForegroundWindowTopmost() {
    final hwnd = getForegroundWindowHandle();

    if (hwnd == 0) {
      return (hwnd: 0, shouldTopmost: false, isSuccess: false);
    }

    final result = toggleTopmost(hwnd);

    return (
      hwnd: hwnd,
      shouldTopmost: result.shouldTopmost,
      isSuccess: result.isSuccess,
    );
  }

  /// Toggles Topmost.
  /// Returns ([shouldTopmost], [isSuccess]).<br>
  /// [shouldTopmost]: true if the window should be topmost, false otherwise.<br>
  /// [isSuccess]: true if the window was successfully toggled, false otherwise.
  ({bool shouldTopmost, bool isSuccess}) toggleTopmost(int hwnd) {
    final shouldTopmost = !isTopmost(hwnd);
    final isSuccess = setTopmost(hwnd, topmost: shouldTopmost);

    return (shouldTopmost: shouldTopmost, isSuccess: isSuccess);
  }

  /// Sets or cancel the topmost state of a window.
  /// Returns true if the window was successfully set or canceled as topmost.
  bool setTopmost(int hwnd, {bool topmost = true}) {
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
  bool isTopmost(int hwnd) {
    final exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);

    return (exStyle & WS_EX_TOPMOST) == WS_EX_TOPMOST;
  }

  /// Gets the handle of the foreground window.
  /// Only the root window is returned.
  /// Returns 0 if no window is active.
  int getForegroundWindowHandle() {
    final hwnd = _foregroundWindowHandle;
    if (hwnd == 0) return 0;

    var candidate = hwnd;

    final root = GetAncestor(candidate, GA_ROOT);
    if (root != 0) candidate = root;

    final rootOwner = GetAncestor(candidate, GA_ROOTOWNER);
    if (rootOwner != 0) candidate = rootOwner;

    return candidate;
  }

  /// Gets Rectangle area of window.
  /// Use DwmGetWindowAttribute to get visual accessible area (excluded shadow).
  /// If failed, fall back to GetWindowRect.
  math.Rectangle<int>? getWindowRect(int hwnd) {
    final rect = calloc<RECT>();
    try {
      // Try DwmGetWindowAttribute for extended frame bounds (excludes shadow)
      try {
        // DWMWA_EXTENDED_FRAME_BOUNDS = 9
        final result = DwmGetWindowAttribute(
          hwnd,
          DWMWA_EXTENDED_FRAME_BOUNDS,
          rect,
          sizeOf<RECT>(),
        );
        if (result == S_OK) {
          return math.Rectangle<int>(
            rect.ref.left,
            rect.ref.top,
            rect.ref.right - rect.ref.left,
            rect.ref.bottom - rect.ref.top,
          );
        }
      } catch (e) {
        // Ignore DWM errors
      }

      // Fallback to GetWindowRect
      final result = GetWindowRect(hwnd, rect);
      if (result != 0) {
        return math.Rectangle<int>(
          rect.ref.left,
          rect.ref.top,
          rect.ref.right - rect.ref.left,
          rect.ref.bottom - rect.ref.top,
        );
      }
      return null;
    } finally {
      calloc.free(rect);
    }
  }

  /// [SetWindowPos].
  void setWindowPos(
    int hwnd,
    int hwndInsertAfter,
    int x,
    int y,
    int cx,
    int cy,
    int uFlags,
  ) {
    SetWindowPos(hwnd, hwndInsertAfter, x, y, cx, cy, uFlags);
  }

  /// Returns the handle to the module containing the specified function.
  /// [lpModuleName] is the name of the module to be retrieved.
  /// If [lpModuleName] is null, the handle of the calling module is returned.
  int getModuleHandle(String? lpModuleName) {
    if (lpModuleName == null) return GetModuleHandle(nullptr);

    final name = lpModuleName.toNativeUtf16();

    try {
      return GetModuleHandle(name);
    } finally {
      calloc.free(name);
    }
  }

  /// Sets an event hook function for a range of events.
  ///
  /// [eventMin] specifies the event constant for the lowest event value in the range.
  /// [eventMax] specifies the event constant for the highest event value in the range.
  /// [hmodWinEventProc] handle to the DLL that contains the hook function (null for current process).
  /// [pfnWinEventProc] pointer to the event hook function.
  /// [idProcess] specifies the ID of the process from which the hook function receives events (0 for all).
  /// [idThread] specifies the ID of the thread from which the hook function receives events (0 for all).
  /// [dwFlags] flag values that specify the location of the hook function and of the events to be skipped.
  ///
  /// Returns an [HWINEVENTHOOK] handle that identifies this event hook instance.
  /// Returns 0 if the hook could not be installed.
  int setWinEventHook(
    int eventMin,
    int eventMax,
    int hmodWinEventProc,
    Pointer<NativeFunction<WinEventProc>> pfnWinEventProc,
    int idProcess,
    int idThread,
    int dwFlags,
  ) {
    final setWinEventHook = _user32
        .lookupFunction<
          IntPtr Function(
            Int32,
            Int32,
            IntPtr,
            Pointer<NativeFunction<WinEventProc>>,
            Int32,
            Int32,
            Int32,
          ),
          int Function(
            int,
            int,
            int,
            Pointer<NativeFunction<WinEventProc>>,
            int,
            int,
            int,
          )
        >('SetWinEventHook');

    return setWinEventHook(
      eventMin,
      eventMax,
      hmodWinEventProc,
      pfnWinEventProc,
      idProcess,
      idThread,
      dwFlags,
    );
  }

  /// Removes an event hook function created by a previous call to [setWinEventHook].
  ///
  /// [hWinEventHook] is the handle to the event hook returned by the previous
  /// call to [setWinEventHook].
  ///
  /// Returns a non-zero value (TRUE) if successful; otherwise, returns 0 (FALSE).
  int unhookWinEvent(int hWinEventHook) {
    final unhookWinEvent = _user32
        .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
          'UnhookWinEvent',
        );

    return unhookWinEvent(hWinEventHook);
  }

  /// Registers a window class, used to call [CreateWindowEx] (with
  /// lpszClassName set to [lpWndClass]).
  /// Return an ATOM, representing a unique code for the class registered.
  /// Return 0 if failed.
  int registerClass(WNDCLASS lpWndClass) {
    final ptr = calloc<WNDCLASS>();
    try {
      ptr.ref = lpWndClass;
      return RegisterClass(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// DebugPrint.
  void _log(String functionName, int errorCode) {
    assert(() {
      final formatted = _formatError(errorCode);
      debugPrint(
        '[Native Window Bridge] $functionName: failed | Error $errorCode: $formatted',
      );
      return true;
    }());
  }

  /// Finds actual error message from error code and format it.
  /// Used by [_log].
  String _formatError(int errorCode) {
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

final nativeWindowBridge = NativeWindowBridge.instance;
