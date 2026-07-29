import 'sync_queue_service.dart';
import 'sync_statistics.dart';
import 'sync_status.dart';

class SyncStatisticsService {
  SyncStatisticsService._();

  static final SyncStatisticsService instance = SyncStatisticsService._();

  final SyncQueueService _queue = SyncQueueService.instance;

  SyncStatistics load() {
    return SyncStatistics(
      pending: _queue.getByStatus(SyncStatus.pending).length,
      sending: _queue.getByStatus(SyncStatus.sending).length,
      completed: _queue.getByStatus(SyncStatus.completed).length,
      failed: _queue.getByStatus(SyncStatus.failed).length,
    );
  }
}
