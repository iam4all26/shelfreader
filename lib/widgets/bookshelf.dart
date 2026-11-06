import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'book_card.dart';

class Bookshelf extends StatelessWidget {
  const Bookshelf({super.key, required this.title, required this.books, required this.onBookTap, required this.onBookMenu});
  final String title;
  final List<Book> books;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book> onBookMenu;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 9), child: Row(children: <Widget>[Expanded(child: Text(title, style: const TextStyle(color: Color(0xFFFFE9C9), fontWeight: FontWeight.w800, fontSize: 16))), Text('${books.length} books', style: const TextStyle(color: Color(0xFFD7B990), fontSize: 11))])),
      SizedBox(height: 198, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => BookCard(book: books[index], onTap: () => onBookTap(books[index]), onMenu: () => onBookMenu(books[index])),
      )),
      Container(height: 13, margin: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF9B6735), Color(0xFF4B2A16), Color(0xFF28150D)]), borderRadius: BorderRadius.circular(3), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black87, blurRadius: 9, offset: Offset(0, 5))])),
    ]));
  }
}
