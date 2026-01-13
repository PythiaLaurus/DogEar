import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'native_window_bridge.dart';

class NativeOverlayOrchestrator {
  NativeOverlayOrchestrator._();
  static final instance = NativeOverlayOrchestrator._();

  static const String kClassName = "PinX_Triangle_Overlay";

  /// Is [init] function called.
  bool get isInitialized => _isClassRegistered;

  // States
  final Map<int, int> _targetToOverlay = {};
  bool _isClassRegistered = false;
  int _hookHandle = 0;
  NativeCallable<WinEventProc>? _hookCallback;

  void addTarget(int targetHwnd) {}

  /// Register Window Class.
  /// Must be called in the first time.
  void init() {
    if (_isClassRegistered) return;

    final wndClass = calloc<WNDCLASS>();
    final classNamePtr = kClassName.toNativeUtf16();

    try {
      wndClass.ref.style = CS_HREDRAW | CS_VREDRAW;
      wndClass.ref.lpfnWndProc = Pointer.fromFunction<WNDPROC>(
        _staticWndProc,
        0,
      );
      wndClass.ref.cbClsExtra = 0;
      wndClass.ref.cbWndExtra = 0;
      wndClass.ref.hInstance = nativeWindowBridge.getModuleHandle(null);
      wndClass.ref.hIcon = 0;
      wndClass.ref.hCursor = LoadCursor(0, IDC_ARROW);
      wndClass.ref.hbrBackground = 0;
      wndClass.ref.lpszMenuName = nullptr;
      wndClass.ref.lpszClassName = classNamePtr;

      nativeWindowBridge.registerClass(wndClass.ref);
      _isClassRegistered = true;
    } finally {
      calloc.free(wndClass);
      calloc.free(classNamePtr);
    }
  }

  void _startHook() {
    if (_hookHandle != 0) return;

    _hookCallback = NativeCallable<WinEventProc>.listener(_staticHookCallback);

    _hookHandle = nativeWindowBridge.setWinEventHook(
      EVENT_OBJECT_LOCATIONCHANGE,
      EVENT_OBJECT_LOCATIONCHANGE,
      0,
      _hookCallback!.nativeFunction,
      0,
      0,
      WINEVENT_OUTOFCONTEXT,
    );
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
    // [event] is always EVENT_OBJECT_LOCATIONCHANGE based on our settings.
    instance._handleLocationChange(event, hwnd, idObject);
  }

  void _handleLocationChange(int event, int hwnd, int idObject) {
    // OBJID_WINDOW = 0
    if (idObject != OBJID_WINDOW) return;

    // Only care about pinned windows
    final overlayHwnd = _targetToOverlay[hwnd];
    if (overlayHwnd != null) {
      _updateOverlayPosition(hwnd, overlayHwnd);
    }
  }

  void _updateOverlayPosition(int targetHwnd, int overlayHwnd) {
    final rect = nativeWindowBridge.getWindowRect(targetHwnd);
    if (rect == null) return;

    const size = 20;
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

  static int _staticWndProc(int hwnd, int msg, int wParam, int lParam) {
    return DefWindowProc(hwnd, msg, wParam, lParam);
  }
}

final nativeOverlayOrchestrator = NativeOverlayOrchestrator.instance;
