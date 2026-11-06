import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../config.dart';
import '../models/book_model.dart';
import '../providers/library_provider.dart';
import '../services/pdf_import_service.dart';
import '../services/storage_service.dart';
import '../widgets/bookshelf.dart';
import '../widgets/empty_library.dart';
import '../widgets/reading_progress.dart';
import 'book_details_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _tab = 0;
  String _query = '';
  bool _busy = false;

  Future<void> _importBooks() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final List<PlatformFile> files = await PdfImportService.pickPdfs();
      final List<Book> current = ref.read(libraryProvider);
      final List<Book> updated = List<Book>.of(current);
      for (final PlatformFile picked in files) {
        final String? source = picked.path;
        if (source == null || !File(source).existsSync()) continue;
        final String filename = p.basenameWithoutExtension(picked.name);
        final bool duplicate = current.any((Book b) => b.title.toLowerCase() == filename.toLowerCase());
        if (duplicate) continue;
        final String id = const Uuid().v4();
        final String savedPath = await StorageService.importPdf(source, id);
        updated.insert(0, Book(id: id, title: filename, pdfPath: savedPath, addedAt: DateTime.now(), category: _suggestCategory(filename)));
      }
      ref.read(libraryProvider.notifier).state = updated;
      await persistLibrary(updated);
      if (mounted && files.isNotEmpty) _message('${updated.length - current.length} PDF book(s) imported');
    } catch (error) {
      if (mounted) _message('Could not import the selected PDF: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _suggestCategory(String name) {
    final String value = name.toLowerCase();
    if (value.contains('math') || value.contains('science') || value.contains('school') || value.contains('lesson')) return 'Education';
    if (value.contains('quran') || value.contains('islam') || value.contains('hadith') || value.contains('fiqh')) return 'Islamic';
    if (value.contains('business') || value.contains('market') || value.contains('finance')) return 'Business';
    if (value.contains('tech') || value.contains('computer') || value.contains('program')) return 'Technology';
    if (value.contains('novel') || value.contains('story')) return 'Novels';
    return 'Other';
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _openBook(Book book) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BookDetailsScreen(bookId: book.id)));
  }

  Future<void> _toggleFavorite(Book book) async {
    final List<Book> updated = ref.read(libraryProvider).map((Book b) => b.id == book.id ? b.copyWith(isFavorite: !b.isFavorite) : b).toList();
    ref.read(libraryProvider.notifier).state = updated;
    await persistLibrary(updated);
  }

  @override
  Widget build(BuildContext context) {
    final List<Book> books = ref.watch(libraryProvider);
    final List<Book> searched = books.where((Book b) => '${b.title} ${b.author} ${b.category} ${b.shelf}'.toLowerCase().contains(_query.toLowerCase())).toList();
    final List<Book> filtered = _tab == 1 ? searched.where((Book b) => b.isFavorite).toList() : searched;
    final List<Book> recent = filtered.where((Book b) => b.lastPage > 1).toList();
    final int pagesRead = books.fold<int>(0, (int total, Book b) => total + b.pagesRead);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: <Widget>[
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppConfig.primary, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.menu_book_rounded, color: Colors.white)),
          const SizedBox(width: 10), const Text(AppConfig.appName, style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: <Widget>[
          IconButton(tooltip: 'Categories', onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CategoriesScreen())), icon: const Icon(Icons.category_outlined)),
          IconButton(tooltip: 'Settings', onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: _tab == 2 ? const CategoriesScreen() : _tab == 3 ? const SettingsScreen() : Column(children: <Widget>[
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), child: TextField(
          onChanged: (String value) => setState(() => _query = value),
          decoration: InputDecoration(hintText: 'Search your library', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
        )),
        Expanded(child: books.isEmpty ? EmptyLibrary(onImport: _importBooks) : filtered.isEmpty
          ? const Center(child: Text('No books match your search.'))
          : ListView(children: <Widget>[
              if (AppConfig.showReadingStats) ReadingProgress(pagesRead: pagesRead, bookCount: books.length),
              if (recent.isNotEmpty) Bookshelf(title: 'Continue reading', books: recent, onBookTap: _openBook, onFavorite: _toggleFavorite),
              Bookshelf(title: _tab == 1 ? 'Favorite books' : 'My bookshelf', books: filtered, onBookTap: _openBook, onFavorite: _toggleFavorite),
              if (_tab == 0) ...<Widget>[
                for (final String shelf in filtered.map((Book b) => b.shelf).toSet())
                  if (shelf != 'My Books') Bookshelf(title: shelf, books: filtered.where((Book b) => b.shelf == shelf).toList(), onBookTap: _openBook, onFavorite: _toggleFavorite),
              ],
              const SizedBox(height: 28),
            ])),
      ]),
      floatingActionButton: _tab == 0 ? FloatingActionButton.extended(onPressed: _busy ? null : _importBooks, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add), label: Text(_busy ? 'Importing' : 'Add books')) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (int value) => setState(() => _tab = value), destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Library'),
        NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
        NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categories'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ]),
    );
  }
}
