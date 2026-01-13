import 'dart:math' as math;
import 'dart:ffi';
import 'package:ffi/ffi.dart';
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

class Win32Service {
  static const int EVENT_OBJECT_LOCATIONCHANGE = 0x800B;
  static const int WINEVENT_OUTOFCONTEXT = 0x0000;
  static const int WINDING = 2;

  // --- Core Methods ---

  bool isTopMost(int hwnd) {
    final exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    return (exStyle & WS_EX_TOPMOST) == WS_EX_TOPMOST;
  }

  int getForegroundWindow() => GetForegroundWindow();

  int getEffectiveForegroundWindow({bool excludeCurrentProcess = true}) {
    final fg = GetForegroundWindow();
    if (fg == 0) return 0;

    var candidate = fg;

    final root = GetAncestor(candidate, GA_ROOT);
    if (root != 0) candidate = root;

    final rootOwner = GetAncestor(candidate, GA_ROOTOWNER);
    if (rootOwner != 0) candidate = rootOwner;

    final enabledPopup = GetWindow(candidate, GW_ENABLEDPOPUP);
    if (enabledPopup != 0 && IsWindowVisible(enabledPopup) != 0) {
      candidate = enabledPopup;
    }

    if (excludeCurrentProcess && isWindowFromCurrentProcess(candidate)) {
      return 0;
    }

    return candidate;
  }

  bool isWindowFromCurrentProcess(int hwnd) {
    final pidPtr = calloc<Uint32>();
    try {
      GetWindowThreadProcessId(hwnd, pidPtr);
      final windowPid = pidPtr.value;
      final currentPid = GetCurrentProcessId();
      return windowPid == currentPid;
    } finally {
      calloc.free(pidPtr);
    }
  }

  bool toggleAlwaysOnTop(int hwnd) {
    final nowTopMost = !isTopMost(hwnd);
    final ok = _setAlwaysOnTop(hwnd, enable: nowTopMost);
    if (!ok) {
      final code = GetLastError();
      final message = _formatSystemMessage(code);
      throw WindowsException(code, message);
    }
    return nowTopMost;
  }

  bool _setAlwaysOnTop(int hwnd, {required bool enable}) {
    final insertAfter = enable ? HWND_TOPMOST : HWND_NOTOPMOST;
    final flags = SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE;
    return SetWindowPos(hwnd, insertAfter, 0, 0, 0, 0, flags) != 0;
  }

  String getWindowTitle(int hwnd) {
    final length = GetWindowTextLength(hwnd);
    if (length == 0) return '';

    final buffer = wsalloc(length + 1);
    try {
      GetWindowText(hwnd, buffer, length + 1);
      return buffer.toDartString();
    } finally {
      free(buffer);
    }
  }

