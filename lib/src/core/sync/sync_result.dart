class SyncRunResult {
  const SyncRunResult({
    required this.startedAt,
    required this.finishedAt,
    required this.total,
    required this.completed,
    required this.failed,
    required this.skipped,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final int total;
  final int completed;
  final int failed;
  final int skipped;

  bool get hasFailures => failed > 0 || skipped > 0;
  Duration get duration => finishedAt.difference(startedAt);
}
