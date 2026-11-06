# ShelfReader Guide
ShelfReader is an offline-first PDF bookshelf and reader. Import PDF books, add personal covers, organize them into categories and shelves, bookmark pages, and resume reading from the last saved page without an internet connection.

## The one file to edit
`lib/config.dart`

```dart
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
```

## Using the template
1. Import one or more PDF files with **Add books**. The app copies each PDF into its private app storage so it remains available offline.
2. Open a book, add a cover image, and edit its title, author, category, shelf and description.
3. Tap **Start reading**. Reading progress is saved as pages change; use the page controls to navigate directly.
4. Use the bookmark icon to save important pages. The bookmarks menu lists saved pages.
5. Change the reader theme or layout from the reader controls or Settings.

## Storage and privacy
- PDFs, covers and the library catalogue are stored locally under the app's private documents directory.
- No account, server, analytics SDK or network permission is required.
- Uninstalling the app normally removes its private files. This starter does not provide cloud backup or export yet.
- Duplicate detection currently compares normalized book titles, not file contents.
- Automatic category suggestions are filename keyword guesses and can be changed by editing a book.

## Build notes
- The template intentionally has no `android/` directory and no GitHub Actions workflow. K-Git Studio supplies the Android project and build workflow.
- Dependencies include pdfrx (PDFium-based PDF rendering), file_picker, path_provider, path and Riverpod.
- Use Flutter 3.47 / Dart 3.13 or later for the selected pdfrx release.
- `app_permissions.txt` is intentionally empty. The system file picker grants access to user-selected files; imported files are copied into app-private storage.
