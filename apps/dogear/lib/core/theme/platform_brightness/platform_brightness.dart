import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../storage/storage.dart';

part "platform_brightness.g.dart";

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

