import 'dart:convert';

import 'package:client/src/config/http_config.dart';
import 'package:client/src/config/storage_config.dart';
import 'package:client/src/models/register_request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

    final storage = FlutterSecureStorage();

    await storage.write(key: "token", value: data["token"] as String);
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

  Future<void> logout() {
    return secureStorage.delete(key: "token");
  }

}