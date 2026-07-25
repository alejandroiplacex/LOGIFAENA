import '../models/operation.dart';

abstract class OperationRepository {
  List<Operation> getAll();
  Operation? getById(String id);
  Operation? getActive();
  void save(Operation operation);
  void delete(String id);
  void setActive(String id);
}

class InMemoryOperationRepository implements OperationRepository {
  InMemoryOperationRepository._();

  static final InMemoryOperationRepository instance =
      InMemoryOperationRepository._();

  final List<Operation> _operations = <Operation>[];
  String? _activeOperationId;

  @override
  List<Operation> getAll() => List<Operation>.unmodifiable(_operations);

  @override
  Operation? getById(String id) {
    for (final operation in _operations) {
      if (operation.id == id) return operation;
    }
    return null;
  }

  @override
  Operation? getActive() =>
      _activeOperationId == null ? null : getById(_activeOperationId!);

  @override
  void save(Operation operation) {
    final index = _operations.indexWhere((item) => item.id == operation.id);
    if (index == -1) {
      _operations.add(operation);
    } else {
      _operations[index] = operation;
    }
    _activeOperationId ??= operation.id;
  }

  @override
  void delete(String id) {
    _operations.removeWhere((item) => item.id == id);
    if (_activeOperationId == id) {
      _activeOperationId =
          _operations.isEmpty ? null : _operations.first.id;
    }
  }

  @override
  void setActive(String id) {
    if (getById(id) == null) {
      throw StateError('No existe una operación con id $id.');
    }
    _activeOperationId = id;
  }
}
