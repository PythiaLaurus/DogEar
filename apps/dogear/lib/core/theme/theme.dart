import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/storage.dart';

export 'theme_extension.dart';

part 'theme.g.dart';

/// Text Styles.
class AppTextStyles {
  final Ref ref;
  late final AppColors colors;
  static const String _fontFamily = "NotoSans";
  static const String _fontFamilyFallback = "NotoSansSC";
  AppTextStyles(this.ref) {
    colors = ref.watch(appColorsProvider);
  }

  TextStyle get body {
    return TextStyle(
      fontSize: 14,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
      color: colors.textPrimary,
      fontFamily: _fontFamily,
      fontFamilyFallback: [_fontFamilyFallback],
    );
  }

  // Body Large Text
  TextStyle get bodyLarge {
    return body.copyWith(fontSize: 16);
  }

  TextStyle get bodyExtraLarge {
    return body.copyWith(fontSize: 18);
  }

  // Body Small Text
  TextStyle get bodySmall {
    return body.copyWith(fontSize: 12);
  }

  TextStyle get bodyExtraSmall {
    return body.copyWith(fontSize: 10);
  }

  // Title && Larger Text
  TextStyle get title {
    return body.copyWith(fontSize: 20);
  }

  TextStyle get titleLarge {
    return body.copyWith(fontSize: 24);
  }

  // Headline && Larger Text
  TextStyle get headline {
    return body.copyWith(fontSize: 32);
  }

  TextStyle get headlineLarge {
    return body.copyWith(fontSize: 48);
  }
}

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

/// Current ThemeMode.<br>
/// This is a custom provider holding [Brightness] by listening to [WidgetsBindingObserver].<br>
/// Use [toFollowSystem] or [setPlatformBrightness] to set to follow system or change the theme mode.<br>
@Riverpod(keepAlive: true)
class PlatformBrightness extends _$PlatformBrightness
    with WidgetsBindingObserver {
  static const _kThemeMode = "settings.themeMode";

  bool _isFollowSystem = true;
  bool get isFollowSystem => _isFollowSystem;

  ThemeMode get themeMode =>
      _isFollowSystem ? ThemeMode.system : ThemeMode.values.byName(state.name);

  @override
  didChangePlatformBrightness() {
    if (!_isFollowSystem) return;
    _followSystemForOnce();
  }

  @override
  Brightness build() {
    _init();
    return Brightness.light;
  }

  /// Make [PlatformBrightness] follow system.
  /// Use [setPlatformBrightness] with argument [Brightness.light] or [Brightness.dark]
  /// to make [PlatformBrightness] not follow system.
  void toFollowSystem() {
    if (_isFollowSystem) return;
    _isFollowSystem = true;

    _followSystemForOnce();
    WidgetsBinding.instance.addObserver(this);
    appStorage.setString(_kThemeMode, ThemeMode.system.name);
  }

  /// Set PlatformBrightness. Only works when not following system.
  void setPlatformBrightness(Brightness brightness) {
    if (!_isFollowSystem && state == brightness) return;

    if (_isFollowSystem) {
      WidgetsBinding.instance.removeObserver(this);
      _isFollowSystem = false;
    }

    _updatePlatformBrightness(brightness);
  }

  /// Set [PlatformBrightness] by [ThemeMode].
  void setByThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        setPlatformBrightness(Brightness.light);
        break;
      case ThemeMode.dark:
        setPlatformBrightness(Brightness.dark);
        break;
      case ThemeMode.system:
        toFollowSystem();
        break;
    }
  }

  /// Toggle theme mode, only works when [PlatformBrightness] is not set to follow system
  void toggleThemeMode() {
    if (_isFollowSystem) return;

    state == Brightness.light
        ? _updatePlatformBrightness(Brightness.dark)
        : _updatePlatformBrightness(Brightness.light);
  }

  /// To follow system brightness once.
  /// This will not save the theme mode in storage.
  void _followSystemForOnce() {
    final sysBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    state = sysBrightness;
  }

  Future<void> _init() async {
    final defaultThemeMode = await appStorage.getString(_kThemeMode);
    if (defaultThemeMode == null) return;

    late final ThemeMode themeMode;
    try {
      themeMode = ThemeMode.values.byName(defaultThemeMode);
    } catch (_) {
      appStorage.setString(_kThemeMode, ThemeMode.system.name);
      themeMode = ThemeMode.system;
    }

    if (themeMode == ThemeMode.system) {
      _isFollowSystem = true;
      _followSystemForOnce();

      WidgetsBinding.instance.addObserver(this);
    } else {
      _isFollowSystem = false;
      state = themeMode == ThemeMode.light ? Brightness.light : Brightness.dark;
    }

    ref.onDispose(() {
      if (_isFollowSystem) {
        WidgetsBinding.instance.removeObserver(this);
      }
    });
  }

  void _updatePlatformBrightness(Brightness brightness) {
    if (brightness == state) return;

    state = brightness;
    appStorage.setString(_kThemeMode, brightness.name);
  }
}

@riverpod
AppColors appColors(Ref ref) {
  final platformBrightness = ref.watch(platformBrightnessProvider);
  return platformBrightness == Brightness.dark ? _DarkColors() : _LightColors();
}

@riverpod
AppTextStyles appTextStyles(Ref ref) {
  return AppTextStyles(ref);
}
