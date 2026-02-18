import 'dart:ffi';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'native_window_bridge.dart';
import 'native_extension.dart';

class NativeOverlayOrchestrator {
  NativeOverlayOrchestrator._();
  static final instance = NativeOverlayOrchestrator._();

  // Configurations
  // Class name
  static const String _kClassNamePrefix = "RobotMachete_DogEar_Overlay_";
  static final String kClassName =
      "$_kClassNamePrefix${DateTime.now().millisecondsSinceEpoch}";
  // Default overlay size (side length of triangle)
  static const defaultOverlaySize = 20;
  // Default overlay shape (a triangle)
  static const defaultOverlayPoints = [
    math.Point(0, 0),
    math.Point(defaultOverlaySize, 0),
    math.Point(defaultOverlaySize, defaultOverlaySize),
  ];

  /// Is [init] function called.
  bool get isInitialized => _isClassRegistered;

  // States
  final Map<int, int> _targetToOverlay = {};
  final Map<int, int> _overlayToTarget = {};
  bool _isClassRegistered = false;
  int _hookHandle = 0;
  NativeCallable<WinEventProc>? _hookCallback;
  int _brushHandle = 0;
  int _brushAlpha = 255;

  /// This will be called after a target window is destroyed (closed).
  ///
  /// [targetHwnd] is already destroyed when this function is called,
  /// so it can't be used to implement any native logic.
  void Function(int targetHwnd)? onWindowDestroyed;

  int? getOverlayHwnd(int targetHwnd) => _targetToOverlay[targetHwnd];
  int? getTargetHwnd(int overlayHwnd) => _overlayToTarget[overlayHwnd];

  /// Adds a new target window to be tracked.
  ///
  /// Returns the overlay window handle if successful, or null if failed.
  int? addTarget(int targetHwnd) {
    if (_shouldIgnoreWindow(targetHwnd)) return null;

    if (!_isClassRegistered) {
      init();
    }

    final isTargetsEmpty = _targetToOverlay.isEmpty;
    if (isTargetsEmpty) {
      _startHook();
    }

    final hInst = nativeWindowBridge.getModuleHandle(null);
    // Creates the native overlay window with specific extended styles:
    // - WS_EX_TOOLWINDOW: Hides from taskbar and Alt+Tab.
    // - WS_EX_TOPMOST: Keeps the window on top of all others.
    // - WS_EX_NOACTIVATE: Prevents taking focus when shown or moved.
    // - WS_EX_LAYERED: Required for transparency and custom shapes.
    // - WS_EX_TRANSPARENT: Enables mouse click-through.
    final overlayHwnd = nativeWindowBridge.createWindowEx(
      WS_EX_TOOLWINDOW |
          WS_EX_TOPMOST |
          WS_EX_NOACTIVATE |
          WS_EX_LAYERED |
          WS_EX_TRANSPARENT,
      kClassName,
      '',
      WS_POPUP | WS_VISIBLE,
      0,
      0,
      20,
      20,
      0,
      0,
      hInst,
      nullptr,
    );
    if (overlayHwnd == 0) return null;

    // Set the window's opacity to [_brushAlpha] but ignoring the color parameter.
    nativeWindowBridge.setLayeredWindowAttributes(
      overlayHwnd,
      0,
      _brushAlpha,
      LWA_ALPHA,
    );

    // If this is the first tracked window, set the class-wide background brush.
    // GCLP_HBRBACKGROUND (-10) replaces the background brush associated with the class.
    // This ensures all subsequent overlay windows inherit the same background color.
    if (isTargetsEmpty && _brushHandle != 0) {
      nativeWindowBridge.setClassLongPtr(
        overlayHwnd,
        GCLP_HBRBACKGROUND,
        _brushHandle,
      );
    }

    _targetToOverlay[targetHwnd] = overlayHwnd;
    _overlayToTarget[overlayHwnd] = targetHwnd;

    // Sets region with a new region handle, since the ownership of the handle
    // will be transferred to the system, so it can't be reused.
    nativeWindowBridge.setWindowRgn(
      overlayHwnd,
      nativeWindowBridge.createPolygonRgn(defaultOverlayPoints),
      true,
    );

    _updateOverlayPosition(targetHwnd, overlayHwnd);

    // Set owner
    // This makes windows automatically manages the lifetime of the overlay.
    nativeWindowBridge.setWindowOwner(overlayHwnd, targetHwnd);

    // Bring target to foreground
    nativeWindowBridge.setForegroundWindow(targetHwnd);

    return overlayHwnd;
  }

