// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'native_extension.dart';

class NativeWindowBridge with NativaErrorLogger {
  NativeWindowBridge._();
  static final instance = NativeWindowBridge._();

  @override
  String get moduleName => "NativeWindowBridge";

  /// [DestroyWindow].
  ///
  /// Destroys the specified window and releases its resources.
  ///
  /// [hwnd] A handle to the window to be destroyed.
  ///
  /// Returns true if the function succeeds; false if it fails.
  /// Note: A window cannot be destroyed if it was created by another thread.
  bool destroyWindow(HWND hwnd) {
    final result = DestroyWindow(hwnd);
    log("destroyWindow", result);
    return result.value;
  }

  /// [SetForegroundWindow].
  ///
  /// Brings the specified window into the foreground and activates the window.
  ///
  /// [hwnd] A handle to the window.
  ///
  /// Returns true if the window was successfully brought to the foreground.
  bool setForegroundWindow(HWND hwnd) {
    final result = SetForegroundWindow(hwnd);
    log("setForegroundWindow", NativeError.getSuccessWin32Result(result));
    return result;
  }

  /// [ShowWindow].
  ///
  /// Sets the specified window's show state.
  ///
  /// [hwnd] A handle to the window.
  ///
  /// [nCmdShow] Controls how the window is to be shown (e.g., SW_SHOW, SW_HIDE).
  ///
  /// Returns true if the window was previously visible, otherwise false.
  ///
  /// Note: The return value does not indicate success or failure of the command.
  bool showWindow(HWND hwnd, SHOW_WINDOW_CMD nCmdShow) {
    final result = ShowWindow(hwnd, nCmdShow);
    log("showWindow", NativeError.getSuccessWin32Result(result));
    return result;
  }

  /// [UpdateWindow].
  ///
  /// Updates the client area of the specified window by sending a WM_PAINT message
  /// directly to the window procedure if the update region is not empty.
  ///
  /// [hwnd] A handle to the window to be updated.<br>
  ///
  /// Returns true if the function succeeds; otherwise false.
  bool updateWindow(HWND hwnd) {
    final result = UpdateWindow(hwnd);
    log("updateWindow", NativeError.getSuccessWin32Result(result));
    return result;
  }

  /// [IsWindowVisible].
  ///
  /// Determines the visibility state of the specified window.
  ///
  /// [hwnd] A handle to the window to be tested.
  ///
  /// Returns true if the specified window has WS_VISIBLE, not minimized, not
  /// cloaked. Otherwise false.
  bool isWindowVisible(HWND hwnd) {
    // Check WS_VISIBLE & WS_MINIMIZE
    if (!IsWindowVisible(hwnd) || IsIconic(hwnd)) {
      log("isWindowVisible", NativeError.getSuccessWin32Result(false));
      return false;
    }

    // Check Cloaked (e.g. virtual desktop, UWP app)
    final cloakedPtr = calloc<Int32>();
    try {
      DwmGetWindowAttribute(
        hwnd,
        DWMWA_CLOAKED,
        cloakedPtr.cast<Void>(),
        sizeOf<Int32>(),
      );

      // If it's Cloaked (value is not zero), return false
      if (cloakedPtr.value != 0) return false;
    } on WindowsException catch (e) {
      log("isWindowVisible", NativeError.getExceptionWin32Result(e));
    } finally {
      free(cloakedPtr);
    }

    log("isWindowVisible", NativeError.getSuccessWin32Result(true));
    return true;
  }

  /// Toggles window under cursor topmost.
  ///
  /// Returns (hwnd, shouldTopmost, isSuccess).<br>
  /// hwnd: The handle of the window.<br>
  /// shouldTopmost: true if the window should be topmost, false otherwise.<br>
  /// isSuccess: true if the window was successfully toggled, false otherwise.
  ({HWND hwnd, bool shouldTopmost, bool isSuccess})
  toggleUnderCursorWindowTopmost() {
    final hwnd = getUnderCursorWindowHandle();

    if (hwnd.isNull) {
      log(
        "toggleUnderCursorWindowTopmost",
        NativeError.getSuccessWin32Result(HWND_NULL),
      );
      return (hwnd: HWND_NULL, shouldTopmost: false, isSuccess: false);
    }

    final result = toggleTopmost(hwnd);
    final value = (
      hwnd: hwnd,
      shouldTopmost: result.shouldTopmost,
      isSuccess: result.isSuccess,
    );

    log(
      "toggleUnderCursorWindowTopmost",
      NativeError.getSuccessWin32Result(value),
    );
    return value;
  }

