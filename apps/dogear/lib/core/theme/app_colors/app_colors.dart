import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../platform_brightness/platform_brightness.dart';

part 'app_colors.g.dart';

// Light theme colors
class _LightColors extends AppColors {
  @override
  Color get primary => const Color.fromRGBO(243, 243, 243, 1);
  @override
  Color get background => const Color(0xFFFFFFFF);
  @override
  Color get onHover => const Color.fromRGBO(237, 237, 237, 1);
  @override
  Color get onFocus => const Color.fromRGBO(234, 234, 234, 1);
  @override
  Color get widgetDisabled => const Color.fromRGBO(228, 228, 228, 1);
  @override
  Color get textPrimary => const Color.fromRGBO(26, 26, 26, 1);
  @override
  Color get textDisabled => Colors.grey;
}

// Dark theme colors
class _DarkColors extends AppColors {
  @override
  Color get primary => const Color(0xFF121212);
  @override
  Color get background => const Color(0xFF1F1F1F);
  @override
  Color get onHover => const Color(0xFF333333);
  @override
  Color get onFocus => const Color(0xFF444444);
  @override
  Color get widgetDisabled => const Color(0xFF555555);
  @override
  Color get textPrimary => Colors.white;
  @override
  Color get textDisabled => const Color(0xFFAAAAAA);
}

// Colors base
abstract class AppColors {
  Color get primary;
  Color get background;
  Color get onHover;
  Color get onFocus;
  Color get widgetDisabled;
  Color get textPrimary;
  Color get textDisabled;

  WidgetStateProperty<Color?> stateResolved({
    Color? hoverColor,
    Color? pressedColor,
    required Color normalColor,
  }) {
    return WidgetStateProperty.resolveWith((state) {
      if (pressedColor != null && state.contains(WidgetState.pressed)) {
        return pressedColor;
      }
      if (hoverColor != null && state.contains(WidgetState.hovered)) {
        return hoverColor;
      }
      return normalColor;
    });
  }
}

@riverpod
AppColors appColors(Ref ref) {
  final platformBrightness = ref.watch(platformBrightnessProvider);
  return platformBrightness == Brightness.dark ? _DarkColors() : _LightColors();
}
