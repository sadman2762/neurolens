import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:photo_manager/photo_manager.dart';

class LocalImageLabelingService {
  LocalImageLabelingService({
    this._maximumLabels = 3,
    double confidenceThreshold = 0.65,
  }) : _confidenceThreshold = confidenceThreshold,
       _imageLabeler = ImageLabeler(
         options: ImageLabelerOptions(confidenceThreshold: confidenceThreshold),
       );

  final double _confidenceThreshold;
  final int _maximumLabels;
  final ImageLabeler _imageLabeler;

  Future<List<String>> labelAsset({required AssetEntity asset}) async {
    final file = await asset.file;

    if (file == null) {
      throw const LocalImageLabelingException(
        'Could not access the selected image.',
      );
    }

    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final labels = await _imageLabeler.processImage(inputImage);

      final filteredLabels =
          labels
              .where(
                (label) =>
                    label.confidence >= _confidenceThreshold &&
                    label.label.trim().isNotEmpty,
              )
              .toList(growable: false)
            ..sort(
              (first, second) => second.confidence.compareTo(first.confidence),
            );

      final uniqueLabels = <String>[];
      final normalizedLabels = <String>{};

      for (final label in filteredLabels) {
        final value = label.label.trim();
        final normalizedValue = value.toLowerCase();

        if (normalizedLabels.add(normalizedValue)) {
          uniqueLabels.add(value);
        }

        if (uniqueLabels.length >= _maximumLabels) {
          break;
        }
      }

      return uniqueLabels;
    } catch (error) {
      throw LocalImageLabelingException('Could not label the image: $error');
    }
  }

  Future<void> dispose() {
    return _imageLabeler.close();
  }
}

class LocalImageLabelingException implements Exception {
  const LocalImageLabelingException(this.message);

  final String message;

  @override
  String toString() => message;
}
