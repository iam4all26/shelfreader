import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(readingThemeProvider);
    final mode = ref.watch(readingModeProvider);
    return Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(padding: const EdgeInsets.all(18), children: <Widget>[
      const Text('Reading preferences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      const SizedBox(height: 10),
      Card(child: Column(children: <Widget>[
        ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('Default reading theme'), subtitle: Text(theme), trailing: DropdownButton<String>(value: theme, underline: const SizedBox.shrink(), items: AppConfig.readingThemes.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) ref.read(readingThemeProvider.notifier).state = v; })),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.view_agenda_outlined), title: const Text('Default page type'), subtitle: Text(mode == 'Continuous' ? 'Continuous scroll' : 'Single page'), trailing: DropdownButton<String>(value: mode, underline: const SizedBox.shrink(), items: const <DropdownMenuItem<String>>[DropdownMenuItem(value: 'Continuous', child: Text('Scroll')), DropdownMenuItem(value: 'Page focus', child: Text('Single page'))], onChanged: (v) { if (v != null) ref.read(readingModeProvider.notifier).state = v; })),
      ])),
      const SizedBox(height: 22), const Text('Your library', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      const Card(child: Column(children: <Widget>[
        ListTile(leading: Icon(Icons.auto_awesome_outlined), title: Text('Automatic book covers'), subtitle: Text('ShelfReader creates each cover from the first page of its PDF.')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.folder_copy_outlined), title: Text('Import from folders'), subtitle: Text('Choose a folder to find and import PDF files inside it.')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.offline_pin_outlined), title: Text('Offline by design'), subtitle: Text('Imported PDFs, covers and reading progress stay on this device.')),
      ])),
      const SizedBox(height: 22), const Text('About', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      const Card(child: ListTile(leading: Icon(Icons.menu_book_rounded), title: Text(AppConfig.appName), subtitle: Text('Personal PDF bookshelf and reader • Version 2.0.0'))),
    ]));
  }
}
