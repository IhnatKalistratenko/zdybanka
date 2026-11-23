import 'dart:convert';

import 'package:client/src/config/http_config.dart';
import 'package:client/src/models/event_tag.dart';

class TagServiceException implements Exception {
  final String message;

  TagServiceException({required this.message});

  @override
  String toString() => message;
}

class TagService {
  Future<List<EventTag>> getTags() async {
    final response = await httpClient
        .get(
          Uri.parse(ApiRoutes.tagsRoute),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      var message = 'Failed to load tags.';
      try {
        final body = jsonDecode(response.body);
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
        if (response.body.trim().isNotEmpty) {
          message = response.body.trim();
        }
      }
      throw TagServiceException(message: message);
    }

    try {
      final data = jsonDecode(response.body);
      if (data is! List) {
        throw const FormatException('Invalid tags response.');
      }

      return data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid tag response.');
        }
        return EventTag.fromJson(item);
      }).toList();
    } on FormatException catch (error) {
      throw TagServiceException(message: error.message);
    }
  }
}
