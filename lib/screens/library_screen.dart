import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../config.dart';
import '../models/book_model.dart';
import '../providers/library_provider.dart';
import '../services/cover_service.dart';
import '../services/pdf_import_service.dart';
import '../services/storage_service.dart';
import '../widgets/bookshelf.dart';
import 'book_details_screen.dart';
import 'pdf_reader_screen.dart';
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

  Future<void> _showImportOptions() async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheetContext) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 22), child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      const Align(alignment: Alignment.centerLeft, child: Text('Add books to your library', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19))),
      const SizedBox(height: 10),
      ListTile(leading: const CircleAvatar(child: Icon(Icons.picture_as_pdf_outlined)), title: const Text('Choose PDF files'), subtitle: const Text('Select one or more PDFs'), onTap: () { Navigator.pop(sheetContext); _importFiles(); }),
      ListTile(leading: const CircleAvatar(child: Icon(Icons.folder_open_outlined)), title: const Text('Import from folder'), subtitle: const Text('Choose a folder and find PDFs inside it'), onTap: () { Navigator.pop(sheetContext); _importFolder(); }),
    ]))));
  }

  Future<void> _importFiles() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await PdfImportService.pickPdfs();
      await _saveImportedFiles(files.map((f) => f.path).whereType<String>().toList());
    } catch (error) { if (mounted) _message('Import failed: $error'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _importFolder() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await PdfImportService.pickPdfsFromFolder();
      await _saveImportedFiles(files.map((f) => f.path).toList());
    } catch (error) { if (mounted) _message('Could not read that folder: $error'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _saveImportedFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    final List<Book> updated = List<Book>.of(ref.read(libraryProvider));
    int added = 0;
    for (final String source in paths) {
      final File sourceFile = File(source);
      if (!await sourceFile.exists() || !source.toLowerCase().endsWith('.pdf')) continue;
      final String filename = p.basenameWithoutExtension(source);
      final bool duplicate = updated.any((Book b) => b.pdfPath.toLowerCase() == source.toLowerCase() || b.title.toLowerCase() == filename.toLowerCase());
      if (duplicate) continue;
      final String id = const Uuid().v4();
      final String savedPath = await StorageService.importPdf(source, id);
      final String? coverPath = await CoverService.generateFromPdf(savedPath, id);
      updated.insert(0, Book(id: id, title: filename, pdfPath: savedPath, addedAt: DateTime.now(), coverPath: coverPath, category: _suggestCategory(filename)));
      added++;
    }
    if (added > 0) {
      ref.read(libraryProvider.notifier).state = updated;
      await persistLibrary(updated);
    }
    if (mounted) _message(added == 0 ? 'No new PDF files were imported.' : '$added PDF book(s) added to your shelf.');
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

  void _openBook(Book book) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(bookId: book.id)));

  Future<void> _showBookMenu(Book book) async {
    final String? action = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit title and author'), onTap: () => Navigator.pop(ctx, 'edit')),
      ListTile(leading: Icon(book.isFavorite ? Icons.favorite : Icons.favorite_border), title: Text(book.isFavorite ? 'Remove from favorites' : 'Add to favorites'), onTap: () => Navigator.pop(ctx, 'favorite')),
      ListTile(leading: const Icon(Icons.info_outline), title: const Text('View book details'), onTap: () => Navigator.pop(ctx, 'details')),
      ListTile(leading: const Icon(Icons.drive_file_move_outline), title: const Text('Move to collection'), onTap: () => Navigator.pop(ctx, 'move')),
      ListTile(leading: const Icon(Icons.ios_share_outlined), title: const Text('Share PDF'), onTap: () => Navigator.pop(ctx, 'share')),
      ListTile(leading: const Icon(Icons.folder_open_outlined), title: const Text('Open PDF with another app'), onTap: () => Navigator.pop(ctx, 'file')),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Delete book', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(ctx, 'delete')),
      const SizedBox(height: 10),
    ])));
    if (!mounted || action == null) return;
    if (action == 'edit') await _editBook(book);
    if (action == 'favorite') { final list = ref.read(libraryProvider).map((b) => b.id == book.id ? b.copyWith(isFavorite: !b.isFavorite) : b).toList(); ref.read(libraryProvider.notifier).state = list; await persistLibrary(list); }
    if (action == 'details') await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BookDetailsScreen(bookId: book.id)));
    if (action == 'move') await _moveBook(book);
    if (action == 'share') await SharePlus.instance.share(ShareParams(files: <XFile>[XFile(book.pdfPath)], text: book.title));
    if (action == 'file') await OpenFilex.open(book.pdfPath);
    if (action == 'delete') await _deleteBook(book);
  }

  Future<void> _editBook(Book book) async {
    final title = TextEditingController(text: book.title);
    final author = TextEditingController(text: book.author);
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Edit book information'), content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')), TextField(controller: author, decoration: const InputDecoration(labelText: 'Author'))]), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final list = ref.read(libraryProvider).map((b) => b.id == book.id ? b.copyWith(title: title.text.trim().isEmpty ? b.title : title.text.trim(), author: author.text.trim()) : b).toList(); ref.read(libraryProvider.notifier).state = list; await persistLibrary(list); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))]));
    title.dispose(); author.dispose();
  }

  Future<void> _moveBook(Book book) async {
    final shelves = ref.read(libraryProvider).map((b) => b.shelf).toSet().toList()..add('New collection…');
    final String? selected = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(title: const Text('Move to collection'), children: shelves.map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Text(s))).toList()));
    if (selected == null) return;
    String destination = selected;
    if (selected == 'New collection…') {
      final input = TextEditingController();
      destination = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('New collection'), content: TextField(controller: input, autofocus: true, decoration: const InputDecoration(hintText: 'Collection name')), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, input.text.trim()), child: const Text('Create'))])) ?? '';
      input.dispose();
    }
    if (destination.trim().isEmpty) return;
    final list = ref.read(libraryProvider).map((b) => b.id == book.id ? b.copyWith(shelf: destination) : b).toList();
    ref.read(libraryProvider.notifier).state = list; await persistLibrary(list);
  }

  Future<void> _deleteBook(Book book) async {
    final bool yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete this book?'), content: const Text('The PDF and its generated cover will be removed from ShelfReader storage.'), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))])) ?? false;
    if (!yes) return;
    final list = ref.read(libraryProvider).where((b) => b.id != book.id).toList();
    ref.read(libraryProvider.notifier).state = list; await persistLibrary(list); await StorageService.deleteBookFiles(book);
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(libraryProvider);
    final visible = books.where((b) => '${b.title} ${b.author} ${b.category} ${b.shelf}'.toLowerCase().contains(_query.toLowerCase())).toList();
    final favorites = visible.where((b) => b.isFavorite).toList();
    final recent = visible.where((b) => b.lastPage > 1).toList();
    return Scaffold(
      backgroundColor: const Color(0xFF2B180F),
      appBar: AppBar(backgroundColor: const Color(0xFF24140D), foregroundColor: const Color(0xFFFFE8C7), title: Row(children: <Widget>[const Icon(Icons.menu_book_rounded, color: Color(0xFFF6C101)), const SizedBox(width: 9), Text(AppConfig.appName, style: const TextStyle(fontWeight: FontWeight.w800))]), actions: <Widget>[IconButton(tooltip: 'Categories', onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CategoriesScreen())), icon: const Icon(Icons.category_outlined)), IconButton(tooltip: 'Settings', onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.tune_rounded))]),
      body: CustomPaint(painter: _WoodGrainPainter(), child: Column(children: <Widget>[
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: TextField(onChanged: (v) => setState(() => _query = v), style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Search your library', hintStyle: const TextStyle(color: Color(0xFFC9B59C)), prefixIcon: const Icon(Icons.search, color: Color(0xFFE5C69C)), filled: true, fillColor: const Color(0xFF4A2D1B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
        Expanded(child: books.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[const Icon(Icons.auto_stories_rounded, size: 64, color: Color(0xFFD7B58B)), const SizedBox(height: 14), const Text('Your bookshelf is waiting', style: TextStyle(color: Color(0xFFFFE8C7), fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 7), const Text('Add PDF books to fill your shelves.', style: TextStyle(color: Color(0xFFD7B58B))), const SizedBox(height: 18), FilledButton.icon(onPressed: _busy ? null : _showImportOptions, icon: const Icon(Icons.add), label: const Text('Add books'))])) : ListView(padding: const EdgeInsets.only(top: 5, bottom: 24), children: <Widget>[
          if (recent.isNotEmpty) Bookshelf(title: 'Continue reading', books: recent, onBookTap: _openBook, onBookMenu: _showBookMenu),
          if (_tab == 1) Bookshelf(title: 'Favorite books', books: favorites, onBookTap: _openBook, onBookMenu: _showBookMenu)
          else for (final shelf in visible.map((b) => b.shelf).toSet()) Bookshelf(title: shelf, books: visible.where((b) => b.shelf == shelf).toList(), onBookTap: _openBook, onBookMenu: _showBookMenu),
          if (_query.isNotEmpty && visible.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Text('No books found.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
        ])),
      ])),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: AppConfig.accent, foregroundColor: const Color(0xFF2D1A0F), onPressed: _busy ? null : _showImportOptions, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add), label: Text(_busy ? 'Importing…' : 'Add PDF')),
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (v) => setState(() => _tab = v), destinations: const <NavigationDestination>[NavigationDestination(icon: Icon(Icons.library_books_outlined), label: 'Library'), NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favorites')]),
    );
  }
}


class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint base = Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF4A2B19), Color(0xFF2D190F), Color(0xFF1E100A)]).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);
    final Paint grain = Paint()..color = const Color(0xFFB27A48).withValues(alpha: .10)..strokeWidth = 1;
    for (int i = 0; i < 42; i++) {
      final double y = (i * 37.0) % (size.height + 20);
      final Path path = Path()..moveTo(0, y);
      path.cubicTo(size.width * .28, y - 5, size.width * .62, y + 7, size.width, y - 2);
      canvas.drawPath(path, grain);
    }
    final Paint seams = Paint()..color = Colors.black.withValues(alpha: .18)..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * .48, 0), Offset(size.width * .48, size.height), seams);
    canvas.drawLine(Offset(size.width * .49 + 2, 0), Offset(size.width * .49 + 2, size.height), grain);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
