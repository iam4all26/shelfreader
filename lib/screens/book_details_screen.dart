import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../providers/library_provider.dart';
import 'pdf_reader_screen.dart';

class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Book? book = ref.watch(libraryProvider).where((b) => b.id == bookId).firstOrNull;
    if (book == null) return const Scaffold(body: Center(child: Text('Book not found')));
    final bool hasCover = book.coverPath != null && File(book.coverPath!).existsSync();
    return Scaffold(appBar: AppBar(title: const Text('Book details')), body: ListView(padding: const EdgeInsets.all(22), children: <Widget>[
      Center(child: Container(width: 170, height: 235, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(4, 8))], image: hasCover ? DecorationImage(image: FileImage(File(book.coverPath!)), fit: BoxFit.cover) : null, color: Theme.of(context).colorScheme.primaryContainer), child: hasCover ? null : const Icon(Icons.picture_as_pdf, size: 64))),
      const SizedBox(height: 18), Text(book.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      Text(book.author, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 18), Wrap(alignment: WrapAlignment.center, spacing: 8, children: <Widget>[Chip(label: Text(book.category)), Chip(label: Text(book.shelf)), Chip(label: Text('${book.lastPage} / ${book.totalPages == 0 ? '—' : book.totalPages} pages'))]),
      if (book.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(book.description)),
      const SizedBox(height: 22), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(bookId: book.id))), icon: const Icon(Icons.menu_book), label: const Text('Open PDF')),
      const SizedBox(height: 12), const Text('The cover is automatically generated from the first page of the imported PDF.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
    ]));
  }
}
