import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static SharedPreferencesAsync? _prefs;

  static SharedPreferencesAsync get _instance {
    _prefs ??= SharedPreferencesAsync();
    return _prefs!;
  }

  /// Set string
  static Future<void> setString(String key, String value) async {
    await _instance.setString(key, value);
  }

  /// Get string
  static Future<String?> getString(String key) async {
    return await _instance.getString(key);
  }

  /// Set int
  static Future<void> setInt(String key, int value) async {
    await _instance.setInt(key, value);
  }

  /// Get int
  static Future<int?> getInt(String key) async {
    return await _instance.getInt(key);
  }

  static Future<void> setJson(String key, dynamic value) async {
    await _instance.setString(key, json.encode(value));
  }

  static dynamic getJson(String key) async {
    try {
      String? tempData = await _instance.getString(key);
      if (tempData != null) {
        return json.decode(tempData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static void removeData(String key) {
    _instance.remove(key);
  }

  static void clearData(Set<String>? allowList) {
    _instance.clear(allowList: allowList);
  }
}
