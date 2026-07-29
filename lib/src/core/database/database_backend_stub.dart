class DatabaseBackend {
  Future<void> initialize() async {}

  bool get isAvailable => false;

  Future<List<Map<String, dynamic>>> readCollection(String key) async =>
      const [];

  Future<void> replaceCollection(
    String key,
    List<Map<String, dynamic>> values,
  ) async {}

  Future<void> addAuditEntry({
    required String action,
    required String entity,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {}

  Future<void> close() async {}
}
