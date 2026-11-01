
import 'dart:convert';

import 'package:client/src/config/http_config.dart';
import 'package:http/http.dart' as http;

import '../config/storage_config.dart';
import '../services/auth_aware_http_client.dart';
import '../models/create_event_request.dart';

class EventServiceException implements Exception {
  final String message;
  final int? statusCode;

  const EventServiceException(
      this.message, {
        this.statusCode,
      });

  @override
  String toString() => message;
}

class EventService {
  final http.Client _client;

  EventService({
    http.Client? client,
  }) : _client = client == null
           ? httpClient
           : AuthAwareHttpClient(client);


  Future<void> createEvent(CreateEventRequest request) async {
    final token = await secureStorage.read(key: "token");
    if (token == null || token.isEmpty) {
      throw EventServiceException("You are not authenticated.");
    }

    final response = await _client
        .post(
          Uri.parse(ApiRoutes.createEventRoute),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    final responseBody = utf8.decode(response.bodyBytes).trim();
    String message = 'Failed to create event.';

    if (responseBody.isNotEmpty) {
      message = responseBody;
    }

    try {
      final body = jsonDecode(responseBody);

      if (body is Map) {
        for (final key in ['error', 'message', 'title', 'detail']) {
          final value = body[key];
          if (value is String && value.trim().isNotEmpty) {
            message = value.trim();
            break;
          }
        }
      } else if (body is String && body.trim().isNotEmpty) {
        message = body.trim();
      }
    } on FormatException {
      // Keep the raw response body for plain text server errors.
    }

    throw EventServiceException(
      message,
      statusCode: response.statusCode,
    );
  }
}
