
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book_model.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.book,
  });

  final BookModel book;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  PdfViewerController? _controller;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: _showControls
          ? AppBar(
              title: Text(
                widget.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: 'Toggle controls',
                  onPressed: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  icon: const Icon(Icons.visibility_off),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfViewer.file(
                widget.book.filePath,
                controller: _controller,
                params: PdfViewerParams(
                  onDocumentChanged: (document) {
                    if (!mounted) return;
                    setState(() {
                      _totalPages = document?.pages.length ?? 0;
                    });
                  },
                  onPageChanged: (pageNumber) {
                    if (!mounted || pageNumber == null) return;
                    setState(() {
                      _currentPage = pageNumber;
                    });
                    ref
                        .read(libraryProvider.notifier)
                        .updateLastReadPage(
                          widget.book.id,
                          pageNumber,
                        );
                  },
                ),
              ),
            ),
            if (_showControls)
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: SafeArea(
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Previous page',
                            onPressed: () {
                              if (_currentPage > 1) {
                                _controller?.goToPage(
                                  pageNumber: _currentPage - 1,
                                );
                              }
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Page $_currentPage'
                                '${_totalPages > 0 ? ' of $_totalPages' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next page',
                            onPressed: () {
                              if (_totalPages == 0 ||
                                  _currentPage < _totalPages) {
                                _controller?.goToPage(
                                  pageNumber: _currentPage + 1,
                                );
                              }
                            },
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
      ),
    );
  }
}
