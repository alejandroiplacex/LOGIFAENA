import '../database/database_service.dart';
import 'audit_entry.dart';

/// Administra el historial local de acciones importantes.
class AuditService {
  AuditService._();

  static final AuditService instance = AuditService._();

  final DatabaseService _database = DatabaseService.instance;

  Future<int> record({
    required String action,
    required String entityType,
    String? details,
  }) {
    return _database.insertAuditEntry(
      occurredAt: DateTime.now().toUtc().toIso8601String(),
      action: action,
      entityType: entityType,
      details: details,
    );
  }

  List<AuditEntry> getAll() {
    return _database
        .readAuditLog()
        .map(AuditEntry.fromDatabaseRow)
        .toList(growable: false);
  }

  Future<void> clear() {
    return _database.clearAuditLog();
  }
}
