import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseBackend {
  Database? _database;

  bool get isAvailable => _database != null;

  Future<void> initialize() async {
    sqfliteFfiInit();
    final baseDirectory = _resolveBaseDirectory();
    await Directory(baseDirectory).create(recursive: true);
    final databasePath = p.join(baseDirectory, 'logifaena_enterprise.db');

    _database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
          await database.execute('PRAGMA journal_mode = WAL');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE entity_store (
              collection_key TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              payload TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              PRIMARY KEY (collection_key, entity_id)
            )
          ''');
          await database.execute('''
            CREATE INDEX idx_entity_store_collection
            ON entity_store(collection_key)
          ''');
          await database.execute('''
            CREATE TABLE audit_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              action TEXT NOT NULL,
              entity TEXT NOT NULL,
              entity_id TEXT,
              details TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              operation_id TEXT NOT NULL UNIQUE,
              entity TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              operation_type TEXT NOT NULL,
              payload TEXT NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 0,
              status TEXT NOT NULL DEFAULT 'pending',
              created_at TEXT NOT NULL,
              last_attempt_at TEXT
            )
          ''');
          await database.execute('''
            CREATE TABLE schema_info (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await database.insert('schema_info', {
            'key': 'schema_version',
            'value': '1',
          });
        },
      ),
    );
  }

  String _resolveBaseDirectory() {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return p.join(appData, 'LogiFaena Enterprise', 'data');
      }
    }
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    return p.join(home, '.logifaena_enterprise', 'data');
  }

  Future<List<Map<String, dynamic>>> readCollection(String key) async {
    final database = _database;
    if (database == null) return const [];
    final rows = await database.query(
      'entity_store',
      columns: ['payload'],
      where: 'collection_key = ?',
      whereArgs: [key],
      orderBy: 'updated_at ASC',
    );
    return rows
        .map((row) => jsonDecode(row['payload']! as String))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> replaceCollection(
    String key,
    List<Map<String, dynamic>> values,
  ) async {
    final database = _database;
    if (database == null) return;
    await database.transaction((transaction) async {
      await transaction.delete(
        'entity_store',
        where: 'collection_key = ?',
        whereArgs: [key],
      );
      final now = DateTime.now().toUtc().toIso8601String();
      for (var index = 0; index < values.length; index++) {
        final value = values[index];
        final rawId = value['id']?.toString();
        final entityId = rawId == null || rawId.isEmpty ? '$index' : rawId;
        await transaction.insert('entity_store', {
          'collection_key': key,
          'entity_id': entityId,
          'payload': jsonEncode(value),
          'updated_at': now,
        });
      }
    });
  }

  Future<void> addAuditEntry({
    required String action,
    required String entity,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    final database = _database;
    if (database == null) return;
    await database.insert('audit_log', {
      'action': action,
      'entity': entity,
      'entity_id': entityId,
      'details': details == null ? null : jsonEncode(details),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
