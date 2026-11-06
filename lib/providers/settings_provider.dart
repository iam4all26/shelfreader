import 'package:flutter_riverpod/legacy.dart';
import '../config.dart';

final StateProvider<String> readingThemeProvider = StateProvider<String>((ref) => AppConfig.defaultReadingTheme);
final StateProvider<String> readingModeProvider = StateProvider<String>((ref) => 'Continuous');