  /// Toggles foreground window topmost.
  ///
  /// Returns (hwnd, shouldTopmost, isSuccess).<br>
  /// hwnd: The handle of the window.<br>
  /// shouldTopmost: true if the window should be topmost, false otherwise.<br>
  /// isSuccess: true if the window was successfully toggled, false otherwise.
  ({HWND hwnd, bool shouldTopmost, bool isSuccess})
  toggleForegroundWindowTopmost() {
    final hwnd = getForegroundWindowHandle();

    if (hwnd.isNull) {
      final value = (hwnd: HWND_NULL, shouldTopmost: false, isSuccess: false);
      log(
        "toggleForegroundWindowTopmost",
        NativeError.getSuccessWin32Result(value),
      );
      return value;
    }

    final result = toggleTopmost(hwnd);
    final value = (
      hwnd: hwnd,
      shouldTopmost: result.shouldTopmost,
      isSuccess: result.isSuccess,
    );

    log(
      "toggleForegroundWindowTopmost",
      NativeError.getSuccessWin32Result(value),
    );
    return value;
  }

  /// Toggles Topmost.
  /// Returns ([shouldTopmost], [isSuccess]).<br>
  /// [shouldTopmost]: true if the window should be topmost, false otherwise.<br>
  /// [isSuccess]: true if the window was successfully toggled, false otherwise.
  ({bool shouldTopmost, bool isSuccess}) toggleTopmost(HWND hwnd) {
    final shouldTopmost = !isTopmost(hwnd);
    final isSuccess = setTopmost(hwnd, shouldTopmost);

    final value = (shouldTopmost: shouldTopmost, isSuccess: isSuccess);
    log("toggleTopmost", NativeError.getSuccessWin32Result(value));

    return value;
  }

  /// Sets or cancel the topmost state of a window.
  ///
  /// Returns true if the window was successfully set or canceled as topmost.
  ///
  /// Note: To ensure system's response, this will bring the window to foreground whether or not set to topmost.
  bool setTopmost(HWND hwnd, [bool topmost = true]) {
    final insertAfter = topmost ? HWND_TOPMOST : HWND_NOTOPMOST;
    final flags = SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE;

    setForegroundWindow(hwnd);
    final result = SetWindowPos(hwnd, insertAfter, 0, 0, 0, 0, flags);

    log("setTopmost", result);
    return result.value;
  }

  /// Returns true if the window is topmost.
  bool isTopmost(HWND hwnd) {
    final exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    final value = (exStyle.value & WS_EX_TOPMOST) == WS_EX_TOPMOST;

    log("isTopmost", Win32Result(value: value, error: exStyle.error));
    return value;
  }

  /// Gets the handle of the top-level window located at the current mouse position.
  ///
  /// Only the root window is returned.
  ///
  /// Returns 0 if no window is found or if the cursor position cannot be retrieved.
  HWND getUnderCursorWindowHandle() {
    // Allocate memory for the POINT structure to store coordinates
    final pPoint = calloc<POINT>();

    try {
      // Get the current cursor position in screen coordinates
      final result = GetCursorPos(pPoint);
      if (!result.value) {
        // Return 0 if failed
        log(
          "getUnderCursorWindowHandle",
          Win32Result(value: HWND_NULL, error: result.error),
        );
        return HWND_NULL;
      }

      // Identify the window at the specified point
      // WindowFromPoint may return a child window (e.g., a button or a text area)
      final hwndPoint = WindowFromPoint(pPoint.ref);

      if (hwndPoint.isNull) {
        log(
          "getUnderCursorWindowHandle",
          NativeError.getSuccessWin32Result(hwndPoint),
        );
        return hwndPoint;
      }

      return getRootWindowHandle(hwndPoint);
    } finally {
      free(pPoint);
    }
  }

