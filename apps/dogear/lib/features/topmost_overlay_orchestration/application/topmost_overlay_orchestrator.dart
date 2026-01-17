import 'dart:ui' show Color;

import 'package:dogear/services/services.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/topmost_overlay_orchestrator_state.dart';

part 'topmost_overlay_orchestrator.g.dart';

@Riverpod(keepAlive: true)
class TopmostOverlayOrchestrator extends _$TopmostOverlayOrchestrator {
  static const String _kUnkown = "Unknown";

  @override
  TopmostOverlayOrchestratorState build() {
    nativeOverlayOrchestrator.init();

    ref.onDispose(() {
      dispose();
    });

    return TopmostOverlayOrchestratorState();
  }

  /// Adds or removes the foreground window from the list of tracked windows.
  /// If the window is already tracked, it will be removed.
  void autoAddRemoveForegroundWindow() {
    final result = nativeWindowBridge.toggleForegroundWindowTopmost();
    if (!result.isSuccess) return;

    if (result.shouldTopmost) {
      nativeOverlayOrchestrator.addTarget(result.hwnd);
      final overlayHwnd = nativeOverlayOrchestrator.getOverlayHwnd(result.hwnd);
      if (overlayHwnd == null) return;

      final processName = nativeWindowBridge.getProcessName(result.hwnd);

      final topmostWindow = TopmostWindow(
        hwnd: result.hwnd,
        overlayHwnd: overlayHwnd,
        title: processName != null ? p.withoutExtension(processName) : _kUnkown,
        processName: processName ?? _kUnkown,
      );

      _updateTopmostWindow(topmostWindow);
    } else {
      nativeOverlayOrchestrator.removeTarget(result.hwnd);
      _removeTopmostWindow(result.hwnd);
    }
  }

  /// Updates the overlay color.
  void updateOverlayColor(Color color) {
    nativeOverlayOrchestrator.updateOverlayColor(color);
  }

  void _updateTopmostWindow(TopmostWindow topmostWindow) {
    state = state.copyWith(
      topmostWindows: [...state.topmostWindows, topmostWindow],
    );
  }

  void _removeTopmostWindow(int hwnd) {
    state = state.copyWith(
      topmostWindows: [
        for (final window in state.topmostWindows)
          if (window.hwnd != hwnd) window,
      ],
    );
  }

  void dispose() {
    for (final window in state.topmostWindows) {
      nativeWindowBridge.setTopmost(window.hwnd, false);
    }
    nativeOverlayOrchestrator.dispose();
  }
}
