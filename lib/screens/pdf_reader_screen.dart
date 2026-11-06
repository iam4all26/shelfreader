
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book_model.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.bookId,
  });

  final String bookId;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late final PdfViewerController _controller;

  int _currentPage = 1;
  int _totalPages = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  void _updateBook({
    int? lastPage,
    int? totalPages,
  }) {
    final List<Book> books = ref.read(libraryProvider);
    final int index = books.indexWhere(
      (Book book) => book.id == widget.bookId,
    );

    if (index == -1) return;

    final Book currentBook = books[index];

    final Book updatedBook = currentBook.copyWith(
      lastPage: lastPage,
      totalPages: totalPages,
    );

    if (updatedBook.lastPage == currentBook.lastPage &&
        updatedBook.totalPages == currentBook.totalPages) {
      return;
    }

    final List<Book> updatedBooks = List<Book>.of(books);
    updatedBooks[index] = updatedBook;

    ref.read(libraryProvider.notifier).state = updatedBooks;

    unawaited(persistLibrary(updatedBooks));
  }

  @override
  Widget build(BuildContext context) {
    final List<Book> books = ref.watch(libraryProvider);

    final Book? book = books
        .where((Book item) => item.id == widget.bookId)
        .firstOrNull;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reader')),
        body: const Center(
          child: Text('This book could not be found in your library.'),
        ),
      );
    }

    final String readingTheme = ref.watch(readingThemeProvider);

    Color backgroundColor;

    switch (readingTheme) {
      case 'Dark':
        backgroundColor = const Color(0xFF171717);
        break;
      case 'Sepia':
        backgroundColor = const Color(0xFFF0E2C5);
        break;
      case 'Warm':
        backgroundColor = const Color(0xFFFFEBCB);
        break;
      default:
        backgroundColor = const Color(0xFFF5F5F5);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: _showControls ? 'Hide controls' : 'Show controls',
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            icon: Icon(
              _showControls
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PdfViewer.file(
              book.pdfPath,
              controller: _controller,
              initialPageNumber: book.lastPage < 1 ? 1 : book.lastPage,
              params: PdfViewerParams(
                onDocumentChanged: (document) {
                  if (!mounted || document == null) return;

                  final int pageCount = document.pages.length;

                  setState(() {
                    _totalPages = pageCount;
                  });

                  _updateBook(totalPages: pageCount);
                },
                onPageChanged: (pageNumber) {
                  if (!mounted || pageNumber == null) return;

                  setState(() {
                    _currentPage = pageNumber;
                  });

                  _updateBook(lastPage: pageNumber);
                },
              ),
            ),
          ),

          if (readingTheme == 'Warm')
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x18FFC66D),
                ),
              ),
            ),

          if (_showControls)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Previous page',
                          onPressed: _currentPage > 1
                              ? () {
                                  _controller.goToPage(
                                    pageNumber: _currentPage - 1,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),

                        Expanded(
                          child: Center(
                            child: Text(
                              'Page $_currentPage'
                              '${_totalPages > 0 ? ' of $_totalPages' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),

                        IconButton(
                          tooltip: 'Next page',
                          onPressed: _totalPages > 0 &&
                                  _currentPage < _totalPages
                              ? () {
                                  _controller.goToPage(
                                    pageNumber: _currentPage + 1,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
