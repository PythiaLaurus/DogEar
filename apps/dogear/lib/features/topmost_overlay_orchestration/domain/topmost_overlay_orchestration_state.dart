import 'package:freezed_annotation/freezed_annotation.dart';

import 'topmost_window.dart';

export 'topmost_window.dart';

part 'topmost_overlay_orchestration_state.freezed.dart';

@freezed
abstract class TopmostOverlayOrchestrationState
    with _$TopmostOverlayOrchestrationState {
  const factory TopmostOverlayOrchestrationState({
    @Default([]) List<TopmostWindow> topmostWindows,
  }) = _TopmostOverlayOrchestrationState;
}
