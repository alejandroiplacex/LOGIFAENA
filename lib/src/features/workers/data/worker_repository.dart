import '../../../core/database/database_service.dart';
import '../domain/worker.dart';

abstract class WorkerRepository {
  List<Worker> getAll();
  void add(Worker worker);
  void addAll(List<Worker> workers);
  ({int created, int updated}) importAll(List<Worker> workers, {required bool updateExisting});
  void update(Worker worker);
  void delete(String id);
}

class InMemoryWorkerRepository implements WorkerRepository {
  InMemoryWorkerRepository._() {
    final saved = DatabaseService.instance.readList('logifaena_workers');
    if (saved.isNotEmpty) {
      _workers
        ..clear()
        ..addAll(saved.map(Worker.fromJson));
    }
  }

  static final InMemoryWorkerRepository instance = InMemoryWorkerRepository._();

  final List<Worker> _workers = [
    Worker(
      id: '1',
      rut: '12.345.678-9',
      firstName: 'Juan',
      lastName: 'Pérez',
      company: 'AVA',
      role: 'Operador',
      project: 'Faena Norte',
      shift: '10x10',
      supervisor: 'Carlos Silva',
      city: 'Talca',
      phone: '+56 9 1111 1111',
      email: 'juan.perez@demo.cl',
      emergencyContact: 'María Pérez',
      emergencyPhone: '+56 9 5555 1111',
      hotel: 'Hotel Central',
      room: '302',
      ticket: 'LATAM LA345',
      transfer: 'Bus 14 · 05:30',
      notes: 'Sin observaciones.',
      status: WorkerStatus.atSite,
    ),
    Worker(
      id: '2',
      rut: '15.444.222-3',
      firstName: 'Pedro',
      lastName: 'Soto',
      company: 'AVA',
      role: 'Mecánico',
      project: 'Faena Norte',
      shift: '10x10',
      supervisor: 'Carlos Silva',
      city: 'Curicó',
      phone: '+56 9 2222 2222',
      email: 'pedro.soto@demo.cl',
      emergencyContact: 'Andrea Soto',
      emergencyPhone: '+56 9 5555 2222',
      hotel: '',
      room: '',
      ticket: 'SKY H201',
      transfer: 'Van 3',
      notes: 'Pendiente alojamiento.',
      status: WorkerStatus.transfer,
    ),
    Worker(
      id: '3',
      rut: '18.222.111-7',
      firstName: 'Luis',
      lastName: 'Díaz',
      company: 'AVA',
      role: 'Eléctrico',
      project: 'Faena Sur',
      shift: '7x7',
      supervisor: 'María Rojas',
      city: 'Linares',
      phone: '+56 9 3333 3333',
      email: 'luis.diaz@demo.cl',
      emergencyContact: 'Carolina Díaz',
      emergencyPhone: '+56 9 5555 3333',
      hotel: 'Hotel Norte',
      room: '115',
      ticket: '',
      transfer: '',
      notes: 'Pasaje pendiente.',
      status: WorkerStatus.lodging,
    ),
  ];

  void _persist() {
    DatabaseService.instance.writeList(
      'logifaena_workers',
      _workers.map((item) => item.toJson()).toList(),
    );
  }

  @override
  List<Worker> getAll() => List.unmodifiable(_workers);

  @override
  void add(Worker worker) {
    _workers.add(worker);
    _persist();
  }

  @override
  void addAll(List<Worker> workers) {
    if (workers.isEmpty) return;
    _workers.addAll(workers);
    _persist();
  }

  @override
  ({int created, int updated}) importAll(
    List<Worker> workers, {
    required bool updateExisting,
  }) {
    var created = 0;
    var updated = 0;
    for (final worker in workers) {
      final normalizedRut = worker.rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
      final index = _workers.indexWhere((item) =>
          item.rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase() == normalizedRut);
      if (updateExisting && index != -1) {
        _workers[index] = worker;
        updated++;
      } else {
        _workers.add(worker);
        created++;
      }
    }
    _persist();
    return (created: created, updated: updated);
  }

  @override
  void update(Worker worker) {
    final index = _workers.indexWhere((item) => item.id == worker.id);
    if (index != -1) {
      _workers[index] = worker;
      _persist();
    }
  }

  @override
  void delete(String id) {
    _workers.removeWhere((worker) => worker.id == id);
    _persist();
  }
}