  /// Ignore windows that are already tracked, created by ourself, and [ToolWindow].
  bool _shouldIgnoreWindow(int hwnd) {
    if (_targetToOverlay.containsKey(hwnd) ||
        _overlayToTarget.containsKey(hwnd)) {
      return true;
    }
    final className = nativeWindowBridge.getClassName(hwnd);
    if (className == null) return true;
    if (className.startsWith(_kClassNamePrefix)) {
      return true;
    }

    int style = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    if ((style & WS_EX_TOOLWINDOW) != 0) return true;

    if (!nativeWindowBridge.isWindowVisible(hwnd)) return true;

    return false;
  }

  /// Removes a tracked target window.
  void removeTarget(int targetHwnd) {
    final overlayHwnd = _targetToOverlay.remove(targetHwnd);
    if (overlayHwnd == null) return;

    _overlayToTarget.remove(overlayHwnd);
    nativeWindowBridge.destroyWindow(overlayHwnd);

    if (_targetToOverlay.isEmpty) {
      _stopHook();
    }
  }

  /// Updates overlay shape.
  void updateOverlayShapeAndAlignment() {
    // TODO: Implement updateOverlayShapeAndAlignment
  }

  /// Updates overlay color.
  void updateOverlayColor(Color color) {
    final r = (color.r * 255).toInt();
    final g = (color.g * 255).toInt();
    final b = (color.b * 255).toInt();
    final a = (color.a * 255).toInt();

    // Windows uses BGR format
    final colorRef = r | (g << 8) | (b << 16);

    // Create new brush first
    final newBrush = CreateSolidBrush(colorRef);

    // Set new brush to class
    if (_targetToOverlay.isNotEmpty) {
      final hwnd = _targetToOverlay.values.first;
      // GCLP_HBRBACKGROUND is -10
      nativeWindowBridge.setClassLongPtr(hwnd, GCLP_HBRBACKGROUND, newBrush);

      if (_brushAlpha != a) {
        for (final h in _targetToOverlay.values) {
          nativeWindowBridge.setLayeredWindowAttributes(h, 0, a, LWA_ALPHA);
        }
      }

      // Force redraw
      for (final h in _targetToOverlay.values) {
        nativeWindowBridge.invalidateRect(h, nullptr, true);
      }
    }

    // Delete old brush
    if (_brushHandle != 0) {
      DeleteObject(_brushHandle);
    }

    _brushHandle = newBrush;
    _brushAlpha = a;
  }

  /// Register Window Class.
  /// Must be called to be able to create overlay windows.
  ///
  /// Can be called in the first, or it will be called automatically in
  /// [addTarget]. It will only be called once. If it is called manually,
  /// it will not be called in [addTarget] again.
  void init() {
    if (_isClassRegistered) return;

    final classNamePtr = kClassName.toNativeUtf16();
    final hInst = nativeWindowBridge.getModuleHandle(null);

    final wndClass = calloc<WNDCLASS>();

    try {
      wndClass.ref.style = CS_HREDRAW | CS_VREDRAW;
      wndClass.ref.lpfnWndProc = DefWindowProcWPtr;
      wndClass.ref.cbClsExtra = 0;
      wndClass.ref.cbWndExtra = 0;
      wndClass.ref.hInstance = hInst;
      wndClass.ref.hIcon = 0;
      wndClass.ref.hCursor = LoadCursor(0, IDC_ARROW);
      // By set [hbrBackground] to 0, erasing step is invisible to the user
      // when calling [invalidateRect]
      wndClass.ref.hbrBackground = 0;
      wndClass.ref.lpszMenuName = nullptr;
      wndClass.ref.lpszClassName = classNamePtr;

      if (nativeWindowBridge.registerClass(wndClass.ref) != 0) {
        _isClassRegistered = true;
      }
    } finally {
      free(wndClass);
      free(classNamePtr);
    }
  }

