import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();
  late SharedPreferences _preferences;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  List<Map<String, dynamic>> readList(String key) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) {
    return _preferences.setString(key, jsonEncode(value));
  }

  bool readBool(String key, {bool fallback = false}) {
    return _preferences.getBool(key) ?? fallback;
  }

  String? readString(String key) {
    return _preferences.getString(key);
  }

  Future<void> writeBool(String key, bool value) {
    return _preferences.setBool(key, value);
  }

  Future<void> writeString(String key, String value) {
    return _preferences.setString(key, value);
  }

  Future<void> remove(String key) {
    return _preferences.remove(key);
  }
}
