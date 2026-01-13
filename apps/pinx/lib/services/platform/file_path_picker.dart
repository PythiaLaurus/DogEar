import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

class FilePathPicker {
  // Choose a directory
  Future<String?> selectDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      return result;
    } catch (e) {
      _onError('Directory selection failed: $e');
      return null;
    }
  }

  // Choose a single file
  Future<File?> pickSingleFile({List<String>? allowedExtensions}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions == null ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (result != null && result.files.isNotEmpty) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      _onError('File selection failed: $e');
    }
    return null;
  }

  // Choose multiple files
  Future<List<File>> pickMultipleFiles({
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: allowedExtensions == null ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (result != null) {
        return result.files.map((f) => File(f.path!)).toList();
      }
    } catch (e) {
      _onError('Multiple file selection failed: $e');
    }
    return [];
  }

  void _onError(String message) {
    assert(() {
      debugPrint('[FilePathPicker Error] $message');
      return true;
    }());
  }
}
