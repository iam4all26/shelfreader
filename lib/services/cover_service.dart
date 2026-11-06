import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CoverService {
  static Future<String?> generateFromPdf(String pdfPath, String id) async {
    PdfDocument? document;
    PdfImage? rendered;
    try {
      document = await PdfDocument.openFile(pdfPath);
      if (document.pages.isEmpty) return null;
      final page = document.pages.first;
      final double ratio = page.width / page.height;
      final int height = 560;
      final int width = (height * ratio).round().clamp(180, 900).toInt();
      rendered = await page.render(width: width, height: height);
      if (rendered == null) return null;
      final image = rendered.createImageNF();
      final List<int> png = img.encodePng(image);
      final Directory base = await getApplicationDocumentsDirectory();
      final Directory covers = Directory(p.join(base.path, 'shelf_reader', 'covers'));
      await covers.create(recursive: true);
      final File output = File(p.join(covers.path, '$id.png'));
      await output.writeAsBytes(png, flush: true);
      return output.path;
    } catch (_) {
      return null;
    } finally {
      rendered?.dispose();
      await document?.dispose();
    }
  }
}
