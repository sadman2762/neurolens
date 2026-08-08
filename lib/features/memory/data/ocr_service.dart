import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<String> extractTextFromAsset(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);

    if (asset == null) {
      return '';
    }

    final file = await asset.file;

    if (file == null) {
      return '';
    }

    final inputImage = InputImage.fromFile(file);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    return recognizedText.text.trim();
  }

  Future<void> dispose() {
    return _textRecognizer.close();
  }
}
