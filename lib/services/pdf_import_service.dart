import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PdfImportService {
  static Future<List<PlatformFile>> pickPdfs() => FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: <String>['pdf'],
  );

  static Future<List<File>> pickPdfsFromFolder() async {
    final String? folder = await FilePicker.getDirectoryPath();
    if (folder == null || folder.isEmpty) return <File>[];
    final Directory root = Directory(folder);
    if (!await root.exists()) return <File>[];
    final List<File> pdfs = <File>[];
    await for (final FileSystemEntity entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) pdfs.add(entity);
    }
    pdfs.sort((File a, File b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    return pdfs;
  }
}
