import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path/path.dart' as p;
import '../../core/storage/directory_storage_keys.dart';
import 'file_path_picker.dart';
import '../../core/storage/storage.dart';

part 'file_path_manager.g.dart';

@Riverpod(keepAlive: true)
class FilePathManager extends _$FilePathManager {
  final _picker = FilePathPicker();

  late final String _key;

  @override
  String build({String key = DirectoryStorageKeys.defaultStorage}) {
    _key = key;

    // Initialize the controller with the saved path or default path
    _init();

    return "";
  }

  Future<void> selectNewPath() async {
    final newPath = await _picker.selectDirectory();
    if (newPath != null) {
      _updatePath(newPath);
    }
  }

  Future<void> _init() async {
    final initPath = await _getPath();
    state = initPath;
  }

  Future<String> _getPath() async {
    final saved = await Storage.getString(_key);
    if (saved is String && saved.isNotEmpty) {
      return saved;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final fullPath = p.join(dir.path, _key);
      await Storage.setString(_key, fullPath);

      return fullPath;
    }
  }

  Future<void> _updatePath(String newPath) async {
    await Storage.setString(_key, newPath);
    state = newPath;
  }
}
