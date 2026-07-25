enum OperationStatus {
  planning,
  validation,
  ready,
  active,
  executing,
  finished,
  archived,
  cancelled,
}

extension OperationStatusLabel on OperationStatus {
  String get label {
    switch (this) {
      case OperationStatus.planning:
        return 'Planificación';
      case OperationStatus.validation:
        return 'Validación';
      case OperationStatus.ready:
        return 'Lista';
      case OperationStatus.active:
        return 'Activa';
      case OperationStatus.executing:
        return 'En ejecución';
      case OperationStatus.finished:
        return 'Finalizada';
      case OperationStatus.archived:
        return 'Archivada';
      case OperationStatus.cancelled:
        return 'Cancelada';
    }
  }
}
