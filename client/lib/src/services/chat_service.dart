import 'dart:convert';

import 'package:client/src/config/http_config.dart';
import 'package:client/src/models/chat_view.dart';
import 'package:client/src/models/extended_chat.dart';
import 'package:client/src/services/api_client.dart';

import '../config/storage_config.dart';

class ChatServiceException extends ApiException {
  const ChatServiceException(String message, {int? statusCode})
    : super(
        message: message,
        code: statusCode == null ? 'chat_error' : 'http_error',
        statusCode: statusCode,
      );
}

class ChatService {
  final ApiClient _client = apiClient;

  Future<String> checkForAuthorize() async {
    final token = await secureStorage.read(key: "token");
    if (token == null || token.isEmpty) {
      throw ChatServiceException("You are not authenticated.");
    }

    return token;
  }

  Future<List<ChatView>> getUserChats() async {
    final token = await checkForAuthorize();
    final response = await _client.get(
      Uri.parse(ApiRoutes.getUserChats),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes).trim();
      var message = 'Failed to load your chats.';
      try {
        final data = apiClient.decodeJson(body);
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
      throw ChatServiceException(message, statusCode: response.statusCode);
    }

    // Some servers use 204 to indicate that the user has no chats.
    final responseBody = utf8.decode(response.bodyBytes).trim();
    if (response.statusCode == 204 || responseBody.isEmpty) {
      return <ChatView>[];
    }

    try {
      final data = apiClient.decodeJson(responseBody);
      if (data is! List) {
        throw const FormatException('Invalid chats response.');
      }

      return data.map<ChatView>((item) {
        if (item is! Map) {
          throw const FormatException('Invalid chat response.');
        }
        return ChatView.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on FormatException catch (error) {
      throw ChatServiceException(error.message);
    } on TypeError {
      throw const ChatServiceException('Invalid chat response.');
    }
  }

  Future<ExtendedChat> getChatById(String chatId) async {
    final token = await checkForAuthorize();
    final response = await _client.get(
      Uri.parse(ApiRoutes.getChatById(chatId)),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes).trim();
      var message = 'Failed to load chat.';
      try {
        final data = apiClient.decodeJson(body);
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
      throw ChatServiceException(message, statusCode: response.statusCode);
    }

    try {
      final data = apiClient.decodeJson(utf8.decode(response.bodyBytes));
      if (data is! Map) {
        throw const FormatException('Invalid chat response.');
      }
      return ExtendedChat.fromJson(Map<String, dynamic>.from(data));
    } on FormatException catch (error) {
      throw ChatServiceException(error.message);
    } on TypeError {
      throw const ChatServiceException('Invalid chat response.');
    }
  }

  Future<void> updateChat({
    required String chatId,
    required String name,
    required String description,
  }) async {
    final token = await checkForAuthorize();
    final response = await _client.post(
      Uri.parse(ApiRoutes.updateChat(chatId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'description': description}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = utf8.decode(response.bodyBytes).trim();
    var message = 'Failed to update chat.';
    try {
      final data = apiClient.decodeJson(body);
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
    throw ChatServiceException(message, statusCode: response.statusCode);
  }
}