  /// Gets the handle of the foreground window.
  ///
  /// Only the root window is returned.
  ///
  /// Returns 0 if no window is active.
  HWND getForegroundWindowHandle() {
    final hwnd = GetForegroundWindow();
    if (hwnd.isNull) {
      log("getForegroundWindowHandle", NativeError.getSuccessWin32Result(hwnd));
      return hwnd;
    }

    return getRootWindowHandle(hwnd);
  }

  /// Gets the root window handle of a window.
  ///
  /// Returns the root window handle of the window handle passed in.
  HWND getRootWindowHandle(HWND hwnd) {
    var candidate = hwnd;

    final root = GetAncestor(candidate, GA_ROOT);
    if (root.isNotNull) candidate = root;

    final rootOwner = GetAncestor(candidate, GA_ROOTOWNER);
    if (rootOwner.isNotNull) candidate = rootOwner;

    log("getRootWindowHandle", NativeError.getSuccessWin32Result(candidate));
    return candidate;
  }

  /// Gets the process name of a window.
  ///
  /// Returns the process name if successful, otherwise null.
  String? getProcessName(HWND hwnd) {
    String processName = '';

    final processIdPtr = calloc<Uint32>();
    try {
      // Get process ID
      GetWindowThreadProcessId(hwnd, processIdPtr);
      final pid = processIdPtr.value;

      if (pid == 0) {
        log("getProcessName", NativeError.noneResult);
        return null;
      }

      // Open process to query information
      // PROCESS_QUERY_INFORMATION: Allow query information
      // PROCESS_VM_READ: Allow read memory (for some old APIs, it's required))
      final hProcessResult = OpenProcess(
        PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
        false,
        pid,
      );
      final hProcess = hProcessResult.value;

      if (!hProcess.isValid) {
        log("getProcessName", NativeError.noneResult);
        return null;
      }

      try {
        // buffer to store process name
        final buffer = calloc<Uint16>(MAX_PATH).cast<Utf16>();

        try {
          // Get process module base name (e.g., "notepad.exe")
          // hModule: 0 (NULL) refers to the executable itself
          final result = GetModuleBaseName(
            hProcess,
            null,
            PWSTR(buffer),
            MAX_PATH,
          );

          if (result.value > 0) {
            processName = buffer.toDartString();
          }
        } finally {
          free(buffer);
        }
      } finally {
        hProcess.close();
      }
    } finally {
      free(processIdPtr);
    }

    if (processName.isEmpty) {
      log("getProcessName", NativeError.noneResult);
      return null;
    } else {
      log("getProcessName", NativeError.getSuccessWin32Result(processName));
      return processName;
    }
  }

  /// Gets Rectangle area of window.
  /// Use DwmGetWindowAttribute to get visual accessible area (excluded shadow).
  /// If failed, fall back to GetWindowRect.
  math.Rectangle<int>? getWindowRect(HWND hwnd) {
    final rect = calloc<RECT>();
    try {
      // Try DwmGetWindowAttribute for extended frame bounds (excludes shadow)
      try {
        // DWMWA_EXTENDED_FRAME_BOUNDS = 9
        DwmGetWindowAttribute(
          hwnd,
          DWMWA_EXTENDED_FRAME_BOUNDS,
          rect,
          sizeOf<RECT>(),
        );
        return math.Rectangle<int>(
          rect.ref.left,
          rect.ref.top,
          rect.ref.right - rect.ref.left,
          rect.ref.bottom - rect.ref.top,
        );
      } on WindowsException catch (e) {
        log("getWindowRect", NativeError.getExceptionWin32Result(e));
      }

      // Fallback to GetWindowRect
      final result = GetWindowRect(hwnd, rect);
      if (result.value) {
        return math.Rectangle<int>(
          rect.ref.left,
          rect.ref.top,
          rect.ref.right - rect.ref.left,
          rect.ref.bottom - rect.ref.top,
        );
      }
      return null;
    } finally {
      free(rect);
    }
  }

