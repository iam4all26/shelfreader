import 'package:flutter_riverpod/legacy.dart';
import '../models/book_model.dart';
import '../services/storage_service.dart';

final StateProvider<List<Book>> libraryProvider = StateProvider<List<Book>>((ref) => <Book>[]);

Future<void> persistLibrary(List<Book> books) => StorageService.saveBooks(books);
