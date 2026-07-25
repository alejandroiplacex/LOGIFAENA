import '../services/local_storage_service.dart';

/// Implementación compatible con Web.
/// En navegadores mantiene el almacenamiento existente mediante SharedPreferences.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Future<void> initialize() async {}

  bool get isSqlite => false;
  bool get isInitialized => true;
  String get databasePath => 'Almacenamiento web (SharedPreferences)';
  bool get databaseExists => false;
  int get databaseSizeBytes => 0;

  List<Map<String, dynamic>> readList(String key) {
    return LocalStorageService.instance.readList(key);
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) {
    return LocalStorageService.instance.writeList(key, value);
  }
}
