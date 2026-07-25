import 'dart:convert';

import '../../../core/services/local_storage_service.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  SettingsRepository._();

  static final SettingsRepository instance = SettingsRepository._();
  static const _storageKey = 'settings.enterprise.v1';

  AppSettings load() {
    final raw = LocalStorageService.instance.readString(_storageKey);
    if (raw == null || raw.isEmpty) return AppSettings.defaults();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> save(AppSettings settings) {
    return LocalStorageService.instance.writeString(
      _storageKey,
      jsonEncode(settings.toJson()),
    );
  }

  Future<void> restoreDefaults() => save(AppSettings.defaults());
}
