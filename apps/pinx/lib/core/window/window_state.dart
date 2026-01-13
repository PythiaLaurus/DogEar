import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';

import 'package:win32/win32.dart';

part 'window_state.g.dart';

enum WindowStateStatus { normal, maximized, fullScreen, docked }

@Riverpod(keepAlive: true)
class WindowState extends _$WindowState with WindowListener {
  bool _isDocked = false;
  int? _hwnd;

  @override
  WindowStateStatus build() {
    _init();
    return WindowStateStatus.normal;
  }

  bool isDocked() {
    if (_hwnd == null || _hwnd == 0) {
      _hwnd = GetActiveWindow();
    }
    final hwnd = _hwnd!;

    final rect = calloc<RECT>();
    GetWindowRect(hwnd, rect);

    // Window position
    final left = rect.ref.left;
    final top = rect.ref.top;
    final right = rect.ref.right;
    final bottom = rect.ref.bottom;

    calloc.free(rect);

    final monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    final monitorInfo = calloc<MONITORINFO>();
    monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();
    GetMonitorInfo(monitor, monitorInfo);

    final m = monitorInfo.ref.rcWork;
    calloc.free(monitorInfo);

    final leftDist = left - m.left;
    final topDist = top - m.top;
    final rightDist = m.right - right;
    final bottomDist = m.bottom - bottom;

    int dockedSideCount = 0;
    if (leftDist == 0) dockedSideCount++;
    if (topDist == 0) dockedSideCount++;
    if (rightDist == 0) dockedSideCount++;
    if (bottomDist == 0) dockedSideCount++;

    return dockedSideCount == 2 || dockedSideCount == 3;
  }

  Future<void> _init() async {
    // Check initial state
    bool isMaximized = await windowManager.isMaximized();
    bool isFullScreen = await windowManager.isFullScreen();

    final savedState = isFullScreen
        ? WindowStateStatus.fullScreen
        : isMaximized
        ? WindowStateStatus.maximized
        : WindowStateStatus.normal;

    state = savedState;

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

  // @override
  // void onWindowResized() {
  //   _isDocked = isDocked();
  //   if (!_isDocked) {
  //     state = WindowStateStatus.normal;
  //   }
  // }
}
