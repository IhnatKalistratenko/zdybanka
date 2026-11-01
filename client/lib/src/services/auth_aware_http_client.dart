import 'package:http/http.dart' as http;

import 'auth_session.dart';

class AuthAwareHttpClient extends http.BaseClient {
  final http.Client _innerClient;

  AuthAwareHttpClient([http.Client? innerClient])
    : _innerClient = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _innerClient.send(request);
    if (response.statusCode == 401) {
      await AuthSession.handleUnauthorized();
    }
    return response;
  }

  @override
  void close() {
    _innerClient.close();
  }
}
