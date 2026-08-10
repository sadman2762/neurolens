import 'dart:typed_data';
import 'dart:ui' as ui;

class GpuImageLoader {
  const GpuImageLoader._();

  static Future<ui.Image> decode(
    Uint8List imageBytes,
  ) async {
    final codec =
        await ui.instantiateImageCodec(
      imageBytes,
    );

    try {
      final frame =
          await codec.getNextFrame();

      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  static Future<ui.Image> decodePreview({
    required Uint8List imageBytes,
    int maxDimension = 1440,
  }) async {
    if (maxDimension <= 0) {
      throw ArgumentError.value(
        maxDimension,
        'maxDimension',
        'Must be greater than zero.',
      );
    }

    final infoCodec =
        await ui.instantiateImageCodec(
      imageBytes,
    );

    try {
      final frame =
          await infoCodec.getNextFrame();

      final sourceImage =
          frame.image;

      try {
        final width =
            sourceImage.width;

        final height =
            sourceImage.height;

        final largestDimension =
            width > height
                ? width
                : height;

        // Already suitable for GPU preview.
        if (largestDimension <=
            maxDimension) {
          return decode(
            imageBytes,
          );
        }

        final scale =
            maxDimension /
            largestDimension;

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

        final previewCodec =
            await ui.instantiateImageCodec(
          imageBytes,
          targetWidth:
              targetWidth,
          targetHeight:
              targetHeight,
          allowUpscaling:
              false,
        );

        try {
          final previewFrame =
              await previewCodec
                  .getNextFrame();

          return previewFrame.image;
        } finally {
          previewCodec.dispose();
        }
      } finally {
        sourceImage.dispose();
      }
    } finally {
      infoCodec.dispose();
    }
  }
}