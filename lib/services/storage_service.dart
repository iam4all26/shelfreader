import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/book_model.dart';

class StorageService {
  static Future<Directory> _root() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory root = Directory(p.join(base.path, 'shelf_reader'));
    await Directory(p.join(root.path, 'books')).create(recursive: true);
    await Directory(p.join(root.path, 'covers')).create(recursive: true);
    return root;
  }

  static Future<File> _catalog() async => File(p.join((await _root()).path, 'library.json'));

  static Future<List<Book>> loadBooks() async {
    final File file = await _catalog();
    if (!await file.exists()) return <Book>[];
    try {
      final dynamic decoded = jsonDecode(await file.readAsString());
      if (decoded is! List<dynamic>) return <Book>[];
      final List<Book> books = decoded.whereType<Map<String, dynamic>>().map(Book.fromJson).toList();
      return books.where((Book book) => File(book.pdfPath).existsSync()).toList();
    } catch (_) { return <Book>[]; }
  }

  static Future<void> saveBooks(List<Book> books) async {
    final File file = await _catalog();
    await file.writeAsString(jsonEncode(books.map((Book book) => book.toJson()).toList()), flush: true);
  }

  static Future<String> importPdf(String sourcePath, String id) async {
    final Directory root = await _root();
    final String target = p.join(root.path, 'books', '$id.pdf');
    await File(sourcePath).copy(target);
    return target;
  }

  static Future<void> deleteBookFiles(Book book) async {
    final File pdf = File(book.pdfPath);
    if (await pdf.exists()) await pdf.delete();
    final String? coverPath = book.coverPath;
    if (coverPath != null) {
      final File cover = File(coverPath);
      if (await cover.exists()) await cover.delete();
    }
  }
}
