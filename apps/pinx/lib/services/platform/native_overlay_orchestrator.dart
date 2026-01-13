import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'native_window_bridge.dart';

class NativeOverlayOrchestrator {
  NativeOverlayOrchestrator._();
  static final instance = NativeOverlayOrchestrator._();

  // States
  bool _isClassRegistered = false;
  static const String kClassName = "PinX_Triangle_Overlay";

  void init() {
    if (_isClassRegistered) return;

    // Register Window Class
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

  static int _staticWndProc(int hwnd, int msg, int wParam, int lParam) {
    return DefWindowProc(hwnd, msg, wParam, lParam);
  }
}

final nativeOverlayOrchestrator = NativeOverlayOrchestrator.instance;
