import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/database/database_service.dart';
import 'src/core/services/local_storage_service.dart';
import 'src/core/sync/sync_transport_factory.dart';
import 'src/features/workers/data/http_worker_changes_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.instance.initialize();
  await DatabaseService.instance.initialize();

  final syncConfig = SyncTransportConfig.fromEnvironment();

  if (syncConfig.mode == SyncTransportMode.http &&
      syncConfig.apiBaseUrl.trim().isNotEmpty) {
    final workerChangesService = HttpWorkerChangesService(
      config: syncConfig,
    );

    try {
      final result = await workerChangesService.downloadChanges();

      debugPrint(
        'SINCRONIZACION INICIAL -> '
        '${result.created} creados, '
        '${result.updated} actualizados, '
        '${result.deleted} eliminados',
      );
    } catch (error) {
      debugPrint(
        'SINCRONIZACION INICIAL -> no fue posible descargar trabajadores: '
        '$error',
      );
    } finally {
      workerChangesService.close();
    }
  }

  runApp(const LogiFaenaApp());
}