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
  String get moduleName => "[NativeWindowBridge]";

  /// [DestroyWindow].
  ///
  /// Destroys the specified window and releases its resources.
  ///
  /// [hwnd] A handle to the window to be destroyed.
  ///
  /// Returns true if the function succeeds; false if it fails.
  /// Note: A window cannot be destroyed if it was created by another thread.
  bool destroyWindow(int hwnd) {
    final result = DestroyWindow(hwnd);
    log("destroyWindow");
    return result != 0;
  }

  /// [SetForegroundWindow].
  ///
  /// Brings the specified window into the foreground and activates the window.
  ///
  /// [hwnd] A handle to the window.
  ///
  /// Returns true if the window was successfully brought to the foreground.
  bool setForegroundWindow(int hwnd) {
    final result = SetForegroundWindow(hwnd);
    log("setForegroundWindow");
    return result != 0;
  }

  /// [ShowWindow].
  ///
  /// Sets the specified window's show state.
  ///
  /// [hwnd] A handle to the window.<br>
  /// [nCmdShow] Controls how the window is to be shown (e.g., SW_SHOW, SW_HIDE).<br>
  ///
  /// Returns a non-zero value if the window was previously visible.
  /// Returns zero if the window was previously hidden.
  /// Note: The return value does not indicate success or failure of the command.
  int showWindow(int hwnd, int nCmdShow) {
    return ShowWindow(hwnd, nCmdShow);
  }

  /// [UpdateWindow].
  ///
  /// Updates the client area of the specified window by sending a WM_PAINT message
  /// directly to the window procedure if the update region is not empty.
  ///
  /// [hwnd] A handle to the window to be updated.<br>
  ///
  /// Returns true if the function succeeds; otherwise false.
  bool updateWindow(int hwnd) {
    final result = UpdateWindow(hwnd);
    log("updateWindow");
    return result != 0;
  }

  /// [IsWindowVisible].
  ///
  /// Determines the visibility state of the specified window.
  ///
  /// [hwnd] A handle to the window to be tested.
  ///
  /// Returns true if the specified window has WS_VISIBLE, not minimized, not
  /// cloaked. Otherwise false.
  bool isWindowVisible(int hwnd) {
    // Check WS_VISIBLE first
    if (IsWindowVisible(hwnd) == 0) return false;
    // Check WS_MINIMIZE
    if (IsIconic(hwnd) != 0) return false;

    // Check Cloaked (e.g. virtual desktop, UWP app)
    final cloakedPtr = calloc<Int32>();
    try {
      final hr = DwmGetWindowAttribute(
        hwnd,
        DWMWA_CLOAKED,
        cloakedPtr.cast<Void>(),
        sizeOf<Int32>(),
      );

      if (hr == S_OK) {
        // If it's Cloaked (value is not zero), return false
        if (cloakedPtr.value != 0) return false;
      }
    } finally {
      calloc.free(cloakedPtr);
    }

    return true;
  }

  /// Toggles window under cursor topmost.
  ///
  /// Returns (hwnd, shouldTopmost, isSuccess).<br>
  /// hwnd: The handle of the window.<br>
  /// shouldTopmost: true if the window should be topmost, false otherwise.<br>
  /// isSuccess: true if the window was successfully toggled, false otherwise.
  ({int hwnd, bool shouldTopmost, bool isSuccess})
  toggleUnderCursorWindowTopmost() {
    final hwnd = getUnderCursorWindowHandle();

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

  /// Toggles foreground window topmost.
  ///
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
    final isSuccess = setTopmost(hwnd, shouldTopmost);

    return (shouldTopmost: shouldTopmost, isSuccess: isSuccess);
  }

  /// Sets or cancel the topmost state of a window.
  ///
  /// Returns true if the window was successfully set or canceled as topmost.
  ///
  /// Note: To ensure system's response, this will bring the window to foreground whether or not set to topmost.
  bool setTopmost(int hwnd, [bool topmost = true]) {
    final insertAfter = topmost ? HWND_TOPMOST : HWND_NOTOPMOST;
    final flags = SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE;

    setForegroundWindow(hwnd);
    final result = SetWindowPos(hwnd, insertAfter, 0, 0, 0, 0, flags);

    if (result == 0) {
      log("setTopmost");
      return false;
    }

    return true;
  }

  /// Returns true if the window is topmost.
  bool isTopmost(int hwnd) {
    final exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);

    return (exStyle & WS_EX_TOPMOST) == WS_EX_TOPMOST;
  }

  /// Gets the handle of the top-level window located at the current mouse position.
  ///
  /// Only the root window is returned.
  ///
  /// Returns 0 if no window is found or if the cursor position cannot be retrieved.
  int getUnderCursorWindowHandle() {
    // Allocate memory for the POINT structure to store coordinates
    final pPoint = calloc<POINT>();

    try {
      // Get the current cursor position in screen coordinates
      final result = GetCursorPos(pPoint);
      if (result == 0) {
        // Return 0 if failed
        log("getUnderCursorWindowHandle");
        return 0;
      }

      // Identify the window at the specified point
      // WindowFromPoint may return a child window (e.g., a button or a text area)
      final hwndPoint = WindowFromPoint(pPoint.ref);

      if (hwndPoint == 0) return 0;

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
  int getForegroundWindowHandle() {
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) return 0;

    return getRootWindowHandle(hwnd);
  }

  /// Gets the root window handle of a window.
  ///
  /// Returns the root window handle of the window handle passed in.
  int getRootWindowHandle(int hwnd) {
    var candidate = hwnd;

    final root = GetAncestor(candidate, GA_ROOT);
    if (root != 0) candidate = root;

    final rootOwner = GetAncestor(candidate, GA_ROOTOWNER);
    if (rootOwner != 0) candidate = rootOwner;

    return candidate;
  }

  /// Gets the process name of a window.
  ///
  /// Returns the process name if successful, otherwise null.
  String? getProcessName(int hwnd) {
    String processName = '';

    final processIdPtr = calloc<Uint32>();
    try {
      // Get process ID
      GetWindowThreadProcessId(hwnd, processIdPtr);
      final pid = processIdPtr.value;

      if (pid == 0) return null;

      // Open process to query information
      // PROCESS_QUERY_INFORMATION: Allow query information
      // PROCESS_VM_READ: Allow read memory (for some old APIs, it's required))
      final hProcess = OpenProcess(
        PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
        FALSE,
        pid,
      );

      if (hProcess == 0) return null;

      try {
        // buffer to store process name
        final buffer = calloc<Uint16>(MAX_PATH).cast<Utf16>();

        try {
          // Get process module base name (e.g., "notepad.exe")
          // hModule: 0 (NULL) refers to the executable itself
          final result = GetModuleBaseName(hProcess, 0, buffer, MAX_PATH);

          if (result > 0) {
            processName = buffer.toDartString();
          }
        } finally {
          calloc.free(buffer);
        }
      } finally {
        CloseHandle(hProcess);
      }
    } finally {
      log("getProcessName");
      calloc.free(processIdPtr);
    }

    return processName.isEmpty ? null : processName;
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
      log("getWindowRect");
      calloc.free(rect);
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
    int hwnd,
    int hwndInsertAfter,
    int x,
    int y,
    int cx,
    int cy,
    int uFlags,
  ) {
    final result = SetWindowPos(hwnd, hwndInsertAfter, x, y, cx, cy, uFlags);
    log("setWindowPos");
    return result != 0;
  }

  /// Creates a native Win32 Region handle (HRGN) from Dart points.
  ///
  /// Returns a handle to the region (HRGN) if successful, or 0 on failure.
  ///
  /// Note: The returned handle ownership is usually transferred to the
  /// window when used with [SetWindowRgn].
  int createPolygonRgn(List<math.Point<int>> points) {
    final lpPoints = calloc<POINT>(points.length);
    try {
      for (var i = 0; i < points.length; i++) {
        lpPoints[i].x = points[i].x;
        lpPoints[i].y = points[i].y;
      }

      return CreatePolygonRgn(lpPoints, points.length, WINDING);
    } finally {
      log("createPolygonRgn");
      calloc.free(lpPoints);
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
  bool setWindowRgn(int hwnd, int hRgn, bool bRedraw) {
    final result = SetWindowRgn(hwnd, hRgn, bRedraw ? TRUE : FALSE);

    if (result == 0) {
      DeleteObject(hRgn);
      log("setWindowRgn");
      return false;
    }

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
  bool invalidateRect(int hwnd, Pointer<RECT> lpRect, bool bErase) {
    final result = InvalidateRect(hwnd, lpRect, bErase ? TRUE : FALSE);
    log("invalidateRect");
    return result != 0;
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
  int setClassLongPtr(int hwnd, int nIndex, int dwNewLong) {
    final result = SetClassLongPtr(hwnd, nIndex, dwNewLong);
    log("setClassLongPtr");
    return result;
  }

  /// Sets the window owner by setting the GWLP_HWNDPARENT window property.
  void setWindowOwner(int childHwnd, int ownerHwnd) {
    SetWindowLongPtr(childHwnd, GWLP_HWNDPARENT, ownerHwnd);
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
    int hwnd,
    int crKey,
    int bAlpha,
    int dwFlags,
  ) {
    final result = SetLayeredWindowAttributes(hwnd, crKey, bAlpha, dwFlags);
    log("setLayeredWindowAttributes");
    return result != 0;
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
      log("createWindowEx");
      calloc.free(className);
      calloc.free(windowName);
    }
  }

  /// Returns the handle to the module containing the specified function.
  /// [lpModuleName] is the name of the module to be retrieved.
  /// If [lpModuleName] is null, the handle of the calling module
  /// (current dart process) is returned.
  int getModuleHandle(String? lpModuleName) {
    if (lpModuleName == null) return GetModuleHandle(nullptr);

    final name = lpModuleName.toNativeUtf16();

    try {
      return GetModuleHandle(name);
    } finally {
      log("getModuleHandle");
      calloc.free(name);
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
    log("setWinEventHook");
    return result;
  }

  /// Removes an event hook function created by a previous call to [setWinEventHook].
  ///
  /// [hWinEventHook] is the handle to the event hook returned by the previous
  /// call to [setWinEventHook].
  ///
  /// Returns true if successful; otherwise, returns false.
  bool unhookWinEvent(int hWinEventHook) {
    final result = UnhookWinEvent(hWinEventHook);
    log("unhookWinEvent");
    return result != 0;
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
      return RegisterClass(ptr);
    } finally {
      log("registerClass");
      calloc.free(ptr);
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
  bool unregisterClass(String lpClassName, int hInstance) {
    final className = lpClassName.toNativeUtf16();
    try {
      return UnregisterClass(className, hInstance) != 0;
    } finally {
      log("unregisterClass");
      calloc.free(className);
    }
  }

  /// [GetClassName].
  ///
  /// Retrieves the window class name of the specified window.
  ///
  /// [hwnd] is the handle to the window whose class name is to be retrieved.
  ///
  /// Returns the window class name if successful; otherwise null.
  String? getClassName(int hwnd) {
    final maxCount = 256;
    final buffer = calloc<Uint16>(maxCount).cast<Utf16>();

    try {
      final result = GetClassName(hwnd, buffer, maxCount);

      if (result == 0) return null;

      return buffer.toDartString();
    } finally {
      log("getClassName");
      calloc.free(buffer);
    }
  }
}

final nativeWindowBridge = NativeWindowBridge.instance;
