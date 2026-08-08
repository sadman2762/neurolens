import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfTextExtractorService {
  Future<String> extractText(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      return PdfTextExtractor(document).extractText().trim();
    } finally {
      document.dispose();
    }
  }
}
