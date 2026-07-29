import 'dart:convert';

import 'package:http/http.dart' as http;

import 'pending_sync_operation.dart';
import 'sync_transport.dart';

typedef AccessTokenProvider = Future<String?> Function();

class HttpSyncTransport implements SyncTransport {
  HttpSyncTransport({
    required this.baseUrl,
    http.Client? client,
    this.accessTokenProvider,
    this.endpointPath = '/api/sync',
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String endpointPath;
  final Duration timeout;
  final AccessTokenProvider? accessTokenProvider;

  final http.Client _client;

  Uri get _endpoint {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedPath = endpointPath.startsWith('/')
        ? endpointPath
        : '/$endpointPath';

    return Uri.parse('$normalizedBaseUrl$normalizedPath');
  }

  @override
  Future<void> send(PendingSyncOperation operation) async {
    final token = await accessTokenProvider?.call();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };

    http.Response response;

    try {
      response = await _client
          .post(
            _endpoint,
            headers: headers,
            body: jsonEncode(operation.toJson()),
          )
          .timeout(timeout);
    } on Exception catch (error) {
      throw HttpSyncException(
        message: 'No fue posible conectar con el servidor.',
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpSyncException(
        message: 'El servidor rechazó la operación.',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  void close() {
    _client.close();
  }
}

class HttpSyncException implements Exception {
  const HttpSyncException({
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
