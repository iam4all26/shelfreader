import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../config.dart';
import '../models/book_model.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({super.key, required this.bookId});
  final String bookId;
  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late final PdfViewerController _controller;
  int _page = 1;
  bool _controlsVisible = true;
  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    final Book? book = ref.read(libraryProvider).where((Book b) => b.id == widget.bookId).firstOrNull;
    _page = book?.lastPage ?? 1;
  }

  Color _background(String theme) => switch (theme) {
    'Dark' => const Color(0xFF171717),
    'Sepia' => const Color(0xFFF0E2C6),
    'Warm' => const Color(0xFFFFEBCB),
    _ => const Color(0xFFF4F3EF),
  };

  Color _foreground(String theme) => theme == 'Dark' ? Colors.white : const Color(0xFF29251F);

  Future<void> _savePage(int? page) async {
    if (page == null || page < 1 || page == _page) return;
    _page = page;
    final List<Book> updated = ref.read(libraryProvider).map((Book b) => b.id == widget.bookId ? b.copyWith(lastPage: page, pagesRead: b.pagesRead + (page > b.lastPage ? 1 : 0), totalPages: _controller.isReady ? _controller.pageCount : b.totalPages) : b).toList();
    ref.read(libraryProvider.notifier).state = updated;
    await persistLibrary(updated);
    if (mounted) setState(() {});
  }

  Future<void> _goToPage() async {
    final TextEditingController input = TextEditingController(text: '$_page');
    final int? requested = await showDialog<int>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Go to page'),
      content: TextField(controller: input, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Page number')),
      actions: <Widget>[TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, int.tryParse(input.text)), child: const Text('Go'))],
    ));
    input.dispose();
    if (requested != null && _controller.isReady && requested >= 1 && requested <= _controller.pageCount) await _controller.goToPage(pageNumber: requested);
  }

  Future<void> _toggleBookmark(Book book) async {
    final List<int> marks = List<int>.of(book.bookmarks);
    if (marks.contains(_page)) { marks.remove(_page); } else { marks.add(_page); marks.sort(); }
    final List<Book> updated = ref.read(libraryProvider).map((Book b) => b.id == book.id ? b.copyWith(bookmarks: marks) : b).toList();
    ref.read(libraryProvider.notifier).state = updated;
    await persistLibrary(updated);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(marks.contains(_page) ? 'Page bookmarked' : 'Bookmark removed')));
  }

  @override
  Widget build(BuildContext context) {
    final Book? book = ref.watch(libraryProvider).where((Book b) => b.id == widget.bookId).firstOrNull;
    if (book == null || !File(book.pdfPath).existsSync()) return const Scaffold(body: Center(child: Text('This PDF file is missing.')));
    final String theme = ref.watch(readingThemeProvider);
    final String mode = ref.watch(readingModeProvider);
    final Color pageBackground = _background(theme);
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: _controlsVisible ? AppBar(
        backgroundColor: pageBackground, foregroundColor: _foreground(theme), title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
        actions: <Widget>[
          IconButton(tooltip: 'Bookmark page', onPressed: () => _toggleBookmark(book), icon: Icon(book.bookmarks.contains(_page) ? Icons.bookmark : Icons.bookmark_border)),
          PopupMenuButton<String>(onSelected: (String value) {
            if (value == 'bookmarks') showModalBottomSheet<void>(context: context, builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, children: book.bookmarks.isEmpty ? const <Widget>[ListTile(title: Text('No bookmarks yet'))] : book.bookmarks.map((int page) => ListTile(leading: const Icon(Icons.bookmark), title: Text('Page $page'), onTap: () { Navigator.pop(ctx); _controller.goToPage(pageNumber: page); })).toList())));
          }, itemBuilder: (_) => const <PopupMenuEntry<String>>[PopupMenuItem(value: 'bookmarks', child: Text('My bookmarks'))]),
        ],
      ) : null,
      body: GestureDetector(
        onTap: () => setState(() => _controlsVisible = !_controlsVisible),
        child: Stack(children: <Widget>[
          PdfViewer.file(book.pdfPath, controller: _controller, initialPageNumber: book.lastPage, params: PdfViewerParams(
            backgroundColor: pageBackground,
            margin: 12,
            onPageChanged: _savePage,
            pageImageColorFilter: theme == 'Warm' ? const ColorFilter.mode(Color(0x18D99A35), BlendMode.srcOver) : null,
            scrollPhysics: mode == 'Page focus' ? const PageScrollPhysics() : const BouncingScrollPhysics(),
          )),
          if (_controlsVisible) Positioned(left: 12, right: 12, bottom: 12, child: SafeArea(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: theme == 'Dark' ? const Color(0xEE282536) : Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(18), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black12, blurRadius: 14)]),
            child: Row(children: <Widget>[
              IconButton(onPressed: _controller.isReady && _page > 1 ? () => _controller.goToPage(pageNumber: _page - 1) : null, icon: const Icon(Icons.chevron_left)),
              Expanded(child: TextButton(onPressed: _goToPage, child: Text('Page $_page${_controller.isReady ? ' / ${_controller.pageCount}' : ''}', style: TextStyle(color: _foreground(theme), fontWeight: FontWeight.bold)))),
              IconButton(onPressed: _controller.isReady && _page < _controller.pageCount ? () => _controller.goToPage(pageNumber: _page + 1) : null, icon: const Icon(Icons.chevron_right)),
              PopupMenuButton<String>(tooltip: 'Reading options', icon: const Icon(Icons.tune), onSelected: (String value) {
                if (AppConfig.readingThemes.contains(value)) ref.read(readingThemeProvider.notifier).state = value;
                if (value == 'Continuous' || value == 'Page focus') ref.read(readingModeProvider.notifier).state = value;
              }, itemBuilder: (_) => <PopupMenuEntry<String>>[
                const PopupMenuItem(value: 'Continuous', child: Text('Continuous scrolling')),
                const PopupMenuItem(value: 'Page focus', child: Text('Page focus')),
                const PopupMenuDivider(),
                for (final String value in AppConfig.readingThemes) PopupMenuItem(value: value, child: Row(children: <Widget>[Text(value), if (theme == value) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check, size: 16))])),
              ]),
            ]),
          ))),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
