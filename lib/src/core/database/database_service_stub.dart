import '../services/local_storage_service.dart';

/// Implementación compatible con Web.
/// En navegadores mantiene el almacenamiento existente mediante SharedPreferences.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static const _syncQueueKey = 'logifaena_sync_queue';

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

  Future<int> enqueueSyncOperation({
    required String entityType,
    String? entityId,
    required String operation,
    required String payload,
    required String createdAt,
    int attempts = 0,
    String status = 'pending',
  }) async {
    final items = readList(_syncQueueKey);

    final nextId =
        items.fold<int>(0, (highest, item) {
          final currentId = (item['id'] as num?)?.toInt() ?? 0;
          return currentId > highest ? currentId : highest;
        }) +
        1;

    items.add(<String, dynamic>{
      'id': nextId,
      'created_at': createdAt,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'attempts': attempts,
      'status': status,
    });

    await writeList(_syncQueueKey, items);
    return nextId;
  }

  List<Map<String, Object?>> readSyncQueue({String? status}) {
    final items = readList(_syncQueueKey);

    return items
        .where((item) => status == null || item['status'] == status)
        .map(
          (item) => <String, Object?>{
            'id': item['id'],
            'created_at': item['created_at'],
            'entity_type': item['entity_type'],
            'entity_id': item['entity_id'],
            'operation': item['operation'],
            'payload': item['payload'],
            'attempts': item['attempts'],
            'status': item['status'],
          },
        )
        .toList()
      ..sort((first, second) {
        final firstId = (first['id'] as num?)?.toInt() ?? 0;
        final secondId = (second['id'] as num?)?.toInt() ?? 0;
        return firstId.compareTo(secondId);
      });
  }

  Future<void> updateSyncOperationStatus(
    int id,
    String status, {
    bool incrementAttempts = false,
  }) async {
    final items = readList(_syncQueueKey);
    final index = items.indexWhere(
      (item) => (item['id'] as num?)?.toInt() == id,
    );

    if (index == -1) return;

    final current = Map<String, dynamic>.from(items[index]);
    current['status'] = status;

    if (incrementAttempts) {
      current['attempts'] = ((current['attempts'] as num?)?.toInt() ?? 0) + 1;
    }

    items[index] = current;
    await writeList(_syncQueueKey, items);
  }

  Future<void> deleteSyncOperation(int id) async {
    final items = readList(_syncQueueKey)
      ..removeWhere((item) => (item['id'] as num?)?.toInt() == id);

    await writeList(_syncQueueKey, items);
  }
}
