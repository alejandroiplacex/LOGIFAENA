import '../../../core/database/database_service.dart';
import '../domain/transfer.dart';

abstract class TransferRepository {
  List<Transfer> getAll();
  List<Transfer> findByWorkerId(String workerId);
  void add(Transfer transfer);
  void replaceAll(List<Transfer> transfers);
  void update(Transfer transfer);
  void delete(String id);
}

class InMemoryTransferRepository implements TransferRepository {
  InMemoryTransferRepository._() {
    final saved = DatabaseService.instance.readList('logifaena_transfers');
    if (saved.isNotEmpty) {
      _transfers
        ..clear()
        ..addAll(saved.map(Transfer.fromJson));
    }
  }

  static final InMemoryTransferRepository instance =
      InMemoryTransferRepository._();

  final List<Transfer> _transfers = [
    Transfer(
      id: 'tr1',
      code: 'TR-001',
      date: DateTime(2026, 7, 20),
      departureTime: '16:30',
      estimatedArrivalTime: '17:15',
      origin: 'Aeropuerto El Loa',
      destination: 'Hotel Central',
      routeDescription: 'Aeropuerto → Hotel',
      vehicleType: TransferVehicleType.van,
      vehicleIdentifier: 'Van 03',
      licensePlate: 'ABCD-12',
      capacity: 8,
      driverName: 'Ricardo Muñoz',
      driverPhone: '+56 9 7777 1000',
      providerCompany: 'Transportes Norte',
      workerIds: ['1'],
      notes: 'Esperar retiro de equipaje.',
      status: TransferStatus.scheduled,
    ),
    Transfer(
      id: 'tr2',
      code: 'TR-002',
      date: DateTime(2026, 7, 21),
      departureTime: '05:30',
      estimatedArrivalTime: '07:00',
      origin: 'Hotel Central',
      destination: 'Faena Norte',
      routeDescription: 'Hotel → Faena',
      vehicleType: TransferVehicleType.bus,
      vehicleIdentifier: 'Bus 14',
      licensePlate: 'EFGH-34',
      capacity: 30,
      driverName: 'Marcelo Rojas',
      driverPhone: '+56 9 7777 2000',
      providerCompany: 'Buses Cordillera',
      workerIds: ['1', '2'],
      notes: 'Presentarse 15 minutos antes.',
      status: TransferStatus.onRoute,
    ),
  ];

  void _persist() {
    DatabaseService.instance.writeList(
      'logifaena_transfers',
      _transfers.map((item) => item.toJson()).toList(),
    );
  }

  @override
  List<Transfer> getAll() => List.unmodifiable(_transfers);

  @override
  List<Transfer> findByWorkerId(String workerId) {
    return _transfers
        .where((transfer) => transfer.workerIds.contains(workerId))
        .toList();
  }

  @override
  void add(Transfer transfer) {
    _transfers.add(transfer);
    _persist();
  }

  @override
  void replaceAll(List<Transfer> transfers) {
    _transfers
      ..clear()
      ..addAll(transfers);
    _persist();
  }

  @override
  void update(Transfer transfer) {
    final index = _transfers.indexWhere((item) => item.id == transfer.id);
    if (index != -1) {
      _transfers[index] = transfer;
      _persist();
    }
  }

  @override
  void delete(String id) {
    _transfers.removeWhere((transfer) => transfer.id == id);
    _persist();
  }
}
