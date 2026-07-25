import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/core/services/local_storage_service.dart';
import 'src/core/database/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.initialize();
  await DatabaseService.instance.initialize();
  runApp(const LogiFaenaApp());
}
