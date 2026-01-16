import 'package:freezed_annotation/freezed_annotation.dart';

part 'topmost_window.freezed.dart';

@freezed
abstract class TopmostWindow with _$TopmostWindow {
  const factory TopmostWindow({
    required int hwnd,
    required int overlayHwnd,
    required String title,
    required String processName,
    int? dogEarColorARGB,
  }) = _TopmostWindow;
}
