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

  final List<Transfer> _transfers = <Transfer>[];

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
