import 'package:http/http.dart' as http;

import 'http_sync_transport.dart';
import 'simulated_sync_transport.dart';
import 'sync_transport.dart';

enum SyncTransportMode { simulated, http }

class SyncTransportConfig {
  const SyncTransportConfig({
    required this.mode,
    this.apiBaseUrl = '',
    this.endpointPath = '/api/sync',
    this.timeout = const Duration(seconds: 20),
  });

  factory SyncTransportConfig.fromEnvironment() {
    const modeValue = String.fromEnvironment(
      'LOGIFAENA_SYNC_MODE',
      defaultValue: 'simulated',
    );

    const apiBaseUrl = String.fromEnvironment(
      'LOGIFAENA_API_BASE_URL',
      defaultValue: '',
    );

    const endpointPath = String.fromEnvironment(
      'LOGIFAENA_SYNC_ENDPOINT',
      defaultValue: '/api/sync',
    );

    final mode = modeValue.toLowerCase() == 'http'
        ? SyncTransportMode.http
        : SyncTransportMode.simulated;

    return SyncTransportConfig(
      mode: mode,
      apiBaseUrl: apiBaseUrl,
      endpointPath: endpointPath,
    );
  }

  final SyncTransportMode mode;
  final String apiBaseUrl;
  final String endpointPath;
  final Duration timeout;
}

class SyncTransportFactory {
  const SyncTransportFactory._();

  static SyncTransport create({
    SyncTransportConfig? config,
    http.Client? httpClient,
    AccessTokenProvider? accessTokenProvider,
  }) {
    final resolvedConfig = config ?? SyncTransportConfig.fromEnvironment();

    switch (resolvedConfig.mode) {
      case SyncTransportMode.simulated:
        return const SimulatedSyncTransport();

      case SyncTransportMode.http:
        final baseUrl = resolvedConfig.apiBaseUrl.trim();

        if (baseUrl.isEmpty) {
          throw StateError(
            'LOGIFAENA_API_BASE_URL es obligatorio cuando '
            'LOGIFAENA_SYNC_MODE=http.',
          );
        }

        return HttpSyncTransport(
          baseUrl: baseUrl,
          endpointPath: resolvedConfig.endpointPath,
          timeout: resolvedConfig.timeout,
          client: httpClient,
          accessTokenProvider: accessTokenProvider,
        );
    }
  }
}
