import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../services/local_storage_service.dart';

/// Base de datos local SQLite para Windows, Android, Linux, macOS e iOS.
///
/// En Windows se guarda deliberadamente bajo LOCALAPPDATA para que la ruta sea
/// estable, fácil de respaldar y verificable por el coordinador.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _migrationFlag = 'sqlite.migration.v1.completed';
  static const _collections = <String>[
    'logifaena_workers',
    'logifaena_tickets',
    'logifaena_hotels',
    'logifaena_transfers',
    'logifaena_import_history',
  ];

  late Database _database;
  late String _databasePath;
  bool _initialized = false;

  bool get isSqlite => true;
  bool get isInitialized => _initialized;
  String get databasePath => _databasePath;
  bool get databaseExists => _initialized && File(_databasePath).existsSync();
  int get databaseSizeBytes => databaseExists ? File(_databasePath).lengthSync() : 0;

  Future<void> initialize() async {
    if (_initialized) return;

    final dataDirectory = await _resolveDataDirectory();
    if (!dataDirectory.existsSync()) {
      dataDirectory.createSync(recursive: true);
    }

    _databasePath = path.join(dataDirectory.path, 'logifaena_enterprise.db');
    _database = sqlite3.open(_databasePath);
    _database.execute('PRAGMA journal_mode = WAL;');
    _database.execute('PRAGMA foreign_keys = ON;');
    _database.execute('PRAGMA synchronous = NORMAL;');
    _database.execute('''
      CREATE TABLE IF NOT EXISTS local_collections (
        storage_key TEXT NOT NULL,
        item_index INTEGER NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (storage_key, item_index)
      );
    ''');
    _database.execute('''
      CREATE TABLE IF NOT EXISTS schema_info (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    _database.execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        occurred_at TEXT NOT NULL,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        details TEXT
      );
    ''');
    _database.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending'
      );
    ''');
    _database.execute(
      'INSERT OR REPLACE INTO schema_info (key, value) VALUES (?, ?)',
      ['schema_version', '1'],
    );

    _initialized = true;
    await _migrateLegacyCollections();

    debugPrint('LogiFaena SQLite activo: $_databasePath');
    debugPrint('Base creada: $databaseExists · tamaño: $databaseSizeBytes bytes');
  }

  Future<Directory> _resolveDataDirectory() async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.trim().isNotEmpty) {
        return Directory(path.join(localAppData, 'LogiFaena Enterprise', 'data'));
      }
    }

    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(path.join(supportDirectory.path, 'data'));
  }

  Future<void> _migrateLegacyCollections() async {
    if (LocalStorageService.instance.readBool(_migrationFlag)) return;

    for (final key in _collections) {
      final sqliteItems = readList(key);
      if (sqliteItems.isNotEmpty) continue;

      final legacyItems = LocalStorageService.instance.readList(key);
      if (legacyItems.isNotEmpty) {
        await writeList(key, legacyItems);
      }
    }

    await LocalStorageService.instance.writeBool(_migrationFlag, true);
  }

  List<Map<String, dynamic>> readList(String key) {
    if (!_initialized) return [];
    final rows = _database.select(
      'SELECT payload FROM local_collections WHERE storage_key = ? ORDER BY item_index',
      [key],
    );

    final items = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        final value = jsonDecode(row['payload'] as String);
        if (value is Map<String, dynamic>) items.add(value);
      } catch (_) {
        // Un registro dañado no impide cargar el resto de la colección.
      }
    }
    return items;
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    if (!_initialized) return;
    final now = DateTime.now().toUtc().toIso8601String();
    _database.execute('BEGIN IMMEDIATE TRANSACTION;');
    try {
      _database.execute(
        'DELETE FROM local_collections WHERE storage_key = ?',
        [key],
      );
      for (var index = 0; index < value.length; index++) {
        _database.execute(
          'INSERT INTO local_collections '
          '(storage_key, item_index, payload, updated_at) VALUES (?, ?, ?, ?)',
          [key, index, jsonEncode(value[index]), now],
        );
      }
      _database.execute('COMMIT;');
    } catch (_) {
      _database.execute('ROLLBACK;');
      rethrow;
    }
  }
}
