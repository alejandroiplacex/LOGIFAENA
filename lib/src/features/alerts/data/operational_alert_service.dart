import '../../hotels/data/hotel_repository.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../transfers/data/transfer_repository.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../domain/operational_alert.dart';

class OperationalAlertService {
  OperationalAlertService._();

  static final OperationalAlertService instance = OperationalAlertService._();

  List<OperationalAlert> getAlerts() {
    final workers = InMemoryWorkerRepository.instance.getAll();
    final alerts = <OperationalAlert>[];

    for (final worker in workers) {
      if (worker.presentationStatus == PresentationStatus.absent) {
        final time = worker.presentationAt;
        final timeText = time == null
            ? 'Hora no registrada'
            : '${time.hour.toString().padLeft(2, '0')}:'
                  '${time.minute.toString().padLeft(2, '0')}';

        alerts.add(
          OperationalAlert(
            id: '${worker.id}-presentation-absent',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} no se presentó',
            detail:
                'Ausencia registrada en control de presentación · $timeText',
            severity: AlertSeverity.high,
            category: AlertCategory.presentation,
          ),
        );
      }

      if (worker.presentationStatus == PresentationStatus.late) {
        final time = worker.presentationAt;
        final timeText = time == null
            ? 'Hora no registrada'
            : '${time.hour.toString().padLeft(2, '0')}:'
                  '${time.minute.toString().padLeft(2, '0')}';

        alerts.add(
          OperationalAlert(
            id: '${worker.id}-presentation-late',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} presentó atraso',
            detail: 'Presentación tardía registrada · $timeText',
            severity: AlertSeverity.medium,
            category: AlertCategory.presentation,
          ),
        );
      }
      if (InMemoryTicketRepository.instance.findByWorkerId(worker.id) == null) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-ticket',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} sin pasaje asignado',
            detail: 'Requiere gestionar y emitir su viaje.',
            severity: AlertSeverity.high,
            category: AlertCategory.ticket,
          ),
        );
      }

      if (InMemoryHotelRepository.instance.findByWorkerId(worker.id) == null) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-hotel',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} sin alojamiento',
            detail: 'La asignación de hotel está pendiente.',
            severity: AlertSeverity.high,
            category: AlertCategory.hotel,
          ),
        );
      }

      if (InMemoryTransferRepository.instance
          .findByWorkerId(worker.id)
          .isEmpty) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-transfer',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} sin traslado',
            detail: 'Debe programarse su transporte operacional.',
            severity: AlertSeverity.medium,
            category: AlertCategory.transfer,
          ),
        );
      }
    }

    alerts.sort((a, b) => _weight(b.severity).compareTo(_weight(a.severity)));
    return List.unmodifiable(alerts);
  }

  int _weight(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return 3;
      case AlertSeverity.medium:
        return 2;
      case AlertSeverity.low:
        return 1;
    }
  }
}
