import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'config.dart';
import 'providers/library_provider.dart';
import 'screens/library_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  final books = await StorageService.loadBooks();
  runApp(ProviderScope(
    overrides: [libraryProvider.overrideWith((ref) => books)],
    child: const ShelfReaderApp(),
  ));
}

class ShelfReaderApp extends StatelessWidget {
  const ShelfReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primary),
        scaffoldBackgroundColor: const Color(0xFFF7F3EC),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F3EC)),
        cardTheme: CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primary, brightness: Brightness.dark),
        scaffoldBackgroundColor: AppConfig.darkBackground,
      ),
      home: const LibraryScreen(),
    );
  }
}
