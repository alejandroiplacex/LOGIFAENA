import '../../features/hotels/domain/hotel_assignment.dart';
import '../../features/tickets/domain/ticket.dart';
import '../../features/transfers/domain/transfer.dart';
import '../../features/workers/domain/worker.dart';
import '../models/logistics_alert.dart';
import '../models/operation.dart';
import '../models/operation_status.dart';
import '../models/provider.dart';
import '../models/vehicle.dart';

class OperationEngine {
  const OperationEngine();

  Operation createOperation({
    required String id,
    required String company,
    required String project,
    required String shift,
    required String coordinator,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
    List<Worker> workers = const <Worker>[],
    List<Ticket> tickets = const <Ticket>[],
    List<HotelAssignment> hotels = const <HotelAssignment>[],
    List<Transfer> transfers = const <Transfer>[],
    List<Provider> providers = const <Provider>[],
    List<Vehicle> vehicles = const <Vehicle>[],
  }) {
    final now = DateTime.now();
    final operation = Operation(
      id: id,
      company: company,
      project: project,
      shift: shift,
      coordinator: coordinator,
      startDate: startDate,
      endDate: endDate,
      status: OperationStatus.validation,
      workers: List<Worker>.from(workers),
      tickets: List<Ticket>.from(tickets),
      hotels: List<HotelAssignment>.from(hotels),
      transfers: List<Transfer>.from(transfers),
      providers: List<Provider>.from(providers),
      vehicles: List<Vehicle>.from(vehicles),
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
    );

    recalculate(operation);
    return operation;
  }

  void recalculate(Operation operation) {
    _calculateWorkerStates(operation);
    operation.alerts
      ..clear()
      ..addAll(_generateAlerts(operation));
    operation.status = _calculateOperationStatus(operation);
    operation.updatedAt = DateTime.now();
  }

  void _calculateWorkerStates(Operation operation) {
    for (final worker in operation.workers) {
      if (worker.status == WorkerStatus.cancelled ||
          worker.status == WorkerStatus.finished ||
          worker.status == WorkerStatus.atSite) {
        continue;
      }

      final ticket = _ticketForWorker(operation, worker.id);
      final hotel = _hotelForWorker(operation, worker.id);
      final transfers = _transfersForWorker(operation, worker.id);

      if (transfers.any((item) => item.status == TransferStatus.onRoute)) {
        worker.status = WorkerStatus.transfer;
      } else if (hotel != null && hotel.status == HotelStatus.checkedIn) {
        worker.status = WorkerStatus.lodging;
      } else if (ticket != null && ticket.status == TicketStatus.issued) {
        worker.status = WorkerStatus.ticketIssued;
      } else {
        worker.status = WorkerStatus.pending;
      }
    }
  }

  List<LogisticsAlert> _generateAlerts(Operation operation) {
    final alerts = <LogisticsAlert>[];
    final now = DateTime.now();

    for (final worker in operation.workers) {
      if (worker.status == WorkerStatus.cancelled ||
          worker.status == WorkerStatus.finished) {
        continue;
      }

      final ticket = _ticketForWorker(operation, worker.id);
      final hotel = _hotelForWorker(operation, worker.id);
      final transfers = _transfersForWorker(operation, worker.id);

      if (ticket == null || ticket.status != TicketStatus.issued) {
        alerts.add(LogisticsAlert(
          id: '${operation.id}-${worker.id}-ticket',
          operationId: operation.id,
          workerId: worker.id,
          severity: LogisticsAlertSeverity.critical,
          code: 'WORKER_WITHOUT_ISSUED_TICKET',
          title: 'Trabajador sin pasaje emitido',
          description: '${worker.fullName} no tiene un pasaje emitido.',
          createdAt: now,
        ));
      }

      if (hotel == null ||
          hotel.status == HotelStatus.requested ||
          hotel.status == HotelStatus.cancelled) {
        alerts.add(LogisticsAlert(
          id: '${operation.id}-${worker.id}-hotel',
          operationId: operation.id,
          workerId: worker.id,
          severity: LogisticsAlertSeverity.critical,
          code: 'WORKER_WITHOUT_CONFIRMED_HOTEL',
          title: 'Trabajador sin alojamiento confirmado',
          description: '${worker.fullName} no tiene alojamiento confirmado.',
          createdAt: now,
        ));
      }

      if (transfers.isEmpty ||
          transfers.every((item) => item.status == TransferStatus.cancelled)) {
        alerts.add(LogisticsAlert(
          id: '${operation.id}-${worker.id}-transfer',
          operationId: operation.id,
          workerId: worker.id,
          severity: LogisticsAlertSeverity.important,
          code: 'WORKER_WITHOUT_TRANSFER',
          title: 'Trabajador sin traslado asignado',
          description: '${worker.fullName} no tiene traslado vigente.',
          createdAt: now,
        ));
      }
    }

    for (final transfer in operation.transfers) {
      if (transfer.status == TransferStatus.cancelled) continue;
      if (transfer.driverName.trim().isEmpty) {
        alerts.add(LogisticsAlert(
          id: '${operation.id}-${transfer.id}-driver',
          operationId: operation.id,
          workerId: null,
          severity: LogisticsAlertSeverity.critical,
          code: 'TRANSFER_WITHOUT_DRIVER',
          title: 'Traslado sin conductor',
          description: 'El traslado ${transfer.code} no tiene conductor asignado.',
          createdAt: now,
        ));
      }
      if (transfer.capacity > 0 && transfer.workerIds.length > transfer.capacity) {
        alerts.add(LogisticsAlert(
          id: '${operation.id}-${transfer.id}-capacity',
          operationId: operation.id,
          workerId: null,
          severity: LogisticsAlertSeverity.critical,
          code: 'TRANSFER_OVER_CAPACITY',
          title: 'Capacidad de traslado excedida',
          description: 'El traslado ${transfer.code} supera su capacidad.',
          createdAt: now,
        ));
      }
    }

    return alerts;
  }

  OperationStatus _calculateOperationStatus(Operation operation) {
    if (operation.status == OperationStatus.cancelled ||
        operation.status == OperationStatus.archived) {
      return operation.status;
    }
    if (operation.endDate.isBefore(DateTime.now()) &&
        operation.workers.every((worker) =>
            worker.status == WorkerStatus.finished ||
            worker.status == WorkerStatus.cancelled)) {
      return OperationStatus.finished;
    }
    if (operation.workers.isEmpty) return OperationStatus.planning;
    if (operation.alerts.any(
        (alert) => alert.severity == LogisticsAlertSeverity.critical)) {
      return OperationStatus.validation;
    }
    if (operation.operationalReadinessIndex >= 95) {
      return OperationStatus.ready;
    }
    if (!operation.startDate.isAfter(DateTime.now())) {
      return OperationStatus.executing;
    }
    return OperationStatus.active;
  }

  Ticket? _ticketForWorker(Operation operation, String workerId) {
    for (final item in operation.tickets.reversed) {
      if (item.workerId == workerId &&
          item.status != TicketStatus.cancelled) {
        return item;
      }
    }
    return null;
  }

  HotelAssignment? _hotelForWorker(Operation operation, String workerId) {
    for (final item in operation.hotels.reversed) {
      if (item.workerId == workerId &&
          item.status != HotelStatus.cancelled) {
        return item;
      }
    }
    return null;
  }

  List<Transfer> _transfersForWorker(Operation operation, String workerId) =>
      operation.transfers
          .where((item) => item.workerIds.contains(workerId))
          .toList(growable: false);
}
