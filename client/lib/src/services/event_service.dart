
import 'dart:convert';

import 'package:http/http.dart' as http;

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
  final Uri createEventUri;
  final http.Client _client;

  EventService({
    required this.createEventUri,
    http.Client? client,
  }) : _client = client ?? http.Client();


  // Todo: підігнати логіку надсилання та обробки помилок під API.
  Future<void> createEvent(CreateEventRequest request) async {
    final response = await _client.post(
      createEventUri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String message = 'Failed to create event';

    try {
      final body = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (body is Map<String, dynamic>) {
        final error = body['error'];
        final serverMessage = body['message'];

        if (error is String && error.isNotEmpty) {
          message = error;
        } else if (serverMessage is String &&
            serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      }
    } catch (_) {
    }

    throw EventServiceException(
      message,
      statusCode: response.statusCode,
    );
  }
}
