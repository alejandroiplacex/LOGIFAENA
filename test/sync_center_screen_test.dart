import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logifaena_master/src/core/sync/audit_entry.dart';
import 'package:logifaena_master/src/core/sync/pending_sync_operation.dart';
import 'package:logifaena_master/src/core/sync/sync_status.dart';
import 'package:logifaena_master/src/features/sync/presentation/sync_center_screen.dart';

void main() {
  final operations = [
    PendingSyncOperation(
      id: 1,
      entityType: 'worker',
      entityId: 'W-001',
      operation: 'update',
      payload: const {'name': 'Alejandro'},
      createdAt: DateTime.utc(2026, 7, 27, 12),
      status: SyncStatus.pending,
    ),
    PendingSyncOperation(
      id: 2,
      entityType: 'ticket',
      entityId: 'T-002',
      operation: 'create',
      payload: const {'route': 'Talca-Calama'},
      createdAt: DateTime.utc(2026, 7, 27, 13),
      attempts: 2,
      status: SyncStatus.failed,
    ),
  ];

  testWidgets('muestra y filtra operaciones por estado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SyncCenterScreen(
          operationsLoader: () => operations,
          auditLoader: () => const <AuditEntry>[],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('worker'), findsOneWidget);
    expect(find.textContaining('update'), findsOneWidget);
    expect(find.textContaining('ticket'), findsOneWidget);
    expect(find.textContaining('create'), findsOneWidget);

    final horizontalScroll = find.byType(SingleChildScrollView);

    expect(horizontalScroll, findsOneWidget);

    await tester.drag(
      horizontalScroll,
      const Offset(-600, 0),
    );

    await tester.pumpAndSettle();

    final failedFilter = find.text('Fallidas');

    expect(failedFilter, findsOneWidget);

    await tester.tap(failedFilter);
    await tester.pumpAndSettle();

    expect(find.textContaining('worker'), findsNothing);
    expect(find.textContaining('update'), findsNothing);
    expect(find.textContaining('ticket'), findsOneWidget);
    expect(find.textContaining('create'), findsOneWidget);
  });

  testWidgets('reintenta una operación fallida', (tester) async {
    var retriedId = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SyncCenterScreen(
          operationsLoader: () => operations,
          auditLoader: () => const <AuditEntry>[],
          retryOperation: (id) async => retriedId = id,
          auditRecorder:
              ({required action, required entityType, details}) async => 1,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Reintentar'));
    await tester.pumpAndSettle();

    expect(retriedId, 2);
  });
}