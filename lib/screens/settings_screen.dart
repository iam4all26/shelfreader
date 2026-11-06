import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String theme = ref.watch(readingThemeProvider);
    final String mode = ref.watch(readingModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: <Widget>[
        const Text('Reading experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(child: Column(children: <Widget>[
          ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('Default reading theme'), subtitle: Text(theme), trailing: DropdownButton<String>(value: theme, underline: const SizedBox.shrink(), items: AppConfig.readingThemes.map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (String? v) { if (v != null) ref.read(readingThemeProvider.notifier).state = v; })),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.view_agenda_outlined), title: const Text('Reading layout'), subtitle: Text(mode), trailing: DropdownButton<String>(value: mode, underline: const SizedBox.shrink(), items: const <DropdownMenuItem<String>>[DropdownMenuItem(value: 'Continuous', child: Text('Scroll')), DropdownMenuItem(value: 'Page focus', child: Text('Page focus'))], onChanged: (String? v) { if (v != null) ref.read(readingModeProvider.notifier).state = v; })),
        ])),
        const SizedBox(height: 22), const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Card(child: Column(children: <Widget>[
          ListTile(leading: Icon(Icons.offline_pin_outlined), title: Text('Offline by design'), subtitle: Text('Your imported books and reading progress stay on this device.')),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.visibility_outlined), title: Text('Eye comfort'), subtitle: Text('Themes and warm overlays are reading preferences, not medical protection.')),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.info_outline), title: Text(AppConfig.appName), subtitle: Text('Personal PDF library • Version 1.0.0')),
        ])),
      ]),
    );
  }
}
