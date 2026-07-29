import 'pending_sync_operation.dart';

abstract interface class SyncTransport {
  Future<void> send(PendingSyncOperation operation);
}
