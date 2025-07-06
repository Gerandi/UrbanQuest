import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // JSON data operations
  Future<bool> saveData(String key, dynamic data) async {
    try {
      final jsonString = jsonEncode(data);
      return await setString(key, jsonString);
    } catch (e) {
      print('Error saving data for key $key: $e');
      return false;
    }
  }

  Future<dynamic> getData(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error getting data for key $key: $e');
      return null;
    }
  }

  // String operations
  Future<String?> getString(String key) async {
    return _preferences?.getString(key);
  }

  Future<bool> setString(String key, String value) async {
    return await _preferences?.setString(key, value) ?? false;
  }

  // Bool operations
  Future<bool?> getBool(String key) async {
    return _preferences?.getBool(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _preferences?.setBool(key, value) ?? false;
  }

  // Int operations
  Future<int?> getInt(String key) async {
    return _preferences?.getInt(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _preferences?.setInt(key, value) ?? false;
  }

  // Double operations
  Future<double?> getDouble(String key) async {
    return _preferences?.getDouble(key);
  }

  Future<bool> setDouble(String key, double value) async {
    return await _preferences?.setDouble(key, value) ?? false;
  }

  // List<String> operations
  Future<List<String>?> getStringList(String key) async {
    return _preferences?.getStringList(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences?.setStringList(key, value) ?? false;
  }

  // Remove operations
  Future<bool> remove(String key) async {
    return await _preferences?.remove(key) ?? false;
  }

  Future<bool> clear() async {
    return await _preferences?.clear() ?? false;
  }

  // Check if key exists
  bool containsKey(String key) {
    return _preferences?.containsKey(key) ?? false;
  }
}
