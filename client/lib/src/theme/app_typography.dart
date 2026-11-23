import 'package:flutter/material.dart';

/// Shared text styles for headings, body copy, labels, and supporting text.
abstract final class AppTypography {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle headingMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle headingSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(fontSize: 15, height: 1.4);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16);
  static const TextStyle bodySmall = TextStyle(fontSize: 14, height: 1.5);
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(fontSize: 12);
  static const TextStyle overline = TextStyle(fontSize: 11);
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: headingLarge,
    headlineLarge: headingMedium,
    headlineMedium: headingSmall,
    headlineSmall: title,
    titleLarge: titleMedium,
    titleMedium: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: button,
    labelMedium: label,
    labelSmall: caption,
  );
}
