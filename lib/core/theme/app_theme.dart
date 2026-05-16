import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  AppTheme._();

  static const Color fundaOrange = Color(0xFFF7A100);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  }
}
