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
    await tester.pumpWidget(
      MaterialApp(
        home: SyncCenterScreen(
          operationsLoader: () => operations,
          auditLoader: () => const <AuditEntry>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('worker Ã‚· update'), findsOneWidget);
    expect(find.textContaining('ticket Ã‚· create'), findsOneWidget);

    await tester.tap(find.text('Fallidas'));
    await tester.pumpAndSettle();

    expect(find.textContaining('worker Ã‚· update'), findsNothing);
    expect(find.textContaining('ticket Ã‚· create'), findsOneWidget);
  });

  testWidgets('reintenta una operaciÃƒÂ³n fallida', (tester) async {
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
