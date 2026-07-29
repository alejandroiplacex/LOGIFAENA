import '../../features/hotels/domain/hotel_assignment.dart';
import '../../features/tickets/domain/ticket.dart';
import '../../features/transfers/domain/transfer.dart';
import '../../features/workers/domain/worker.dart';
import 'logistics_alert.dart';
import 'operation_note.dart';
import 'operation_status.dart';
import 'provider.dart';
import 'vehicle.dart';

class Operation {
  final String id;
  String company;
  String project;
  String shift;
  String coordinator;
  DateTime startDate;
  DateTime endDate;
  OperationStatus status;
  final List<Worker> workers;
  final List<Ticket> tickets;
  final List<HotelAssignment> hotels;
  final List<Transfer> transfers;
  final List<Vehicle> vehicles;
  final List<Provider> providers;
  final List<OperationNote> notes;
  final List<LogisticsAlert> alerts;
  final DateTime createdAt;
  DateTime updatedAt;
  String createdBy;

  Operation({
    required this.id,
    required this.company,
    required this.project,
    required this.shift,
    required this.coordinator,
    required this.startDate,
    required this.endDate,
    required this.status,
    List<Worker>? workers,
    List<Ticket>? tickets,
    List<HotelAssignment>? hotels,
    List<Transfer>? transfers,
    List<Vehicle>? vehicles,
    List<Provider>? providers,
    List<OperationNote>? notes,
    List<LogisticsAlert>? alerts,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  }) : workers = workers ?? <Worker>[],
       tickets = tickets ?? <Ticket>[],
       hotels = hotels ?? <HotelAssignment>[],
       transfers = transfers ?? <Transfer>[],
       vehicles = vehicles ?? <Vehicle>[],
       providers = providers ?? <Provider>[],
       notes = notes ?? <OperationNote>[],
       alerts = alerts ?? <LogisticsAlert>[];

  int get totalWorkers => workers.length;
  int get issuedTickets =>
      tickets.where((item) => item.status == TicketStatus.issued).length;
  int get confirmedHotels => hotels
      .where(
        (item) =>
            item.status == HotelStatus.confirmed ||
            item.status == HotelStatus.checkedIn ||
            item.status == HotelStatus.checkedOut,
      )
      .length;
  int get assignedTransfers => workers
      .where(
        (worker) =>
            transfers.any((transfer) => transfer.workerIds.contains(worker.id)),
      )
      .length;

  double get operationalReadinessIndex {
    if (workers.isEmpty) return 0;
    var completedRequirements = 0;
    for (final worker in workers) {
      if (tickets.any(
        (ticket) =>
            ticket.workerId == worker.id &&
            ticket.status == TicketStatus.issued,
      )) {
        completedRequirements++;
      }
      if (hotels.any(
        (hotel) =>
            hotel.workerId == worker.id &&
            hotel.status != HotelStatus.requested &&
            hotel.status != HotelStatus.cancelled,
      )) {
        completedRequirements++;
      }
      if (transfers.any(
        (transfer) =>
            transfer.workerIds.contains(worker.id) &&
            transfer.status != TransferStatus.cancelled,
      )) {
        completedRequirements++;
      }
    }
    return (completedRequirements / (workers.length * 3)) * 100;
  }

  Worker? findWorkerByRut(String rut) {
    final normalized = normalizeRut(rut);
    for (final worker in workers) {
      if (normalizeRut(worker.rut) == normalized) return worker;
    }
    return null;
  }

  static String normalizeRut(String value) =>
      value.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company,
    'project': project,
    'shift': shift,
    'coordinator': coordinator,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status.name,
    'workers': workers.map((item) => item.toJson()).toList(),
    'tickets': tickets.map((item) => item.toJson()).toList(),
    'hotels': hotels.map((item) => item.toJson()).toList(),
    'transfers': transfers.map((item) => item.toJson()).toList(),
    'vehicles': vehicles.map((item) => item.toJson()).toList(),
    'providers': providers.map((item) => item.toJson()).toList(),
    'notes': notes.map((item) => item.toJson()).toList(),
    'alerts': alerts.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
  };
}
