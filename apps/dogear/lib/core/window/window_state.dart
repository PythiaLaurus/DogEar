import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';

import 'package:win32/win32.dart';

part 'window_state.g.dart';

enum WindowStateStatus { normal, maximized, fullScreen, docked }

@Riverpod(keepAlive: true)
class WindowState extends _$WindowState
    with WindowListener
    implements Finalizable {
  // Internal window state cache
  bool _isDocked = false;
  int? _hwnd;

  // Native Resources
  late final Pointer<RECT> _rectPtr;
  late final Pointer<MONITORINFO> _monitorInfoPtr;

  static final _finalizer = NativeFinalizer(calloc.nativeFree);

  @override
  WindowStateStatus build() {
    // Initialize native resources
    _initNativeResources();

    // Initialize window state
    _initWindowState();
    return WindowStateStatus.normal;
  }

  bool isDocked() {
    if (_hwnd == null || _hwnd == 0) {
      _hwnd = GetActiveWindow();
    }
    final hwnd = _hwnd!;

    if (GetWindowRect(hwnd, _rectPtr) == 0) return false;

    final monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    if (GetMonitorInfo(monitor, _monitorInfoPtr) == 0) return false;

    final r = _rectPtr.ref;
    final m = _monitorInfoPtr.ref.rcWork;

    final leftDist = r.left - m.left;
    final topDist = r.top - m.top;
    final rightDist = m.right - r.right;
    final bottomDist = m.bottom - r.bottom;

    int dockedSideCount = 0;
    if (leftDist == 0) dockedSideCount++;
    if (topDist == 0) dockedSideCount++;
    if (rightDist == 0) dockedSideCount++;
    if (bottomDist == 0) dockedSideCount++;

    return dockedSideCount == 2 || dockedSideCount == 3;
  }

  void _initNativeResources() {
    _rectPtr = calloc<RECT>();
    _monitorInfoPtr = calloc<MONITORINFO>();
    _monitorInfoPtr.ref.cbSize = sizeOf<MONITORINFO>();

    _finalizer.attach(this, _rectPtr.cast(), detach: this);
    _finalizer.attach(this, _monitorInfoPtr.cast(), detach: this);

    ref.onDispose(() {
      free(_rectPtr);
      free(_monitorInfoPtr);
    });
  }

  Future<void> _initWindowState() async {
    // Check initial state
    bool isMaximized = await windowManager.isMaximized();
    bool isFullScreen = await windowManager.isFullScreen();

    state = isFullScreen
        ? WindowStateStatus.fullScreen
        : isMaximized
        ? WindowStateStatus.maximized
        : WindowStateStatus.normal;

    windowManager.addListener(this);
    ref.onDispose(() => windowManager.removeListener(this));
  }

  @override
  void onWindowMaximize() {
    state = WindowStateStatus.maximized;
  }

  @override
  void onWindowUnmaximize() {
    state = WindowStateStatus.normal;
  }

  @override
  void onWindowMoved() {
    _isDocked = isDocked();
    if (_isDocked) {
      state = WindowStateStatus.docked;
    }
  }

  @override
  void onWindowResize() {
    final tempIsDocked = isDocked();
    if (tempIsDocked != _isDocked) {
      _isDocked = tempIsDocked;
      if (_isDocked) {
        state = WindowStateStatus.docked;
      } else {
        state = WindowStateStatus.normal;
      }
    }
  }
}
