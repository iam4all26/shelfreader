import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book_model.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap, required this.onMenu});
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final bool hasCover = book.coverPath != null && File(book.coverPath!).existsSync();
    return SizedBox(width: 112, child: Column(children: <Widget>[
      Expanded(child: Stack(clipBehavior: Clip.none, children: <Widget>[
        Positioned.fill(child: GestureDetector(onTap: onTap, child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(3)),
            border: Border.all(color: Colors.black.withValues(alpha: .24), width: 1),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(4, 5))],
            image: hasCover ? DecorationImage(image: FileImage(File(book.coverPath!)), fit: BoxFit.cover) : null,
            gradient: hasCover ? null : const LinearGradient(colors: <Color>[Color(0xFF5B3B28), Color(0xFFB57A3E), Color(0xFF57351F)]),
          ),
          child: hasCover ? null : Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(book.title, maxLines: 5, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, shadows: <Shadow>[Shadow(color: Colors.black54, blurRadius: 5)])))),
        ))),
        Positioned(left: 0, top: 0, bottom: 0, width: 7, child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black.withValues(alpha: .16), borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)))))),
        Positioned(right: -3, top: 2, child: Material(color: Colors.black.withValues(alpha: .56), shape: const CircleBorder(), child: InkWell(onTap: onMenu, customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(5), child: Icon(Icons.more_vert, color: Colors.white, size: 17))))),
        if (book.progress > 0) Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: book.progress, minHeight: 3, backgroundColor: Colors.transparent, color: const Color(0xFFF6C101))),
      ])),
      const SizedBox(height: 7),
      GestureDetector(onTap: onTap, child: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFF4E5), fontWeight: FontWeight.w700, fontSize: 11))),
      Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD8C4A8), fontSize: 9)),
    ]));
  }
}
