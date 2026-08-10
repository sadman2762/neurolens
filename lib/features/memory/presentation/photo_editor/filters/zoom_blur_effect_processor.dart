import 'dart:typed_data';
import 'dart:ui' as ui;

class ZoomBlurEffectProcessor {
  const ZoomBlurEffectProcessor._();

  /// Applies a radial zoom-blur effect toward the center of the image.
  ///
  /// intensity:
  /// 0.0 = original image
  /// 1.0 = strong zoom blur
  static Future<Uint8List> apply({
    required Uint8List imageBytes,
    required double intensity,
  }) async {
    final strength = intensity.clamp(
      0.0,
      1.0,
    );

    if (strength <= 0.001) {
      return imageBytes;
    }

    final codec = await ui.instantiateImageCodec(
      imageBytes,
    );

    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        final byteData = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );

        if (byteData == null) {
          throw StateError(
            'Could not decode image pixels.',
          );
        }

        final source = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );

        final width = image.width;
        final height = image.height;

        final output = Uint8List(
          source.length,
        );

        final centerX =
            (width - 1) / 2.0;

        final centerY =
            (height - 1) / 2.0;

        // More intensity = more samples.
        final sampleCount =
            5 + (strength * 13).round();

        // Maximum radial travel.
        final maxTravel =
            0.16 * strength;

        for (
          var y = 0;
          y < height;
          y++
        ) {
          for (
            var x = 0;
            x < width;
            x++
          ) {
            double red = 0;
            double green = 0;
            double blue = 0;
            double alpha = 0;

            final dx =
                x - centerX;

            final dy =
                y - centerY;

            for (
              var sample = 0;
              sample < sampleCount;
              sample++
            ) {
              final t = sampleCount <= 1
                  ? 0.0
                  : sample /
                      (sampleCount - 1);

              // Samples travel toward the center.
              final scale =
                  1.0 -
                      (
                        maxTravel *
                        t
                      );

              final sampleX =
                  centerX +
                  (dx * scale);

              final sampleY =
                  centerY +
                  (dy * scale);

              final sx = sampleX
                  .round()
                  .clamp(
                    0,
                    width - 1,
                  );

              final sy = sampleY
                  .round()
                  .clamp(
                    0,
                    height - 1,
                  );

              final sourceIndex =
                  ((sy * width) + sx) * 4;

              red +=
                  source[sourceIndex];

              green +=
                  source[sourceIndex + 1];

              blue +=
                  source[sourceIndex + 2];

              alpha +=
                  source[sourceIndex + 3];
            }

            final destinationIndex =
                ((y * width) + x) * 4;

            output[destinationIndex] =
                (red / sampleCount)
                    .round()
                    .clamp(
                      0,
                      255,
                    );

            output[destinationIndex + 1] =
                (green / sampleCount)
                    .round()
                    .clamp(
                      0,
                      255,
                    );

            output[destinationIndex + 2] =
                (blue / sampleCount)
                    .round()
                    .clamp(
                      0,
                      255,
                    );

            output[destinationIndex + 3] =
                (alpha / sampleCount)
                    .round()
                    .clamp(
                      0,
                      255,
                    );
          }
        }

        final buffer =
            await ui.ImmutableBuffer
                .fromUint8List(
          output,
        );

        try {
          final descriptor =
              ui.ImageDescriptor.raw(
            buffer,
            width: width,
            height: height,
            pixelFormat:
                ui.PixelFormat.rgba8888,
          );

          try {
            final processedCodec =
                await descriptor
                    .instantiateCodec();

            try {
              final processedFrame =
                  await processedCodec
                      .getNextFrame();

              final processedImage =
                  processedFrame.image;

              try {
                final pngData =
                    await processedImage
                        .toByteData(
                  format:
                      ui.ImageByteFormat.png,
                );

                if (pngData == null) {
                  throw StateError(
                    'Could not encode zoom blur result.',
                  );
                }

                return pngData.buffer
                    .asUint8List(
                  pngData.offsetInBytes,
                  pngData.lengthInBytes,
                );
              } finally {
                processedImage.dispose();
              }
            } finally {
              processedCodec.dispose();
            }
          } finally {
            descriptor.dispose();
          }
        } finally {
          buffer.dispose();
        }
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}