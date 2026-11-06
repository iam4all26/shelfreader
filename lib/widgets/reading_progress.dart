import 'package:flutter/material.dart';

class ReadingProgress extends StatelessWidget {
  const ReadingProgress({super.key, required this.pagesRead, required this.bookCount});
  final int pagesRead;
  final int bookCount;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 12, 20, 4), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(18)),
    child: Row(children: <Widget>[
      const Icon(Icons.auto_stories_rounded, size: 30), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Your reading journey', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('$bookCount books in your library  •  $pagesRead pages read', style: Theme.of(context).textTheme.bodySmall),
      ])),
    ]),
  );
}
