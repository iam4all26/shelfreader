import 'dart:io';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/book_model.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap, this.onFavorite});
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final String? cover = book.coverPath;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        AspectRatio(
          aspectRatio: 0.72,
          child: Stack(children: <Widget>[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppConfig.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                image: cover != null && File(cover).existsSync()
                    ? DecorationImage(image: FileImage(File(cover)), fit: BoxFit.cover)
                    : null,
              ),
              child: cover == null || !File(cover).existsSync()
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                      Icon(Icons.picture_as_pdf_rounded, size: 42, color: AppConfig.primary),
                      SizedBox(height: 8),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('PDF BOOK', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppConfig.primary))),
                    ])
                  : null,
            ),
            if (onFavorite != null)
              Positioned(right: 5, top: 5, child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                onPressed: onFavorite,
                icon: Icon(book.isFavorite ? Icons.favorite : Icons.favorite_border, color: book.isFavorite ? Colors.red : null),
              )),
            Positioned(left: 0, right: 0, bottom: 0, child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: LinearProgressIndicator(value: book.progress, minHeight: 4, backgroundColor: Colors.black12, color: AppConfig.accent),
            )),
          ]),
        ),
        const SizedBox(height: 8),
        Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
