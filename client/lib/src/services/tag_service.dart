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
      throw TagServiceException(message: 'Failed to load tags.');
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
