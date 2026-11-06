import 'package:file_picker/file_picker.dart';

class CoverService {
  static Future<PlatformFile?> pickCover() async {
    return FilePicker.pickFile(type: FileType.image);
  }
}
