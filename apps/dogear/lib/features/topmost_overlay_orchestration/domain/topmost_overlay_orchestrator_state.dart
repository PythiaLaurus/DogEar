import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:win32/win32.dart' show HWND;

part 'topmost_overlay_orchestrator_state.freezed.dart';

@freezed
abstract class TopmostOverlayOrchestratorState
    with _$TopmostOverlayOrchestratorState {
  const factory TopmostOverlayOrchestratorState({
    @Default(<TopmostWindow>[]) List<TopmostWindow> topmostWindows,
  }) = _TopmostOverlayOrchestratorState;
}

@freezed
abstract class TopmostWindow with _$TopmostWindow {
  const factory TopmostWindow({
    required HWND hwnd,
    required HWND overlayHwnd,
    required String title,
    required String processName,
    int? dogEarColorARGB,
  }) = _TopmostWindow;
}
