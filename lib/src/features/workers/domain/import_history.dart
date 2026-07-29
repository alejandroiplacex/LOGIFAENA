class ImportHistory {
  final String id;
  final String fileName;
  final String importedAt;
  final int rowsRead;
  final int created;
  final int updated;
  final int skippedOrInvalid;
  final String duplicatePolicy;

  const ImportHistory({
    required this.id,
    required this.fileName,
    required this.importedAt,
    required this.rowsRead,
    required this.created,
    required this.updated,
    required this.skippedOrInvalid,
    required this.duplicatePolicy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'importedAt': importedAt,
    'rowsRead': rowsRead,
    'created': created,
    'updated': updated,
    'skippedOrInvalid': skippedOrInvalid,
    'duplicatePolicy': duplicatePolicy,
  };

  factory ImportHistory.fromJson(Map<String, dynamic> json) => ImportHistory(
    id: json['id'] as String? ?? '',
    fileName: json['fileName'] as String? ?? '',
    importedAt: json['importedAt'] as String? ?? '',
    rowsRead: json['rowsRead'] as int? ?? 0,
    created: json['created'] as int? ?? 0,
    updated: json['updated'] as int? ?? 0,
    skippedOrInvalid: json['skippedOrInvalid'] as int? ?? 0,
    duplicatePolicy: json['duplicatePolicy'] as String? ?? '',
  );
}
