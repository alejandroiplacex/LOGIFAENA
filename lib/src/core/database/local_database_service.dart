import 'database_backend.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();
  final DatabaseBackend _backend = DatabaseBackend();

  bool get isAvailable => _backend.isAvailable;

  Future<void> initialize() => _backend.initialize();

  Future<List<Map<String, dynamic>>> readCollection(String key) {
    return _backend.readCollection(key);
  }

  Future<void> replaceCollection(
    String key,
    List<Map<String, dynamic>> values,
  ) {
    return _backend.replaceCollection(key, values);
  }

  Future<void> addAuditEntry({
    required String action,
    required String entity,
    String? entityId,
    Map<String, dynamic>? details,
  }) {
    return _backend.addAuditEntry(
      action: action,
      entity: entity,
      entityId: entityId,
      details: details,
    );
  }

  Future<void> close() => _backend.close();
}
