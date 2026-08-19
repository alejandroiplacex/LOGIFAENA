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

  final List<HotelAssignment> _assignments = <HotelAssignment>[];

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
