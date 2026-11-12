import 'package:flutter/material.dart';

/// Shared color palette for the client application.
abstract final class AppColors {
  static const Color primary = Color(0xFF3478F6);
  static const Color secondary = Color(0xFF52627A);
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF448AFF);

  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textMuted = Color(0xFF8A96A8);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color surfaceTint = Colors.transparent;
  static const Color border = Color(0xFFE5EAF1);
  static const Color disabled = Color(0xFFE0E0E0);

  static const Color primarySurface = Color(0xFFEDF3FF);
  static const Color chatBubble = Color(0xFFF0F3F8);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryMuted = Colors.white70;
  static const Color onDark = Colors.black;

  // Map marker colors retain MaterialColor types required by the map API.
  static const MaterialColor markerWarning = Colors.amber;
  static const MaterialColor markerPrimary = Colors.blue;
  static const MaterialColor markerNeutral = Colors.grey;
  static const MaterialColor markerError = Colors.red;
  static const Color location = Colors.white;
  static const Color destructive = Colors.redAccent;
}
