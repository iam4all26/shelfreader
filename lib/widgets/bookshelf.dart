import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'book_card.dart';

class Bookshelf extends StatelessWidget {
  const Bookshelf({super.key, required this.title, required this.books, required this.onBookTap, required this.onFavorite});
  final String title;
  final List<Book> books;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book> onFavorite;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 12), child: Row(children: <Widget>[
        Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        Text('${books.length} books', style: Theme.of(context).textTheme.bodySmall),
      ])),
      SizedBox(height: 225, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => SizedBox(width: 116, child: BookCard(
          book: books[index], onTap: () => onBookTap(books[index]), onFavorite: () => onFavorite(books[index]),
        )),
      )),
      Container(height: 5, margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: const Color(0xFFB58B55), borderRadius: BorderRadius.circular(5))),
    ]);
  }
}
