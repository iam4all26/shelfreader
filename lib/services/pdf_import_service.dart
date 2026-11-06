
import 'package:file_picker/file_picker.dart';

class PdfImportService {
  static Future<List<PlatformFile>> pickPdfs() async {
    return FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );
  }
}
