import 'package:freezed_annotation/freezed_annotation.dart';

import 'topmost_window.dart';

export 'topmost_window.dart';

part 'topmost_overlay_orchestrator_state.freezed.dart';

@freezed
abstract class TopmostOverlayOrchestratorState
    with _$TopmostOverlayOrchestratorState {
  const factory TopmostOverlayOrchestratorState({
    @Default(<TopmostWindow>[]) List<TopmostWindow> topmostWindows,
  }) = _TopmostOverlayOrchestratorState;
}
