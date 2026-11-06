import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';
import '../models/book_model.dart';
import 'pdf_reader_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Book> books = ref.watch(libraryProvider);
    final Map<String, List<Book>> groups = <String, List<Book>>{};
    for (final Book book in books) { groups.putIfAbsent(book.category, () => <Book>[]).add(book); }
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: groups.isEmpty ? const Center(child: Text('Your categories will appear when you add books.')) : ListView(padding: const EdgeInsets.all(16), children: groups.entries.map((entry) => Card(child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.folder_outlined)), title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${entry.value.length} books'),
        children: entry.value.map((Book book) => ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: Text(book.title), subtitle: Text(book.author), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(bookId: book.id))))).toList(),
      ))).toList()),

    );
  }
}
