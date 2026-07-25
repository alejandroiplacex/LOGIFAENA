import '../../../core/database/database_service.dart';
import '../domain/hotel_assignment.dart';

abstract class HotelRepository {
  List<HotelAssignment> getAll();
  HotelAssignment? findByWorkerId(String workerId);
  void add(HotelAssignment assignment);
  void replaceAll(List<HotelAssignment> assignments);
  void update(HotelAssignment assignment);
  void delete(String id);
}

class InMemoryHotelRepository implements HotelRepository {
  InMemoryHotelRepository._() {
    final saved = DatabaseService.instance.readList('logifaena_hotels');
    if (saved.isNotEmpty) {
      _assignments
        ..clear()
        ..addAll(saved.map(HotelAssignment.fromJson));
    }
  }
  static final InMemoryHotelRepository instance = InMemoryHotelRepository._();

  final List<HotelAssignment> _assignments = [
    HotelAssignment(
      id: 'h1', workerId: '1', hotelName: 'Hotel Central', city: 'Calama',
      address: 'Av. Granaderos 1200', contactName: 'Marcela Soto',
      contactPhone: '+56 9 5555 1000', room: '302',
      checkInDate: DateTime(2026, 7, 20), checkOutDate: DateTime(2026, 7, 30),
      dailyRate: 62000, confirmationCode: 'HC-9081',
      notes: 'Desayuno incluido.', status: HotelStatus.confirmed,
    ),
    HotelAssignment(
      id: 'h2', workerId: '3', hotelName: 'Hotel Norte', city: 'Antofagasta',
      address: 'Av. Brasil 850', contactName: 'Luis Mena',
      contactPhone: '+56 9 5555 2000', room: '115',
      checkInDate: DateTime(2026, 7, 18), checkOutDate: DateTime(2026, 7, 25),
      dailyRate: 58000, confirmationCode: 'HN-4412',
      notes: 'Traslado desde aeropuerto pendiente.', status: HotelStatus.checkedIn,
    ),
  ];

  void _persist() {
    DatabaseService.instance.writeList(
      'logifaena_hotels',
      _assignments.map((item) => item.toJson()).toList(),
    );
  }

  @override
  List<HotelAssignment> getAll() => List.unmodifiable(_assignments);

  @override
  HotelAssignment? findByWorkerId(String workerId) {
    for (final item in _assignments) {
      if (item.workerId == workerId) return item;
    }
    return null;
  }

  @override
  void add(HotelAssignment assignment) {
    _assignments.add(assignment);
    _persist();
  }

  @override
  void replaceAll(List<HotelAssignment> assignments) {
    _assignments
      ..clear()
      ..addAll(assignments);
    _persist();
  }

  @override
  void update(HotelAssignment assignment) {
    final index = _assignments.indexWhere((item) => item.id == assignment.id);
    if (index != -1) {
      _assignments[index] = assignment;
      _persist();
    }
  }

  @override
  void delete(String id) {
    _assignments.removeWhere((item) => item.id == id);
    _persist();
  }
}
