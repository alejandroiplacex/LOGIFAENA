import '../../../core/database/database_service.dart';
import '../domain/import_history.dart';

class ImportHistoryRepository {
  ImportHistoryRepository._() {
    final saved = DatabaseService.instance.readList('logifaena_import_history');
    _items.addAll(saved.map(ImportHistory.fromJson));
  }

  static final ImportHistoryRepository instance = ImportHistoryRepository._();

  final List<ImportHistory> _items = [];

  List<ImportHistory> getAll() => List.unmodifiable(_items.reversed);

  void add(ImportHistory history) {
    _items.add(history);
    DatabaseService.instance.writeList(
      'logifaena_import_history',
      _items.map((item) => item.toJson()).toList(),
    );
  }
}