  /// [SetWindowPos]
  ///
  /// Changes the size, position, and Z-order of a child, pop-up, or top-level window.
  ///
  /// [hwnd] A handle to the window.<br>
  /// [hwndInsertAfter] A handle to the window to precede the positioned window in the Z order (e.g., HWND_TOPMOST).<br>
  /// [x], [y] The new coordinates of the left and top sides of the window.<br>
  /// [cx], [cy] The new width and height of the window, in pixels.<br>
  /// [uFlags] The window sizing and positioning flags (e.g., SWP_NOSIZE | SWP_NOACTIVATE).<br>
  ///
  /// Returns true if the function succeeds; otherwise returns false.
  bool setWindowPos(
    HWND hwnd,
    HWND hwndInsertAfter,
    int x,
    int y,
    int cx,
    int cy,
    SET_WINDOW_POS_FLAGS uFlags,
  ) {
    final result = SetWindowPos(hwnd, hwndInsertAfter, x, y, cx, cy, uFlags);
    return result.value;
  }

  /// Creates a native Win32 Region handle (HRGN) from Dart points.
  ///
  /// Returns a handle to the region (HRGN) if successful, or 0 on failure.
  ///
  /// Note: The returned handle ownership is usually transferred to the
  /// window when used with [SetWindowRgn].
  HRGN createPolygonRgn(List<math.Point<int>> points) {
    final lpPoints = calloc<POINT>(points.length);
    try {
      for (var i = 0; i < points.length; i++) {
        lpPoints[i].x = points[i].x;
        lpPoints[i].y = points[i].y;
      }

      final value = HRGN(
        Pointer.fromAddress(CreatePolygonRgn(lpPoints, points.length, WINDING)),
      );
      log("createPolygonRgn", NativeError.getSuccessWin32Result(value));
      return value;
    } finally {
      free(lpPoints);
    }
  }

  /// [SetWindowRgn].
  ///
  /// Sets the window region of a window.
  /// The window region determines the area where the system permits drawing.
  ///
  /// [hwnd] Handle to the window whose window region is to be set.<br>
  /// [hRgn] Handle to a region. The function sets the [window region] of the [window] to this [region]
  /// (this may be a bit awkward to read, it means that this function uses the provided region handle
  /// as a template to crop the window's shape).<br>
  /// [bRedraw] Specifies whether the system redraws the window after setting the window region
  /// (immediately redraw or wait until the next time that system decides to redraw).<br>
  ///
  /// Returns true if successful; otherwise, returns false.
  ///
  /// IMPORTANT: After a successful call, the system owns the region specified by the region handle [hRgn].
  /// Do not make further function calls with this region handle, and do not delete it.
  ///
  /// Will automatically delete the region handle if the function fails, so don't call [DeleteObject] manually.
  bool setWindowRgn(HWND hwnd, HRGN hRgn, bool bRedraw) {
    final result = SetWindowRgn(hwnd, hRgn, bRedraw);

    if (result == 0) {
      hRgn.close();
      log("setWindowRgn", NativeError.noneResult);
      return false;
    }

    log("setWindowRgn", NativeError.getSuccessWin32Result(true));
    return true;
  }

  /// [InvalidateRect].
  ///
  /// Adds a rectangle to the specified window's update region.
  /// This tells Windows that the area needs to be repainted.
  ///
  /// [hwnd] A handle to the window whose update region has changed.<br>
  /// [lpRect] A pointer to a RECT structure that contains the coordinates of the update region.<br>
  /// If this parameter is [nullptr], the entire client area is added to the update region.<br>
  /// [bErase] Specifies whether the background within the update region is to be erased
  /// when the update region is processed. If true, the background inside the
  /// update region is erased (using the [hbrBackground] regesitered in the [WNDCLASS]) before repainting.
  /// If false, the background remains unchanged, and you just draw over it.<br>
  ///
  /// Returns true if the function succeeds; otherwise false.
  bool invalidateRect(HWND hwnd, Pointer<RECT> lpRect, bool bErase) {
    final result = InvalidateRect(hwnd, lpRect, bErase);
    log("invalidateRect", NativeError.getSuccessWin32Result(result));
    return result;
  }

