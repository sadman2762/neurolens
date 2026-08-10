import 'dart:typed_data';
import 'dart:ui' as ui;

import 'filter_image_processor.dart';
import 'filter_recipe.dart';

class FilterPreviewProcessor {
  const FilterPreviewProcessor._();

  // Keep preview processing reasonably fast on phones.
  //
  // The final exported image will NOT use this reduced resolution.
  static const int defaultMaxDimension = 1080;

  static Future<Uint8List> apply({
    required Uint8List imageBytes,
    required FilterRecipe recipe,
    required double intensity,
    int maxDimension = defaultMaxDimension,
  }) async {
    final value = intensity.clamp(
      0.0,
      1.0,
    );

    if (value <= 0.001) {
      return imageBytes;
    }

    final previewBytes = await _resizeForPreview(
      imageBytes: imageBytes,
      maxDimension: maxDimension,
    );

    return FilterImageProcessor.apply(
      imageBytes: previewBytes,
      recipe: recipe,
      intensity: value,
    );
  }

  static Future<Uint8List> _resizeForPreview({
    required Uint8List imageBytes,
    required int maxDimension,
  }) async {
    if (maxDimension <= 0) {
      throw ArgumentError.value(
        maxDimension,
        'maxDimension',
        'Must be greater than zero.',
      );
    }

    final codec = await ui.instantiateImageCodec(
      imageBytes,
    );

    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        final width = image.width;
        final height = image.height;

        final largestDimension =
            width > height ? width : height;

        // Already small enough.
        if (largestDimension <= maxDimension) {
          return imageBytes;
        }

        final scale =
            maxDimension / largestDimension;

        final targetWidth =
            (width * scale)
                .round()
                .clamp(
                  1,
                  maxDimension,
                );

        final targetHeight =
            (height * scale)
                .round()
                .clamp(
                  1,
                  maxDimension,
                );

        return _decodeAtSize(
          imageBytes: imageBytes,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static Future<Uint8List> _decodeAtSize({
    required Uint8List imageBytes,
    required int targetWidth,
    required int targetHeight,
  }) async {
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: false,
    );

    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        final data = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (data == null) {
          throw StateError(
            'Could not encode filter preview image.',
          );
        }

        return data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}