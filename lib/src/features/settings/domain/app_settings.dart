class AppSettings {
  final String companyName;
  final String taxId;
  final String defaultSite;
  final String coordinatorName;
  final String coordinatorRole;
  final bool notificationsEnabled;
  final bool automaticBackup;
  final bool automaticSync;
  final int syncIntervalMinutes;
  final String apiBaseUrl;

  const AppSettings({
    required this.companyName,
    required this.taxId,
    required this.defaultSite,
    required this.coordinatorName,
    required this.coordinatorRole,
    required this.notificationsEnabled,
    required this.automaticBackup,
    required this.automaticSync,
    required this.syncIntervalMinutes,
    required this.apiBaseUrl,
  });

  factory AppSettings.defaults() => const AppSettings(
        companyName: 'LogiFaena Enterprise',
        taxId: '',
        defaultSite: 'Faena Norte',
        coordinatorName: 'Alejandro Cárdenas',
        coordinatorRole: 'Coordinador Logístico',
        notificationsEnabled: true,
        automaticBackup: true,
        automaticSync: false,
        syncIntervalMinutes: 15,
        apiBaseUrl: '',
      );

  AppSettings copyWith({
    String? companyName,
    String? taxId,
    String? defaultSite,
    String? coordinatorName,
    String? coordinatorRole,
    bool? notificationsEnabled,
    bool? automaticBackup,
    bool? automaticSync,
    int? syncIntervalMinutes,
    String? apiBaseUrl,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      taxId: taxId ?? this.taxId,
      defaultSite: defaultSite ?? this.defaultSite,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      coordinatorRole: coordinatorRole ?? this.coordinatorRole,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      automaticBackup: automaticBackup ?? this.automaticBackup,
      automaticSync: automaticSync ?? this.automaticSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'taxId': taxId,
        'defaultSite': defaultSite,
        'coordinatorName': coordinatorName,
        'coordinatorRole': coordinatorRole,
        'notificationsEnabled': notificationsEnabled,
        'automaticBackup': automaticBackup,
        'automaticSync': automaticSync,
        'syncIntervalMinutes': syncIntervalMinutes,
        'apiBaseUrl': apiBaseUrl,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      companyName: json['companyName'] as String? ?? defaults.companyName,
      taxId: json['taxId'] as String? ?? defaults.taxId,
      defaultSite: json['defaultSite'] as String? ?? defaults.defaultSite,
      coordinatorName:
          json['coordinatorName'] as String? ?? defaults.coordinatorName,
      coordinatorRole:
          json['coordinatorRole'] as String? ?? defaults.coordinatorRole,
      notificationsEnabled:
          json['notificationsEnabled'] as bool? ?? defaults.notificationsEnabled,
      automaticBackup:
          json['automaticBackup'] as bool? ?? defaults.automaticBackup,
      automaticSync:
          json['automaticSync'] as bool? ?? defaults.automaticSync,
      syncIntervalMinutes:
          json['syncIntervalMinutes'] as int? ?? defaults.syncIntervalMinutes,
      apiBaseUrl: json['apiBaseUrl'] as String? ?? defaults.apiBaseUrl,
    );
  }
}
