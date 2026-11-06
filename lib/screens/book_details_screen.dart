import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../providers/library_provider.dart';
import '../services/cover_service.dart';
import '../services/storage_service.dart';
import 'pdf_reader_screen.dart';

class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.bookId});
  final String bookId;

  Future<void> _edit(BuildContext context, WidgetRef ref, Book book) async {
    final TextEditingController title = TextEditingController(text: book.title);
    final TextEditingController author = TextEditingController(text: book.author);
    final TextEditingController shelf = TextEditingController(text: book.shelf);
    final TextEditingController description = TextEditingController(text: book.description);
    final TextEditingController category = TextEditingController(text: book.category);
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Edit book details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Book title')),
        TextField(controller: author, decoration: const InputDecoration(labelText: 'Author')),
        TextField(controller: shelf, decoration: const InputDecoration(labelText: 'Shelf name')),
        TextField(controller: category, decoration: const InputDecoration(labelText: 'Category', hintText: 'Enter or create a category')),
        TextField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 18),
        FilledButton(onPressed: () async {
          final List<Book> updated = ref.read(libraryProvider).map((Book b) => b.id == book.id ? b.copyWith(title: title.text.trim().isEmpty ? b.title : title.text.trim(), author: author.text.trim(), shelf: shelf.text.trim().isEmpty ? 'My Books' : shelf.text.trim(), category: category.text.trim().isEmpty ? 'Other' : category.text.trim(), description: description.text.trim()) : b).toList();
          ref.read(libraryProvider.notifier).state = updated;
          await persistLibrary(updated);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        }, child: const Text('Save changes')),
      ])),
    ));
    title.dispose(); author.dispose(); shelf.dispose(); description.dispose(); category.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Book? book = ref.watch(libraryProvider).where((Book b) => b.id == bookId).firstOrNull;
    if (book == null) return const Scaffold(body: Center(child: Text('Book not found')));
    return Scaffold(
      appBar: AppBar(title: const Text('Book details'), actions: <Widget>[IconButton(onPressed: () => _edit(context, ref, book), icon: const Icon(Icons.edit_outlined))]),
      body: ListView(padding: const EdgeInsets.all(22), children: <Widget>[
        Center(child: Container(width: 180, height: 245, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Theme.of(context).colorScheme.primaryContainer, image: book.coverPath != null && File(book.coverPath!).existsSync() ? DecorationImage(image: FileImage(File(book.coverPath!)), fit: BoxFit.cover) : null), child: book.coverPath == null ? const Icon(Icons.picture_as_pdf, size: 72) : null)),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: () async {
          final picked = await CoverService.pickCover();
          if (picked?.path == null) return;
          final coverPath = await StorageService.importCover(picked!.path!, book.id);
          final updated = ref.read(libraryProvider).map((Book b) => b.id == book.id ? b.copyWith(coverPath: coverPath) : b).toList();
          ref.read(libraryProvider.notifier).state = updated;
          await persistLibrary(updated);
        }, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Add or change cover')),
        const SizedBox(height: 18),
        Text(book.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        Text(book.author, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 18),
        Wrap(spacing: 8, alignment: WrapAlignment.center, children: <Widget>[Chip(label: Text(book.category)), Chip(label: Text(book.shelf)), Chip(label: Text('${book.lastPage} / ${book.totalPages == 0 ? '—' : book.totalPages} pages'))]),
        if (book.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(book.description)),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(bookId: book.id))), icon: const Icon(Icons.menu_book), label: Text(book.lastPage > 1 ? 'Continue from page ${book.lastPage}' : 'Start reading')),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () => _edit(context, ref, book), icon: const Icon(Icons.edit_outlined), label: const Text('Edit book information')),
        TextButton.icon(onPressed: () async {
          final bool? confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Remove this book?'), content: const Text('The imported PDF and its cover will be deleted from this app.'), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove'))]));
          if (confirm != true || !context.mounted) return;
          final List<Book> updated = ref.read(libraryProvider).where((Book b) => b.id != book.id).toList();
          ref.read(libraryProvider.notifier).state = updated;
          await persistLibrary(updated);
          await StorageService.deleteBookFiles(book);
          if (context.mounted) Navigator.pop(context);
        }, icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Remove book', style: TextStyle(color: Colors.red))),
      ]),
    );
  }
}
