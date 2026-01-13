// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserPreferences)
final userPreferencesProvider = UserPreferencesProvider._();

final class UserPreferencesProvider
    extends $AsyncNotifierProvider<UserPreferences, UserPreferencesModel> {
  UserPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userPreferencesHash();

  @$internal
  @override
  UserPreferences create() => UserPreferences();
}

String _$userPreferencesHash() => r'a04578a0c14f97d6844f34a7462e74892e29bb5c';

abstract class _$UserPreferences extends $AsyncNotifier<UserPreferencesModel> {
  FutureOr<UserPreferencesModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<UserPreferencesModel>, UserPreferencesModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<UserPreferencesModel>,
                UserPreferencesModel
              >,
              AsyncValue<UserPreferencesModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
