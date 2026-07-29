enum LogisticsAlertSeverity { critical, important, informative }

extension LogisticsAlertSeverityLabel on LogisticsAlertSeverity {
  String get label {
    switch (this) {
      case LogisticsAlertSeverity.critical:
        return 'Crítica';
      case LogisticsAlertSeverity.important:
        return 'Importante';
      case LogisticsAlertSeverity.informative:
        return 'Informativa';
    }
  }
}

class LogisticsAlert {
  final String id;
  final String operationId;
  final String? workerId;
  final LogisticsAlertSeverity severity;
  final String code;
  final String title;
  final String description;
  final DateTime createdAt;

  const LogisticsAlert({
    required this.id,
    required this.operationId,
    required this.workerId,
    required this.severity,
    required this.code,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operationId': operationId,
    'workerId': workerId,
    'severity': severity.name,
    'code': code,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };
}
