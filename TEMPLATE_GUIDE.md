# ShelfReader Guide
ShelfReader is an offline-first PDF bookshelf and reader with a warm, realistic wooden-shelf library. Import individual PDF files or scan a selected folder, automatically generate book covers from each PDF's first page, organize books into collections, and continue reading from the last saved page.

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

## Options explained
| Option | What it does |
|---|---|
| `appName` | Name displayed in the app header and app identity. |
| `tagline` | Short product tagline for future onboarding or about screens. |
| `primary` | Main brand color used by Material controls. |
| `accent` | Highlight color used for primary shelf actions and progress. |
| `lightBackground` | Light-mode base background color. |
| `darkBackground` | Dark-mode base background color. |
| `darkSurface` | Dark-mode surface color for future panels. |
| `defaultReadingTheme` | Initial PDF reader theme: Light, Dark, Sepia or Warm. |
| `showReadingStats` | Retained configuration flag for reading statistics. |
| `enableCustomShelves` | Retained configuration flag for custom collections. |
| `defaultCategories` | Suggested category names for organizing imported books. |
| `readingThemes` | Theme choices available in the reader. |

## Using the template
1. Tap **Add PDF** to choose one or more PDF files.
2. Choose **Import from folder** to select a folder. ShelfReader scans that folder and its subfolders for `.pdf` files and imports the PDFs it can access.
3. Imported PDFs are copied into the app's private storage. A cover image is generated from the first page of each PDF; no manual cover upload is required.
4. Tap any book cover to open the PDF reader directly. Use the three-dot book menu for title/author edits, details, collection changes, sharing, opening the PDF with another app, or deletion.
5. Change page type and reading theme from the controls inside the reader. Settings also stores the default reading preferences.
6. Use bookmarks and the page controls to navigate, then return later to continue from the last saved page.

## Folder import notes
- Folder import is a user-initiated operation through the Android system folder picker.
- PDFs are discovered recursively within the selected folder. Other file types are ignored.
- The app imports accessible files only; files behind cloud-only placeholders or provider restrictions may not be readable until downloaded by the file provider.
- Duplicate detection avoids importing a PDF when its source path or title already exists in the library. Files with the same title in different folders may therefore be treated as duplicates.

## Storage and privacy
- Imported PDFs, generated cover PNGs and the library catalogue are stored locally under the app's private documents directory.
- The library does not require an account, backend, analytics SDK or internet connection for its core reading features.
- Sharing a PDF intentionally sends the selected file to the Android share sheet. Opening with another app hands the PDF to the Android app chosen by the user.
- Uninstalling the app normally removes its private files. This starter does not provide cloud backup.
- Automatic category suggestions are filename keyword guesses and can be changed by editing book information.

## Build notes
- The template intentionally has no `android/` directory and no GitHub Actions workflow. K-Git Studio supplies the Android project and build workflow.
- Dependencies include pdfrx, file_picker, path_provider, path, Riverpod, image, share_plus, cross_file, open_filex and uuid.
- Use Flutter 3.47 / Dart 3.13 or later for the selected pdfrx release.
- `app_permissions.txt` is intentionally empty. The system file and folder pickers grant access to user-selected content; ShelfReader copies imported PDFs into app-private storage.
