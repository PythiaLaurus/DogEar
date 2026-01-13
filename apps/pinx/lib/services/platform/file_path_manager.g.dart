// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_path_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FilePathManager)
final filePathManagerProvider = FilePathManagerFamily._();

final class FilePathManagerProvider
    extends $NotifierProvider<FilePathManager, String> {
  FilePathManagerProvider._({
    required FilePathManagerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filePathManagerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filePathManagerHash();

  @override
  String toString() {
    return r'filePathManagerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FilePathManager create() => FilePathManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilePathManagerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filePathManagerHash() => r'aad9bcd0812f6a8eca11ad08488609e55a7d8ed6';

final class FilePathManagerFamily extends $Family
    with $ClassFamilyOverride<FilePathManager, String, String, String, String> {
  FilePathManagerFamily._()
    : super(
        retry: null,
        name: r'filePathManagerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  FilePathManagerProvider call({
    String key = DirectoryStorageKeys.defaultStorage,
  }) => FilePathManagerProvider._(argument: key, from: this);

  @override
  String toString() => r'filePathManagerProvider';
}

abstract class _$FilePathManager extends $Notifier<String> {
  late final _$args = ref.$arg as String;
  String get key => _$args;

  String build({String key = DirectoryStorageKeys.defaultStorage});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(key: _$args));
  }
}