  /// [SetClassLongPtr].
  ///
  /// Replaces the specified value at the specified offset in the extra class memory
  /// or the WNDCLASSEX structure for the class to which the window belongs.
  ///
  /// [hwnd] A handle to the window and, indirectly, the class to which the window belongs.<br>
  /// [nIndex] The value to be replaced (e.g., GCLP_HBRBACKGROUND, GCLP_HICON).<br>
  /// [dwNewLong] The replacement value.<br>
  ///
  /// Returns the previous value of the specified offset. If the previous value is 0
  /// and the function succeeds, the return value is 0, but GetLastError will still be 0.
  /// Returns 0 on failure.
  int setClassLongPtr(HWND hwnd, GET_CLASS_LONG_INDEX nIndex, int dwNewLong) {
    final result = SetClassLongPtr(hwnd, nIndex, dwNewLong);
    log("setClassLongPtr", result);
    return result.value;
  }

  /// Sets the window owner by setting the GWLP_HWNDPARENT window property.
  void setWindowOwner(HWND childHwnd, HWND ownerHwnd) {
    final result = SetWindowLongPtr(
      childHwnd,
      GWLP_HWNDPARENT,
      ownerHwnd.address,
    );
    log("setWindowOwner", result);
  }

  /// [SetLayeredWindowAttributes].
  ///
  /// Sets the opacity and transparency color key of a layered window.
  ///
  /// [hwnd] is the handle to the layered window.<br>
  /// [crKey] specifies the color key (in BGR order: 0xBBGGRR).<br>
  /// [bAlpha] specifies the opacity value (0 to 255).<br>
  /// [dwFlags] determines the action to take (e.g., LWA_COLORKEY, LWA_ALPHA).<br>
  ///
  /// Note: The window must have the WS_EX_LAYERED style set.
  ///
  /// Returns true if successful; otherwise, returns false.
  bool setLayeredWindowAttributes(
    HWND hwnd,
    COLORREF crKey,
    int bAlpha,
    LAYERED_WINDOW_ATTRIBUTES_FLAGS dwFlags,
  ) {
    final result = SetLayeredWindowAttributes(hwnd, crKey, bAlpha, dwFlags);
    log("setLayeredWindowAttributes", result);
    return result.value;
  }

  /// [CreateWindowEx].
  ///
  /// Creates an overlapped, pop-up, or child window with an extended window style.
  ///
  /// [dwExStyle] specifies the extended window style (e.g., WS_EX_LAYERED).<br>
  /// [lpClassName] is the name of the window class registered via RegisterClass.<br>
  /// [lpWindowName] is the window title (can be empty for overlays).<br>
  /// [dwStyle] specifies the window style (e.g., WS_POPUP).<br>
  /// [x], [y], [nWidth], [nHeight] define the initial position and dimensions.<br>
  /// [hWndParent] is the handle to the parent or owner window.<br>
  /// [hInstance] is the handle to the instance of the module to be associated with the window.<br>
  /// [lpParam] is a pointer to a value to be passed to the window through the CREATESTRUCT.<br>
  ///
  /// This wrapper handles the conversion of Dart [String] to Native Utf16 and
  /// ensures memory is freed after the native call.
  ///
  /// Returns the window handle (hwnd) if successful; otherwise, returns 0.
  HWND createWindowEx(
    WINDOW_EX_STYLE dwExStyle,
    String lpClassName,
    String lpWindowName,
    WINDOW_STYLE dwStyle,
    int x,
    int y,
    int nWidth,
    int nHeight,
    HWND hWndParent,
    HMENU hMenu,
    HINSTANCE hInstance,
    Pointer<Void> lpParam,
  ) {
    final className = lpClassName.toNativeUtf16();
    final windowName = lpWindowName.toNativeUtf16();
    try {
      final result = CreateWindowEx(
        dwExStyle,
        PCWSTR(className),
        PCWSTR(windowName),
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
      log("createWindowEx", result);
      return result.value;
    } finally {
      free(className);
      free(windowName);
    }
  }

  /// Returns the handle to the module containing the specified function.
  /// [lpModuleName] is the name of the module to be retrieved.
  /// If [lpModuleName] is null, the handle of the calling module
  /// (current dart process) is returned.
  HMODULE getModuleHandle(String? lpModuleName) {
    if (lpModuleName == null) {
      final result = GetModuleHandle(PCWSTR(nullptr));
      log("getModuleHandle", result);
      return result.value;
    }

    final name = lpModuleName.toNativeUtf16();

    try {
      final result = GetModuleHandle(PCWSTR(name));
      log("getModuleHandle", result);
      return result.value;
    } finally {
      free(name);
    }
  }

  /// [SetWinEventHook].
  ///
  /// Sets an event hook function for a range of events.
  ///
  /// [eventMin] specifies the event constant for the lowest event value in the range.<br>
  /// [eventMax] specifies the event constant for the highest event value in the range.<br>
  /// [hmodWinEventProc] handle to the DLL that contains the hook function (null for current process).<br>
  /// [pfnWinEventProc] pointer to the event hook function.<br>
  /// [idProcess] specifies the ID of the process from which the hook function receives events (0 for all).<br>
  /// [idThread] specifies the ID of the thread from which the hook function receives events (0 for all).<br>
  /// [dwFlags] flag values that specify the location of the hook function and of the events to be skipped.<br>
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
    final result = SetWinEventHook(
      eventMin,
      eventMax,
      hmodWinEventProc,
      pfnWinEventProc,
      idProcess,
      idThread,
      dwFlags,
    );
    log("setWinEventHook", NativeError.getSuccessWin32Result(result));
    return result;
  }

