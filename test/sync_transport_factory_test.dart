import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logifaena_master/src/core/sync/http_sync_transport.dart';
import 'package:logifaena_master/src/core/sync/simulated_sync_transport.dart';
import 'package:logifaena_master/src/core/sync/sync_transport_factory.dart';

void main() {
  test('crea transporte simulado', () {
    final transport = SyncTransportFactory.create(
      config: const SyncTransportConfig(mode: SyncTransportMode.simulated),
    );

    expect(transport, isA<SimulatedSyncTransport>());
  });

  test('crea transporte HTTP', () {
    final client = MockClient((request) async {
      return http.Response('', 204);
    });

    final transport = SyncTransportFactory.create(
      config: const SyncTransportConfig(
        mode: SyncTransportMode.http,
        apiBaseUrl: 'https://api.logifaena.cl',
      ),
      httpClient: client,
    );

    expect(transport, isA<HttpSyncTransport>());

    (transport as HttpSyncTransport).close();
  });

  test('rechaza modo HTTP sin URL del servidor', () {
    expect(
      () => SyncTransportFactory.create(
        config: const SyncTransportConfig(mode: SyncTransportMode.http),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('LOGIFAENA_API_BASE_URL'),
        ),
      ),
    );
  });

  test('el modo predeterminado del entorno es simulado', () {
    final config = SyncTransportConfig.fromEnvironment();

    expect(config.mode, SyncTransportMode.simulated);
  });
}