  /// Disposes resources.
  void dispose() {
    if (_hookHandle != 0) {
      _stopHook();
    }

    for (final h in _targetToOverlay.values) {
      nativeWindowBridge.destroyWindow(h);
    }
    _targetToOverlay.clear();
    _overlayToTarget.clear();

    if (_brushHandle != 0) {
      DeleteObject(_brushHandle);
      _brushHandle = 0;
    }

    if (_isClassRegistered) {
      nativeWindowBridge.unregisterClass(kClassName, 0);
      _isClassRegistered = false;
    }
  }

  void _startHook() {
    if (_hookHandle != 0) return;

    _hookCallback ??= NativeCallable<WinEventProc>.listener(
      _staticHookCallback,
    );
    final funcPtr = _hookCallback!.nativeFunction;

    if (_hookHandle == 0) {
      _hookHandle = nativeWindowBridge.setWinEventHook(
        EVENT_OBJECT_DESTROY,
        EVENT_OBJECT_LOCATIONCHANGE,
        0,
        funcPtr,
        0,
        0,
        WINEVENT_OUTOFCONTEXT,
      );
    }
  }

  void _stopHook() {
    if (_hookHandle == 0) return;

    nativeWindowBridge.unhookWinEvent(_hookHandle);
    _hookHandle = 0;

    _hookCallback?.close();
    _hookCallback = null;
  }

  /// This callback must be static because it is passed as a raw function pointer
  /// to the Win32 API (via [NativeCallable] or [Pointer.fromFunction]).
  ///
  /// Note: Dart's Linter cannot detect the external lifecycle of this callback.
  /// It serves as a bridge between the static C-world and our instance-world.
  /// We use the [instance] singleton to redirect the event back to instance
  /// methods, allowing us to access internal state like [_targetToOverlay].
  static void _staticHookCallback(
    int hWinEventHook,
    int event,
    int hwnd,
    int idObject,
    int idChild,
    int dwEventThread,
    int dwmsEventTime,
  ) {
    // OBJID_WINDOW (0) is the window itself (not a child like a button).
    if (idObject != OBJID_WINDOW) return;

    instance._handleWindowEnvent(event, hwnd);
  }

  void _handleWindowEnvent(int event, int targetHwnd) {
    final overlayHwnd = _targetToOverlay[targetHwnd];
    if (overlayHwnd == null) return;

    switch (event) {
      case EVENT_OBJECT_DESTROY:
        // Remove target when the target window is destroyed
        removeTarget(targetHwnd);
        onWindowDestroyed?.call(targetHwnd);
        break;

      case EVENT_OBJECT_HIDE:
        // Hide overlay when target is hidden
        nativeWindowBridge.showWindow(overlayHwnd, SW_HIDE);
        break;

      case EVENT_OBJECT_SHOW:
        // Show overlay when target is shown
        // Only show overlay when target window is visible
        if (nativeWindowBridge.isWindowVisible(targetHwnd)) {
          nativeWindowBridge.showWindow(overlayHwnd, SW_SHOWNOACTIVATE);
          // Update Overlay Position, just in case
          _updateOverlayPosition(targetHwnd, overlayHwnd);
        }
        break;

      case EVENT_OBJECT_LOCATIONCHANGE:
        _updateOverlayPosition(targetHwnd, overlayHwnd);
        break;
    }
  }

  void _updateOverlayPosition(int targetHwnd, int overlayHwnd) {
    final rect = nativeWindowBridge.getWindowRect(targetHwnd);
    if (rect == null) return;

    const size = defaultOverlaySize;
    final x = rect.left + rect.width - size;
    final y = rect.top;

    nativeWindowBridge.setWindowPos(
      overlayHwnd,
      HWND_TOPMOST,
      x,
      y,
      size,
      size,
      SWP_NOACTIVATE | SWP_NOOWNERZORDER,
    );
  }
}

final nativeOverlayOrchestrator = NativeOverlayOrchestrator.instance;
