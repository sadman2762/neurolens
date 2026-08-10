import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class WavyEffectProcessor {
  const WavyEffectProcessor._();

  /// Applies a sine-wave horizontal distortion.
  ///
  /// intensity:
  /// 0.0 = original
  /// 1.0 = strong wave distortion
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

    final codec =
        await ui.instantiateImageCodec(
      imageBytes,
    );

    try {
      final frame =
          await codec.getNextFrame();

      final image = frame.image;

      try {
        final byteData =
            await image.toByteData(
          format:
              ui.ImageByteFormat.rawRgba,
        );

        if (byteData == null) {
          throw StateError(
            'Could not decode image pixels.',
          );
        }

        final source =
            byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );

        final width = image.width;
        final height = image.height;

        final output =
            Uint8List(
          source.length,
        );

        // Maximum horizontal shift.
        final amplitude =
            width *
            0.045 *
            strength;

        // Number of visible waves vertically.
        final waveCount =
            2.0 +
            (strength * 2.0);

        final frequency =
            (
              math.pi *
              2 *
              waveCount
            ) /
            height;

        for (
          var y = 0;
          y < height;
          y++
        ) {
          final horizontalShift =
              math.sin(
                y * frequency,
              ) *
              amplitude;

          for (
            var x = 0;
            x < width;
            x++
          ) {
            final sourceX =
                (
                  x -
                  horizontalShift
                )
                    .round()
                    .clamp(
                      0,
                      width - 1,
                    );

            final sourceIndex =
                (
                  (y * width) +
                  sourceX
                ) *
                4;

            final destinationIndex =
                (
                  (y * width) +
                  x
                ) *
                4;

            output[destinationIndex] =
                source[sourceIndex];

            output[destinationIndex + 1] =
                source[sourceIndex + 1];

            output[destinationIndex + 2] =
                source[sourceIndex + 2];

            output[destinationIndex + 3] =
                source[sourceIndex + 3];
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
                    'Could not encode wavy result.',
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