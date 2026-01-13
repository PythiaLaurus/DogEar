import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage._();
  static final instance = AppStorage._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// Set string
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Get string
  Future<String?> getString(String key) async {
    return await _prefs.getString(key);
  }

  /// Set int
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  /// Get int
  Future<int?> getInt(String key) async {
    return await _prefs.getInt(key);
  }

  Future<void> setJson(String key, dynamic value) async {
    await _prefs.setString(key, json.encode(value));
  }

  dynamic getJson(String key) async {
    try {
      String? tempData = await _prefs.getString(key);
      if (tempData != null) {
        return json.decode(tempData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void removeData(String key) {
    _prefs.remove(key);
  }

  void clearData(Set<String>? allowList) {
    _prefs.clear(allowList: allowList);
  }
}

final appStorage = AppStorage.instance;
