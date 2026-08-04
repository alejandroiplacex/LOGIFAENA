import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logifaena_master/src/core/sync/http_sync_transport.dart';
import 'package:logifaena_master/src/core/sync/pending_sync_operation.dart';
import 'package:logifaena_master/src/core/sync/sync_status.dart';

void main() {
  final operation = PendingSyncOperation(
    id: 10,
    entityType: 'worker',
    entityId: 'W-010',
    operation: 'update',
    payload: const {'name': 'Alejandro'},
    createdAt: DateTime.utc(2026, 7, 29, 12),
    status: SyncStatus.pending,
  );

  test('envía una operación al servidor correctamente', () async {
    late http.Request capturedRequest;

    final client = MockClient((request) async {
      capturedRequest = request;

      return http.Response(
        jsonEncode({'success': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final transport = HttpSyncTransport(
      baseUrl: 'https://api.logifaena.cl',
      client: client,
      accessTokenProvider: () async => 'token-prueba',
    );

    await transport.send(operation);

    expect(
  capturedRequest.url.toString(),
  'https://api.logifaena.cl/api/sync',
);

    expect(capturedRequest.method, 'POST');

    expect(capturedRequest.headers['authorization'], 'Bearer token-prueba');

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

    expect(body['entityType'], 'worker');
    expect(body['entityId'], 'W-010');
    expect(body['operation'], 'update');
  });

  test('lanza excepción cuando el servidor rechaza la operación', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'message': 'Operación rechazada'}),
        500,
        headers: {'content-type': 'application/json'},
      );
    });

    final transport = HttpSyncTransport(
      baseUrl: 'https://api.logifaena.cl',
      client: client,
    );

    expect(
      () => transport.send(operation),
      throwsA(
        isA<HttpSyncException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having(
              (error) => error.responseBody,
              'responseBody',
              contains('Operación rechazada'),
            ),
      ),
    );
  });

  test('permite configurar una ruta diferente', () async {
    late Uri capturedUrl;

    final client = MockClient((request) async {
      capturedUrl = request.url;
      return http.Response('', 204);
    });

    final transport = HttpSyncTransport(
      baseUrl: 'https://api.logifaena.cl/',
      endpointPath: 'api/v1/sync',
      client: client,
    );

    await transport.send(operation);

    expect(capturedUrl.toString(), 'https://api.logifaena.cl/api/v1/sync');
  });
}
