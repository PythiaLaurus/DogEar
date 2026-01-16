// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current ThemeMode.<br>
/// This is a custom provider holding [Brightness] by listening to [WidgetsBindingObserver].<br>
/// Use [toFollowSystem] or [setPlatformBrightness] to set to follow system or change the theme mode.<br>

@ProviderFor(PlatformBrightness)
final platformBrightnessProvider = PlatformBrightnessProvider._();

/// Current ThemeMode.<br>
/// This is a custom provider holding [Brightness] by listening to [WidgetsBindingObserver].<br>
/// Use [toFollowSystem] or [setPlatformBrightness] to set to follow system or change the theme mode.<br>
final class PlatformBrightnessProvider
    extends $NotifierProvider<PlatformBrightness, Brightness> {
  /// Current ThemeMode.<br>
  /// This is a custom provider holding [Brightness] by listening to [WidgetsBindingObserver].<br>
  /// Use [toFollowSystem] or [setPlatformBrightness] to set to follow system or change the theme mode.<br>
  PlatformBrightnessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformBrightnessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformBrightnessHash();

  @$internal
  @override
  PlatformBrightness create() => PlatformBrightness();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Brightness value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Brightness>(value),
    );
  }
}

String _$platformBrightnessHash() =>
    r'cf48e63d65ca77001c624cc0f07265adff4fa07e';

/// Current ThemeMode.<br>
/// This is a custom provider holding [Brightness] by listening to [WidgetsBindingObserver].<br>
/// Use [toFollowSystem] or [setPlatformBrightness] to set to follow system or change the theme mode.<br>

abstract class _$PlatformBrightness extends $Notifier<Brightness> {
  Brightness build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Brightness, Brightness>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Brightness, Brightness>,
              Brightness,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(appColors)
final appColorsProvider = AppColorsProvider._();

final class AppColorsProvider
    extends $FunctionalProvider<AppColors, AppColors, AppColors>
    with $Provider<AppColors> {
  AppColorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appColorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appColorsHash();

  @$internal
  @override
  $ProviderElement<AppColors> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppColors create(Ref ref) {
    return appColors(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppColors value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppColors>(value),
    );
  }
}

String _$appColorsHash() => r'96b34419b7a39897a2ac8d38802fe5fb3a5d1dc6';

@ProviderFor(appTextStyles)
final appTextStylesProvider = AppTextStylesProvider._();

final class AppTextStylesProvider
    extends $FunctionalProvider<AppTextStyles, AppTextStyles, AppTextStyles>
    with $Provider<AppTextStyles> {
  AppTextStylesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appTextStylesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appTextStylesHash();

  @$internal
  @override
  $ProviderElement<AppTextStyles> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppTextStyles create(Ref ref) {
    return appTextStyles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppTextStyles value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppTextStyles>(value),
    );
  }
}

String _$appTextStylesHash() => r'6b560791bef2515f781387135a40c19cedc3a3f4';
