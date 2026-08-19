import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/sync/http_sync_transport.dart';
import '../../../core/sync/sync_transport_factory.dart';
import '../domain/worker.dart';
import 'worker_repository.dart';

class HttpWorkerChangesService {
  HttpWorkerChangesService({
    SyncTransportConfig? config,
    http.Client? client,
    this._accessTokenProvider,
  }) : _config = config ?? SyncTransportConfig.fromEnvironment(),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final SyncTransportConfig _config;
  final http.Client _client;
  final bool _ownsClient;
  final AccessTokenProvider? _accessTokenProvider;

  DateTime? _lastServerTimeUtc;

  DateTime? get lastServerTimeUtc => _lastServerTimeUtc;

  Future<({int created, int updated, int deleted})> downloadChanges() async {
    final baseUrl = _config.apiBaseUrl.trim();

    if (baseUrl.isEmpty) {
      throw StateError(
        'LOGIFAENA_API_BASE_URL es obligatorio para descargar trabajadores.',
      );
    }

    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final uri = Uri.parse('$normalizedBaseUrl/api/workers/changes').replace(
      queryParameters: _lastServerTimeUtc == null
          ? null
          : <String, String>{
              'since': _lastServerTimeUtc!.toUtc().toIso8601String(),
            },
    );

    final token = await _accessTokenProvider?.call();

    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };

    http.Response response;

    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(_config.timeout);
    } on Exception catch (error) {
      throw HttpWorkerChangesException(
        message: 'No fue posible descargar los trabajadores.',
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpWorkerChangesException(
        message: 'El servidor rechazó la descarga de trabajadores.',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const HttpWorkerChangesException(
        message: 'La respuesta del servidor no tiene el formato esperado.',
      );
    }

    final serverTimeValue = decoded['serverTimeUtc'];
    final workersValue = decoded['workers'];

    if (serverTimeValue is! String) {
      throw const HttpWorkerChangesException(
        message: 'La respuesta no contiene serverTimeUtc.',
      );
    }

    if (workersValue is! List) {
      throw const HttpWorkerChangesException(
        message: 'La respuesta no contiene una lista de trabajadores.',
      );
    }

    final deletedIds = workersValue
        .whereType<Map>()
        .where((value) => value['isDeleted'] == true)
        .map(
          (value) =>
              Map<String, dynamic>.from(value)['externalId']?.toString() ?? '',
        )
        .where((value) => value.isNotEmpty)
        .toSet();

    final activeWorkers = workersValue
        .whereType<Map>()
        .where((value) => value['isDeleted'] != true)
        .map((value) => Worker.fromJson(Map<String, dynamic>.from(value)))
        .toList();

    final result = InMemoryWorkerRepository.instance.applyServerChanges(
      activeWorkers,
      deletedIds: deletedIds,
    );

    _lastServerTimeUtc = DateTime.parse(serverTimeValue).toUtc();

    return result;
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class HttpWorkerChangesException implements Exception {
  const HttpWorkerChangesException({
    required this.message,
    this.statusCode,
    this.responseBody,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final String? responseBody;
  final Object? cause;

  @override
  String toString() {
    final parts = <String>[message];

    if (statusCode != null) {
      parts.add('Código HTTP: $statusCode.');
    }

    if (responseBody != null && responseBody!.trim().isNotEmpty) {
      parts.add('Respuesta: ${responseBody!.trim()}');
    }

    if (cause != null) {
      parts.add('Causa: $cause');
    }

    return parts.join(' ');
  }
}
