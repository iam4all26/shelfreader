import 'package:flutter/material.dart';

/// THE ONLY FILE MOST USERS NEED TO CUSTOMIZE.
class AppConfig {
  AppConfig._();

  static const String appName = 'ShelfReader';
  static const String tagline = 'Your books. Your space. Always offline.';
  static const Color primary = Color(0xFF7351FF);
  static const Color accent = Color(0xFFF6C101);
  static const Color lightBackground = Color(0xFFF7F6FC);
  static const Color darkBackground = Color(0xFF151321);
  static const Color darkSurface = Color(0xFF211E31);
  static const String defaultReadingTheme = 'Light';
  static const bool showReadingStats = true;
  static const bool enableCustomShelves = true;
  static const List<String> defaultCategories = <String>[
    'Education', 'Islamic', 'Business', 'Technology', 'Novels', 'Reference', 'Other',
  ];
  static const List<String> readingThemes = <String>[
    'Light', 'Dark', 'Sepia', 'Warm',
  ];
}
