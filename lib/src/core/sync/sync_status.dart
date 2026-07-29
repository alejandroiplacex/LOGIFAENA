enum SyncStatus {
  pending,
  sending,
  completed,
  failed;

  String get databaseValue => name;

  static SyncStatus fromDatabaseValue(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}
