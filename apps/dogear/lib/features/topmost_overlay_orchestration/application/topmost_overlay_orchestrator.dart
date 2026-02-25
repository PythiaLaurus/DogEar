import 'dart:ui' show Color;

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32/win32.dart';

import '../../../services/platform/native_overlay_orchestrator.dart';
import '../../../services/platform/native_privilege_manager.dart';
import '../../../services/platform/native_window_bridge.dart';
import '../domain/topmost_overlay_orchestrator_state.dart';

part 'topmost_overlay_orchestrator.g.dart';

@Riverpod(keepAlive: true)
class TopmostOverlayOrchestrator extends _$TopmostOverlayOrchestrator {
  static const String _kUnkown = "Unknown";

  @override
  TopmostOverlayOrchestratorState build() {
    nativeOverlayOrchestrator.init();
    nativeOverlayOrchestrator.onWindowDestroyed = _handleNativeWindowDestroyed;

    ref.onDispose(() {
      dispose();
      nativeOverlayOrchestrator.onWindowDestroyed = null;
      nativeOverlayOrchestrator.dispose();
    });

    return TopmostOverlayOrchestratorState();
  }

  void autoAddRemoveUnderCursorWindow() {
    final curForeWindowHwnd = nativeWindowBridge.getForegroundWindowHandle();

    final result = nativeWindowBridge.toggleUnderCursorWindowTopmost();
    if (!result.isSuccess) {
      nativePrivilegeManager.requestAdminPrivileges();
      return;
    }

    if (result.shouldTopmost) {
      final overlayHwnd = nativeOverlayOrchestrator.addTarget(result.hwnd);
      if (overlayHwnd.isNull) return;

      final processName = nativeWindowBridge.getProcessName(result.hwnd);

      final topmostWindow = TopmostWindow(
        hwnd: result.hwnd,
        overlayHwnd: overlayHwnd,
        title: processName != null ? p.withoutExtension(processName) : _kUnkown,
        processName: processName ?? _kUnkown,
      );

      _addToState(topmostWindow);
    } else {
      nativeOverlayOrchestrator.removeTarget(result.hwnd);
      _removefromState(result.hwnd);

      if (curForeWindowHwnd.isNotNull) {
        nativeWindowBridge.setForegroundWindow(curForeWindowHwnd);
      }
    }
  }

  /// Updates the overlay color.
  void updateOverlayColor(Color color) {
    nativeOverlayOrchestrator.updateOverlayColor(color);
  }

  void _addToState(TopmostWindow topmostWindow) {
    state = state.copyWith(
      topmostWindows: [...state.topmostWindows, topmostWindow],
    );
  }

  void _handleNativeWindowDestroyed(HWND hwnd) {
    _removefromState(hwnd);
  }

  void _removefromState(HWND hwnd) {
    final newList = List<TopmostWindow>.from(state.topmostWindows)
      ..removeWhere((w) => w.hwnd == hwnd);
    state = state.copyWith(topmostWindows: newList);
  }

  void dispose() {
    for (final window in state.topmostWindows) {
      nativeWindowBridge.setTopmost(window.hwnd, false);
    }
  }
}
