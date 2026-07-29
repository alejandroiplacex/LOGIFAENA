import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logifaena_master/src/core/sync/sync_result.dart';
import 'package:logifaena_master/src/core/sync/sync_statistics.dart';
import 'package:logifaena_master/src/features/settings/presentation/widgets/sync_queue_status.dart';

void main() {
  testWidgets('muestra las estadísticas de la cola', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncQueueStatus(
            statisticsLoader: () => const SyncStatistics(
              pending: 3,
              sending: 1,
              completed: 8,
              failed: 2,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Fallidas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Sincronizar ahora'), findsOneWidget);
  });

  testWidgets('ejecuta el motor al presionar sincronizar', (tester) async {
    var executions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncQueueStatus(
            statisticsLoader: () => const SyncStatistics.empty(),
            syncRunner: () async {
              executions++;
              final now = DateTime.utc(2026, 1, 1);
              return SyncRunResult(
                startedAt: now,
                finishedAt: now,
                total: 1,
                completed: 1,
                failed: 0,
                skipped: 0,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sincronizar ahora'));
    await tester.pumpAndSettle();

    expect(executions, 1);
    expect(find.textContaining('1 completada'), findsOneWidget);
  });
}
