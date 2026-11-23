import 'dart:convert';

import 'package:client/src/config/http_config.dart';
import 'package:client/src/config/storage_config.dart';
import 'package:client/src/models/register_request.dart';
import 'package:http/http.dart' as http;

import '../models/login_request.dart';

class AuthServiceException implements Exception
{
  final String message;
  AuthServiceException({required this.message});
}

class AuthService
{

  AuthService();

  Future<void> login(LoginRequest request) async {
    Uri loginUrl = Uri.parse(ApiRoutes.loginRoute);
    var body = {
      "username": request.username,
      "password": request.password
    };
    http.Response response = await httpClient.post(loginUrl,
        body: jsonEncode(body),
        headers: {
          "Content-Type": "application/json"
        }).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);

    if(response.statusCode != 200) {
      throw AuthServiceException(message: data["error"]);
    }

    final token = data["token"] as String;
    await secureStorage.write(key: "token", value: token);

    final userId = _userIdFromToken(token);
    if (userId == null) {
      await secureStorage.delete(key: userIdStorageKey);
    } else {
      await secureStorage.write(key: userIdStorageKey, value: userId);
    }
  }

  String? _userIdFromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
      final payload = jsonDecode(utf8.decode(payloadBytes));
      if (payload is! Map) return null;

      const nameIdentifierClaim =
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
      final claim = payload[nameIdentifierClaim] ??
          payload['nameid'] ??
          payload['sub'] ??
          payload['user_id'] ??
          payload['userId'];

      if (claim is String && claim.trim().isNotEmpty) return claim;
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }


  Future<void> register(RegisterRequest request) async {
    final response = await httpClient
        .post(
      Uri.parse(ApiRoutes.registerRoute),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": request.username,
        "password": request.password,
      }),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      return;
    }

    String message = "Registration failed. Please try again.";

    try {
      final data = jsonDecode(response.body);

      if (data is Map && data["error"] is String) {
        message = data["error"] as String;
      }
    } on FormatException {
      // Keep the default error message.
    }

    throw AuthServiceException(message: message);
  }

  Future<void> logout() async {
    await secureStorage.delete(key: "token");
    await secureStorage.delete(key: userIdStorageKey);
  }

}