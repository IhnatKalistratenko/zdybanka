import 'dart:convert';

import 'package:client/src/config/http_config.dart';
import 'package:client/src/models/event.dart';
import 'package:client/src/models/event_boundary_request.dart';
import 'package:client/src/models/event_marker.dart';
import 'package:client/src/models/event_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../config/storage_config.dart';
import '../services/auth_aware_http_client.dart';
import '../models/create_event_request.dart';

class EventServiceException implements Exception {
  final String message;
  final int? statusCode;

  const EventServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class EventService {
  final http.Client _client;

  EventService({http.Client? client})
    : _client = client == null ? httpClient : AuthAwareHttpClient(client);

  Future<String> checkForAuthorize() async {
    final token = await secureStorage.read(key: "token");
    if (token == null || token.isEmpty) {
      throw EventServiceException("You are not authenticated.");
    }

    return token;
  }

  Future<void> createEvent(CreateEventRequest request) async {
    final token = await checkForAuthorize();

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

    if (response.statusCode >= 200 && response.statusCode < 300) {
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

    throw EventServiceException(message, statusCode: response.statusCode);
  }

  Future<void> deleteEvent(String eventId) async {
    final token = await checkForAuthorize();
    final response = await _client
        .delete(
          Uri.parse('${ApiRoutes.createEventRoute}/$eventId'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EventServiceException(
        'Failed to delete event.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> joinEvent(String eventId) async {
    final token = await checkForAuthorize();
    final response = await _client
        .post(
          Uri.parse('${ApiRoutes.createEventRoute}/$eventId/join'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = utf8.decode(response.bodyBytes).trim();
    var message = 'Failed to join event.';
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        for (final key in ['error', 'message', 'title', 'detail']) {
          final value = data[key];
          if (value is String && value.trim().isNotEmpty) {
            message = value.trim();
            break;
          }
        }
      } else if (data is String && data.trim().isNotEmpty) {
        message = data.trim();
      }
    } on FormatException {
      if (body.isNotEmpty) message = body;
    }

    throw EventServiceException(message, statusCode: response.statusCode);
  }

  Future<void> leaveEvent(String eventId) async {
    final token = await checkForAuthorize();
    final response = await _client
        .post(
          Uri.parse(ApiRoutes.leaveEventRoute(eventId)),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = utf8.decode(response.bodyBytes).trim();
    var message = 'Failed to leave event.';
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        for (final key in ['error', 'message', 'title', 'detail']) {
          final value = data[key];
          if (value is String && value.trim().isNotEmpty) {
            message = value.trim();
            break;
          }
        }
      } else if (data is String && data.trim().isNotEmpty) {
        message = data.trim();
      }
    } on FormatException {
      if (body.isNotEmpty) message = body;
    }

    throw EventServiceException(message, statusCode: response.statusCode);
  }

  Future<Event> getEventById(String eventId) async {
    final token = await checkForAuthorize();
    final response = await _client
        .get(
          Uri.parse('${ApiRoutes.createEventRoute}/$eventId'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EventServiceException(
        'Failed to load event.',
        statusCode: response.statusCode,
      );
    }

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid event response.');
      }
      return Event.fromJson(data);
    } on FormatException catch (error) {
      throw EventServiceException(error.message);
    }
  }

  Future<void> updateEvent(String eventId, CreateEventRequest request) async {
    final token = await checkForAuthorize();
    final response = await _client
        .put(
          Uri.parse('${ApiRoutes.createEventRoute}/$eventId'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': request.name,
            'description': request.description,
            'address': request.address,
            'status': 'Active',
            'startTime': request.startTime.toUtc().toIso8601String(),
            'endTime': request.endTime.toUtc().toIso8601String(),
            'maxParticipants': request.maxParticipants,
            'latitude': request.latitude,
            'longitude': request.longitude,
            'tagIds': request.tagIds
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes).trim();
      var message = 'Failed to update event.';
      try {
        final data = jsonDecode(body);
        if (data is Map) {
          for (final key in ['error', 'message', 'title', 'detail']) {
            final value = data[key];
            if (value is String && value.trim().isNotEmpty) {
              message = value.trim();
              break;
            }
          }
        }
      } on FormatException {
        if (body.isNotEmpty) message = body;
      }
      throw EventServiceException(message, statusCode: response.statusCode);
    }
  }

  Future<List<Event>> getEvents(EventQuery queryParams) async {
    final token = await checkForAuthorize();
    final response = await _client.get(
      Uri.parse(ApiRoutes.buildGetEventsFromQuery(queryParams)),
      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Failed to load events.';
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          for (final key in ['error', 'message', 'title', 'detail']) {
            final value = data[key];
            if (value is String && value.trim().isNotEmpty) {
              errorMessage = value.trim();
              break;
            }
          }
        } else if (data is String && data.trim().isNotEmpty) {
          errorMessage = data.trim();
        }
      } on FormatException {
        if (response.body.trim().isNotEmpty) {
          errorMessage = response.body.trim();
        }
      }
      throw EventServiceException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }

    try {
      final data = jsonDecode(response.body);
      if (data is! List) {
        throw const FormatException('Invalid events response.');
      }

      return data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid event response.');
        }
        return Event.fromJson(item);
      }).toList();
    } on FormatException catch (error) {
      throw EventServiceException(error.message);
    }
  }

  Future<List<Event>> getMyEvents() async {
    final token = await checkForAuthorize();
    final response = await _client
        .get(
          Uri.parse(ApiRoutes.myEventsRoute),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes).trim();
      var message = 'Failed to load your events.';
      try {
        final data = jsonDecode(body);
        if (data is Map) {
          for (final key in ['error', 'message', 'title', 'detail']) {
            final value = data[key];
            if (value is String && value.trim().isNotEmpty) {
              message = value.trim();
              break;
            }
          }
        }
      } on FormatException {
        if (body.isNotEmpty) message = body;
      }
      throw EventServiceException(message, statusCode: response.statusCode);
    }

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint("Received data: $data");
      if (data is! List) {
        throw const FormatException('Expected a list of events.');
      }
      return data.map<Event>((item) {
        if (item is! Map) {
          throw const FormatException('Expected an event object.');
        }
        return Event.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on FormatException catch (error) {
      throw EventServiceException(error.message);
    } on TypeError {
      throw const EventServiceException('Invalid event response.');
    }
  }

  Future<List<EventMarker>> getEventsPosition(
    EventBoundaryRequest query,
  ) async {
    final token = await checkForAuthorize();
    final response = await _client
        .get(
          Uri.parse(ApiRoutes.buildGetEventsInBoundaries(query)),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Failed to load events in bounds.';
      try {
        final data = jsonDecode(body);
        if (data is Map) {
          for (final key in ['error', 'message', 'title', 'detail']) {
            final value = data[key];
            if (value is String && value.trim().isNotEmpty) {
              message = value.trim();
              break;
            }
          }
        } else if (data is String && data.trim().isNotEmpty) {
          message = data.trim();
        }
      } on FormatException {
        if (body.trim().isNotEmpty) message = body.trim();
      }
      throw EventServiceException(message, statusCode: response.statusCode);
    }

    try {
      final data = jsonDecode(body);
      if (data is! List) {
        throw const FormatException('Invalid events in bounds response.');
      }

      return data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid event marker response.');
        }
        return EventMarker.fromJson(item);
      }).toList();
    } on FormatException catch (error) {
      throw EventServiceException(error.message);
    }
  }
}
