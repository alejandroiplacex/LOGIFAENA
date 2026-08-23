import '../../hotels/data/hotel_repository.dart';
import '../../hotels/domain/hotel_assignment.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../tickets/domain/ticket.dart';
import '../../transfers/data/transfer_repository.dart';
import '../../transfers/domain/transfer.dart';
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

      final ticket = InMemoryTicketRepository.instance.findByWorkerId(
        worker.id,
      );

      final hotel = InMemoryHotelRepository.instance.findByWorkerId(worker.id);

      final transfers = InMemoryTransferRepository.instance.findByWorkerId(
        worker.id,
      );

      final hasValidTicket =
          ticket != null &&
          (ticket.status == TicketStatus.issued ||
              ticket.status == TicketStatus.rescheduled);

      final hasValidHotel =
          hotel != null &&
          (hotel.status == HotelStatus.confirmed ||
              hotel.status == HotelStatus.checkedIn ||
              hotel.status == HotelStatus.checkedOut);

      final ticketPendingEmission =
          ticket != null && ticket.status == TicketStatus.requested;

      final hotelPendingConfirmation =
          hotel != null && hotel.status == HotelStatus.requested;

      final hasValidTransfer = transfers.any(
        (transfer) => transfer.status != TransferStatus.cancelled,
      );

      final requiresTicket =
          ticketPendingEmission ||
          switch (worker.status) {
            WorkerStatus.ticketIssued ||
            WorkerStatus.traveling ||
            WorkerStatus.lodging ||
            WorkerStatus.transfer => true,
            _ => false,
          };

      final requiresHotel =
          hotelPendingConfirmation ||
          switch (worker.status) {
            WorkerStatus.ticketIssued ||
            WorkerStatus.traveling ||
            WorkerStatus.lodging => true,
            _ => false,
          };

      final requiresTransfer =
          (hasValidTicket && hasValidHotel) ||
          switch (worker.status) {
            WorkerStatus.lodging || WorkerStatus.transfer => true,
            _ => false,
          };

      if (requiresTicket && ticketPendingEmission) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-ticket-pending',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} con pasaje pendiente de emisión',
            detail:
                'El pasaje fue solicitado, pero todavía no ha sido emitido.',
            severity: AlertSeverity.medium,
            category: AlertCategory.ticket,
          ),
        );
      }

      if (requiresTicket && !hasValidTicket && !ticketPendingEmission) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-ticket',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} sin pasaje válido',
            detail:
                'El trabajador se encuentra en una etapa que requiere pasaje.',
            severity: AlertSeverity.high,
            category: AlertCategory.ticket,
          ),
        );
      }

      if (requiresHotel && hotelPendingConfirmation) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-hotel-pending',
            workerId: worker.id,
            workerName: worker.fullName,
            title:
                '${worker.fullName} con alojamiento pendiente de confirmación',
            detail:
                'El alojamiento fue solicitado, pero todavía no ha sido confirmado.',
            severity: AlertSeverity.medium,
            category: AlertCategory.hotel,
          ),
        );
      }

      if (requiresHotel && !hasValidHotel && !hotelPendingConfirmation) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-hotel',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} sin alojamiento válido',
            detail:
                'El trabajador se encuentra en una etapa que requiere alojamiento.',
            severity: AlertSeverity.high,
            category: AlertCategory.hotel,
          ),
        );
      }

      if (requiresTransfer && !hasValidTransfer) {
        alerts.add(
          OperationalAlert(
            id: '${worker.id}-transfer',
            workerId: worker.id,
            workerName: worker.fullName,
            title: '${worker.fullName} sin traslado válido',
            detail:
                'El trabajador se encuentra en una etapa que requiere traslado.',
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
