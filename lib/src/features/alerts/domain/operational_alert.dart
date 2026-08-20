enum AlertSeverity { high, medium, low }

enum AlertCategory { presentation, ticket, hotel, transfer }

class OperationalAlert {
  final String id;
  final String workerId;
  final String workerName;
  final String title;
  final String detail;
  final AlertSeverity severity;
  final AlertCategory category;

  const OperationalAlert({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.title,
    required this.detail,
    required this.severity,
    required this.category,
  });
}