  /// Removes an event hook function created by a previous call to [setWinEventHook].
  ///
  /// [hWinEventHook] is the handle to the event hook returned by the previous
  /// call to [setWinEventHook].
  ///
  /// Returns true if successful; otherwise, returns false.
  bool unhookWinEvent(int hWinEventHook) {
    final result = UnhookWinEvent(hWinEventHook) != 0;
    log("unhookWinEvent", NativeError.getSuccessWin32Result(result));
    return result;
  }

  /// Registers a window class, used to call [CreateWindowEx] (with
  /// lpszClassName set to [lpWndClass]).
  ///
  /// Returns an ATOM, representing a unique code for the class registered.
  ///
  /// Returns 0 if failed.
  int registerClass(WNDCLASS lpWndClass) {
    final ptr = calloc<WNDCLASS>();
    try {
      ptr.ref = lpWndClass;
      final result = RegisterClass(ptr);
      log("registerClass", result);
      return result.value;
    } finally {
      free(ptr);
    }
  }

  /// [UnregisterClass].
  ///
  /// Unregisters a window class created by the [registerClass] function.
  ///
  /// [lpClassName] is the name of the window class to be unregistered.<br>
  /// [hInstance] is the handle to the module that created the class.<br>
  ///
  /// Returns true if successful; otherwise, returns false.
  bool unregisterClass(String lpClassName, HINSTANCE hInstance) {
    final className = lpClassName.toNativeUtf16();
    try {
      final result = UnregisterClass(PCWSTR(className), hInstance);
      log("unregisterClass", result);
      return result.value;
    } finally {
      free(className);
    }
  }

  /// [GetClassName].
  ///
  /// Retrieves the window class name of the specified window.
  ///
  /// [hwnd] is the handle to the window whose class name is to be retrieved.
  ///
  /// Returns the window class name if successful; otherwise null.
  String? getClassName(HWND hwnd) {
    final maxCount = 256;
    final buffer = calloc<Uint16>(maxCount).cast<Utf16>();

    try {
      final result = GetClassName(hwnd, PWSTR(buffer), maxCount);

      if (result.value == 0) {
        log("getClassName", NativeError.noneResult);
        return null;
      }

      final value = buffer.toDartString();
      log("getClassName", NativeError.getSuccessWin32Result(value));
      return value;
    } finally {
      free(buffer);
    }
  }
}

final nativeWindowBridge = NativeWindowBridge.instance;
