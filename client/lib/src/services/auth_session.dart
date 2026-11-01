import 'package:client/src/config/storage_config.dart';

class AuthSession {
  static Future<void> Function()? _onUnauthorized;
  static bool _isHandlingUnauthorized = false;

  static void configure({required Future<void> Function() onUnauthorized}) {
    _onUnauthorized = onUnauthorized;
  }

  static Future<void> handleUnauthorized() async {
    if (_isHandlingUnauthorized) return;

    _isHandlingUnauthorized = true;
    try {
      await secureStorage.delete(key: 'token');
      await _onUnauthorized?.call();
    } finally {
      _isHandlingUnauthorized = false;
    }
  }
}
