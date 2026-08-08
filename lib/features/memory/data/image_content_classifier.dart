enum ImageContentType { text, photo }

class ImageContentClassifier {
  const ImageContentClassifier();

  ImageContentType classify(String ocrText) {
    final cleanedText = ocrText.trim();

    if (cleanedText.isEmpty) {
      return ImageContentType.photo;
    }

    final words = cleanedText
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.length >= 2)
        .toList(growable: false);

    final meaningfulCharacterCount = cleanedText
        .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')
        .length;

    final hasStrongOcrResult =
        words.length >= 5 && meaningfulCharacterCount >= 30;

    return hasStrongOcrResult ? ImageContentType.text : ImageContentType.photo;
  }
}
