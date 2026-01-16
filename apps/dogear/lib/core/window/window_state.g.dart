// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WindowState)
final windowStateProvider = WindowStateProvider._();

final class WindowStateProvider
    extends $NotifierProvider<WindowState, WindowStateStatus> {
  WindowStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowStateHash();

  @$internal
  @override
  WindowState create() => WindowState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindowStateStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindowStateStatus>(value),
    );
  }
}

String _$windowStateHash() => r'6f052cd8eaca91d84d1b4d206092787729039295';

abstract class _$WindowState extends $Notifier<WindowStateStatus> {
  WindowStateStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WindowStateStatus, WindowStateStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WindowStateStatus, WindowStateStatus>,
              WindowStateStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
