import 'dart:convert';

import 'package:client/src/config/http_config.dart';
import 'package:client/src/config/storage_config.dart';
import 'package:client/src/models/user.dart';
import 'package:client/src/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserServiceException extends ApiException {
  UserServiceException({required String message})
    : super(message: message, code: 'user_error');
}

class UserService {
  Future<User> getUser() async {
    final FlutterSecureStorage storage = secureStorage;
    final token = await storage.read(key: "token");

    if (token == null || token.isEmpty) {
      throw UserServiceException(message: "You are not authenticated.");
    }

    final response = await apiClient.get(
      Uri.parse(ApiRoutes.userRoute),
      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw UserServiceException(message: "Failed to load user information.");
    }

    final data = apiClient.decodeJson(response.body);
    if (data is! Map<String, dynamic>) {
      throw UserServiceException(message: "Invalid user information response.");
    }

    try {
      return User.fromJson(data);
    } on FormatException catch (error) {
      throw UserServiceException(message: error.message);
    }
  }

  Future<User> updateUsername({
    required String userId,
    required String username,
  }) async {
    final token = await secureStorage.read(key: "token");
    if (token == null || token.isEmpty) {
      throw UserServiceException(message: "You are not authenticated.");
    }

    final response = await apiClient.patch(
      Uri.parse(ApiRoutes.userByIdRoute(userId)),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "newPassword": null,
        "currentPassword": null,
      }),
    );

    if (response.statusCode != 200) {
      String message = "Failed to update username.";
      try {
        final data = apiClient.decodeJson(response.body);
        if (data is Map && data["error"] is String) {
          message = data["error"] as String;
        }
      } on FormatException {
        // Keep the fallback error message for non-JSON responses.
      }
      throw UserServiceException(message: message);
    }

    final data = apiClient.decodeJson(response.body);
    if (data is! Map<String, dynamic>) {
      throw UserServiceException(message: "Invalid user information response.");
    }

    try {
      return User.fromJson(data);
    } on FormatException catch (error) {
      throw UserServiceException(message: error.message);
    }
  }

  Future<void> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await secureStorage.read(key: "token");
    if (token == null || token.isEmpty) {
      throw UserServiceException(message: "You are not authenticated.");
    }

    final response = await apiClient.patch(
      Uri.parse(ApiRoutes.userByIdRoute(userId)),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "confirmPassword": currentPassword,
        "newPassword": newPassword,
      }),
    );

    if (response.statusCode != 200) {
      String message = "Failed to update password.";
      try {
        final data = apiClient.decodeJson(response.body);
        if (data is Map && data["error"] is String) {
          message = data["error"] as String;
        }
      } on FormatException {
        // Keep the fallback for empty or non-JSON error responses.
      }
      throw UserServiceException(message: message);
    }
  }
}
