class SyncStatistics {
  const SyncStatistics({
    required this.pending,
    required this.sending,
    required this.completed,
    required this.failed,
  });

  const SyncStatistics.empty()
    : pending = 0,
      sending = 0,
      completed = 0,
      failed = 0;

  final int pending;
  final int sending;
  final int completed;
  final int failed;

  int get total => pending + sending + completed + failed;

  bool get hasProblems => failed > 0;
  bool get hasPendingWork => pending > 0 || sending > 0;
}
