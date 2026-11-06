import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/book_model.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({super.key, required this.bookId});
  final String bookId;
  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late final PdfViewerController _controller;
  int _page = 1;
  bool _showControls = true;
  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _page = ref.read(libraryProvider).where((b) => b.id == widget.bookId).firstOrNull?.lastPage ?? 1;
  }

  Color _pageColor(String theme) => switch (theme) { 'Dark' => const Color(0xFF171717), 'Sepia' => const Color(0xFFF0E2C6), 'Warm' => const Color(0xFFFFEBCB), _ => const Color(0xFFF7F5EF) };
  Color _ink(String theme) => theme == 'Dark' ? Colors.white : const Color(0xFF29251F);

  Future<void> _savePage(int? value) async {
    if (value == null || value < 1 || value == _page) return;
    _page = value;
    final list = ref.read(libraryProvider).map((b) => b.id == widget.bookId ? b.copyWith(lastPage: value, pagesRead: b.pagesRead + (value > b.lastPage ? 1 : 0), totalPages: _controller.isReady ? _controller.pageCount : b.totalPages) : b).toList();
    ref.read(libraryProvider.notifier).state = list;
    await persistLibrary(list);
    if (mounted) setState(() {});
  }

  Future<void> _goToPage() async {
    final input = TextEditingController(text: '$_page');
    final requested = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(title: const Text('Go to page'), content: TextField(controller: input, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Page number')), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(input.text)), child: const Text('Go'))]));
    input.dispose();
    if (requested != null && _controller.isReady && requested >= 1 && requested <= _controller.pageCount) _controller.goToPage(pageNumber: requested);
  }

  Future<void> _bookmark(Book book) async {
    final marks = List<int>.of(book.bookmarks);
    if (marks.contains(_page)) { marks.remove(_page); } else { marks.add(_page); marks.sort(); }
    final list = ref.read(libraryProvider).map((b) => b.id == book.id ? b.copyWith(bookmarks: marks) : b).toList();
    ref.read(libraryProvider.notifier).state = list; await persistLibrary(list);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(marks.contains(_page) ? 'Page bookmarked' : 'Bookmark removed')));
  }

  Future<void> _readerOptions(String theme, String mode) async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('Reading settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)), const SizedBox(height: 18),
      const Text('PAGE TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
      RadioListTile<String>(value: 'Continuous', groupValue: mode, title: const Text('Continuous scroll'), secondary: const Icon(Icons.view_day_outlined), onChanged: (v) { if (v != null) ref.read(readingModeProvider.notifier).state = v; Navigator.pop(ctx); }),
      RadioListTile<String>(value: 'Page focus', groupValue: mode, title: const Text('Single page'), secondary: const Icon(Icons.crop_portrait_outlined), onChanged: (v) { if (v != null) ref.read(readingModeProvider.notifier).state = v; Navigator.pop(ctx); }),
      const Divider(), const Text('READING THEME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
      Wrap(spacing: 8, runSpacing: 8, children: <Widget>[for (final value in <String>['Light', 'Dark', 'Sepia', 'Warm']) ChoiceChip(label: Text(value), selected: theme == value, onSelected: (_) { ref.read(readingThemeProvider.notifier).state = value; Navigator.pop(ctx); })]),
    ]))));
  }

  @override
  Widget build(BuildContext context) {
    final Book? book = ref.watch(libraryProvider).where((b) => b.id == widget.bookId).firstOrNull;
    if (book == null || !File(book.pdfPath).existsSync()) return const Scaffold(body: Center(child: Text('This PDF file is missing.')));
    final theme = ref.watch(readingThemeProvider);
    final mode = ref.watch(readingModeProvider);
    final bg = _pageColor(theme);
    return Scaffold(backgroundColor: bg, appBar: _showControls ? AppBar(backgroundColor: bg, foregroundColor: _ink(theme), title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)), actions: <Widget>[IconButton(tooltip: 'Bookmark this page', onPressed: () => _bookmark(book), icon: Icon(book.bookmarks.contains(_page) ? Icons.bookmark : Icons.bookmark_border)), PopupMenuButton<String>(onSelected: (v) { if (v == 'bookmarks') showModalBottomSheet<void>(context: context, builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, children: book.bookmarks.isEmpty ? const <Widget>[ListTile(title: Text('No bookmarks yet'))] : book.bookmarks.map((p) => ListTile(leading: const Icon(Icons.bookmark), title: Text('Page $p'), onTap: () { Navigator.pop(ctx); _controller.goToPage(pageNumber: p); })).toList()))); }, itemBuilder: (_) => const <PopupMenuEntry<String>>[PopupMenuItem(value: 'bookmarks', child: Text('Bookmarks'))])]) : null,
      body: Stack(children: <Widget>[
        PdfViewer.file(book.pdfPath, controller: _controller, initialPageNumber: book.lastPage, params: PdfViewerParams(backgroundColor: bg, margin: 12, onPageChanged: _savePage, scrollPhysics: mode == 'Page focus' ? const PageScrollPhysics() : const BouncingScrollPhysics(), pageImageColorFilter: theme == 'Warm' ? const ColorFilter.mode(Color(0x18D99A35), BlendMode.srcOver) : null)),
        Positioned(top: 8, right: 12, child: SafeArea(child: IconButton.filledTonal(onPressed: () => setState(() => _showControls = !_showControls), icon: Icon(_showControls ? Icons.fullscreen : Icons.fullscreen_exit)))),
        if (_showControls) Positioned(left: 12, right: 12, bottom: 12, child: SafeArea(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7), decoration: BoxDecoration(color: theme == 'Dark' ? const Color(0xEE282536) : Colors.white.withValues(alpha: .96), borderRadius: BorderRadius.circular(18), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black26, blurRadius: 15)]), child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Row(children: <Widget>[IconButton(onPressed: _controller.isReady && _page > 1 ? () => _controller.goToPage(pageNumber: _page - 1) : null, icon: const Icon(Icons.chevron_left)), Expanded(child: TextButton(onPressed: _goToPage, child: Text('Page $_page${_controller.isReady ? ' / ${_controller.pageCount}' : ''}', style: TextStyle(color: _ink(theme), fontWeight: FontWeight.bold)))), IconButton(onPressed: _controller.isReady && _page < _controller.pageCount ? () => _controller.goToPage(pageNumber: _page + 1) : null, icon: const Icon(Icons.chevron_right))]),
          Row(children: <Widget>[Expanded(child: _readerAction(Icons.view_carousel_outlined, 'Page type', () => _readerOptions(theme, mode))), Expanded(child: _readerAction(Icons.wb_sunny_outlined, 'Theme', () => _readerOptions(theme, mode))), Expanded(child: _readerAction(Icons.tune_rounded, 'More', () => _readerOptions(theme, mode)))])
        ]))))
      ]));
  }

  Widget _readerAction(IconData icon, String label, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 21), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 11))])));
}