  String _formatSystemMessage(int errorCode) {
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

  bool relaunchElevated() {
    final exePath = _getCurrentExePath();
    if (exePath.isEmpty) return false;

    final verb = 'runas'.toNativeUtf16();
    final file = exePath.toNativeUtf16();
    final parameters = nullptr;
    final directory = nullptr;
    try {
      final result = ShellExecute(
        0,
        verb,
        file,
        parameters,
        directory,
        SW_SHOWNORMAL,
      );
      return result > 32;
    } finally {
      calloc.free(verb);
      calloc.free(file);
    }
  }

  String _getCurrentExePath() {
    final buffer = wsalloc(MAX_PATH);
    try {
      final len = GetModuleFileName(0, buffer, MAX_PATH);
      if (len == 0) return '';
      return buffer.toDartString(length: len);
    } finally {
      free(buffer);
    }
  }

  /// Create a named mutex to ensure single instance.
  /// Returns true if this is the first instance (mutex created successfully),
  /// false if the mutex already exists (another instance is running).
  bool ensureSingleInstance(String mutexName) {
    final namePtr = mutexName.toNativeUtf16();
    try {
      // Dynamic lookup for CreateMutexW to avoid resolution issues
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final createMutexW = kernel32
          .lookupFunction<
            IntPtr Function(Pointer<Void>, Int32, Pointer<Utf16>),
            int Function(Pointer<Void>, int, Pointer<Utf16>)
          >('CreateMutexW');

      final handle = createMutexW(nullptr, TRUE, namePtr);
      final error = GetLastError();

      // If handle is NULL, creation failed entirely
      if (handle == 0) {
        return false;
      }

      // If error is ERROR_ALREADY_EXISTS (183), an instance is already running
      if (error == 183) {
        return false;
      }

      return true;
    } finally {
      calloc.free(namePtr);
    }
  }

  bool getCursorPos(math.Point<int> outPoint) {
    final ptr = calloc<POINT>();
    try {
      final result = GetCursorPos(ptr);
      if (result != 0) {
        // We can't mutate the passed Point, but Dart Point is immutable anyway.
        // Wait, the caller expects a return value or a struct fill?
        // Dart style: return Point.
        return true;
      }
      return false;
    } finally {
      calloc.free(ptr);
    }
  }

  math.Point<int>? getCursorPosition() {
    final ptr = calloc<POINT>();
    try {
      final result = GetCursorPos(ptr);
      if (result != 0) {
        return math.Point(ptr.ref.x, ptr.ref.y);
      }
      return null;
    } finally {
      calloc.free(ptr);
    }
  }

  /// 获取窗口矩形区域
  /// 优先尝试使用 DwmGetWindowAttribute 获取可视区域（去除阴影等），
  /// 如果失败则回退到 GetWindowRect。
  math.Rectangle<int>? getWindowRect(int hwnd) {
    final rect = calloc<RECT>();
    try {
      // 1. Try DwmGetWindowAttribute for extended frame bounds (excludes shadow)
      try {
        // DWMWA_EXTENDED_FRAME_BOUNDS = 9
        final result = DwmGetWindowAttribute(hwnd, 9, rect, sizeOf<RECT>());
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

      // 2. Fallback to GetWindowRect
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
  // --- Native Overlay Support ---

  int createSolidBrush(int color) {
    return CreateSolidBrush(color);
  }

  int createPolygonRgn(List<math.Point<int>> points) {
    final lpPoints = calloc<POINT>(points.length);
    try {
      for (var i = 0; i < points.length; i++) {
        lpPoints[i].x = points[i].x;
        lpPoints[i].y = points[i].y;
      }

      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final createPolygonRgn = gdi32
          .lookupFunction<
            IntPtr Function(Pointer<POINT>, Int32, Int32),
            int Function(Pointer<POINT>, int, int)
          >('CreatePolygonRgn');

      return createPolygonRgn(lpPoints, points.length, WINDING);
    } finally {
      calloc.free(lpPoints);
    }
  }

  int setWindowRgn(int hwnd, int hRgn, bool bRedraw) {
    return SetWindowRgn(hwnd, hRgn, bRedraw ? TRUE : FALSE);
  }

  int setWinEventHook(
    int eventMin,
    int eventMax,
    int hmodWinEventProc,
    Pointer<NativeFunction<WinEventProc>> pfnWinEventProc,
    int idProcess,
    int idThread,
    int dwFlags,
  ) {
    final user32 = DynamicLibrary.open('user32.dll');
    final setWinEventHook = user32
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

  int unhookWinEvent(int hWinEventHook) {
    final user32 = DynamicLibrary.open('user32.dll');
    final unhookWinEvent = user32
        .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
          'UnhookWinEvent',
        );

    return unhookWinEvent(hWinEventHook);
  }

  int getWindowThreadProcessId(int hwnd) {
    return GetWindowThreadProcessId(hwnd, nullptr);
  }

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

  int createWindowEx(
    int dwExStyle,
    String lpClassName,
    String lpWindowName,
    int dwStyle,
    int x,
    int y,
    int nWidth,
    int nHeight,
    int hWndParent,
    int hMenu,
    int hInstance,
    Pointer<Void> lpParam,
  ) {
    final className = lpClassName.toNativeUtf16();
    final windowName = lpWindowName.toNativeUtf16();
    try {
      return CreateWindowEx(
        dwExStyle,
        className,
        windowName,
        dwStyle,
        x,
        y,
        nWidth,
        nHeight,
        hWndParent,
        hMenu,
        hInstance,
        lpParam,
      );
    } finally {
      calloc.free(className);
      calloc.free(windowName);
    }
  }

  int registerClass(WNDCLASS lpWndClass) {
    final ptr = calloc<WNDCLASS>();
    try {
      ptr.ref = lpWndClass;
      return RegisterClass(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  int defWindowProc(int hWnd, int Msg, int wParam, int lParam) {
    return DefWindowProc(hWnd, Msg, wParam, lParam);
  }

  int getModuleHandle(String? lpModuleName) {
    if (lpModuleName == null) return GetModuleHandle(nullptr);
    final name = lpModuleName.toNativeUtf16();
    try {
      return GetModuleHandle(name);
    } finally {
      calloc.free(name);
    }
  }

  int destroyWindow(int hwnd) {
    return DestroyWindow(hwnd);
  }

  int showWindow(int hwnd, int nCmdShow) {
    return ShowWindow(hwnd, nCmdShow);
  }

  int updateWindow(int hwnd) {
    return UpdateWindow(hwnd);
  }

  int setClassLongPtr(int hwnd, int nIndex, int dwNewLong) {
    return SetClassLongPtr(hwnd, nIndex, dwNewLong);
  }

  int setLayeredWindowAttributes(int hwnd, int crKey, int bAlpha, int dwFlags) {
    return SetLayeredWindowAttributes(hwnd, crKey, bAlpha, dwFlags);
  }

  int invalidateRect(int hwnd, Pointer<RECT> lpRect, bool bErase) {
    return InvalidateRect(hwnd, lpRect, bErase ? TRUE : FALSE);
  }
}

final class WindowsException implements Exception {
  WindowsException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'WindowsException(code: $code, message: $message)';
}
