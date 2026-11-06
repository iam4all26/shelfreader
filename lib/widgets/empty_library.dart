import 'package:flutter/material.dart';
import '../config.dart';

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key, required this.onImport});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Container(width: 112, height: 112, decoration: BoxDecoration(color: AppConfig.primary.withValues(alpha: 0.10), shape: BoxShape.circle), child: const Icon(Icons.local_library_rounded, size: 58, color: AppConfig.primary)),
      const SizedBox(height: 20), const Text('Your bookshelf is waiting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('Import your first PDF and start building a library that stays with you, even offline.', textAlign: TextAlign.center),
      const SizedBox(height: 20), FilledButton.icon(onPressed: onImport, icon: const Icon(Icons.add), label: const Text('Import PDF books')),
    ]),
  ));
}
