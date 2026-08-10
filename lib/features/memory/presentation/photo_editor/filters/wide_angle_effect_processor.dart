import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class WideAngleEffectProcessor {
  const WideAngleEffectProcessor._();

  /// Barrel-style wide-angle distortion.
  ///
  /// intensity:
  /// 0.0 = original
  /// 1.0 = strong wide-angle distortion
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

      final image =
          frame.image;

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

        final width =
            image.width;

        final height =
            image.height;

        final output =
            Uint8List(
          source.length,
        );

        final centerX =
            (width - 1) / 2.0;

        final centerY =
            (height - 1) / 2.0;

        final maxRadius =
            math.sqrt(
          (centerX * centerX) +
              (centerY * centerY),
        );

        // Controls how strong the barrel distortion becomes.
        final distortion =
            0.42 * strength;

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
            // Normalized coordinates around center.
            final nx =
                (x - centerX) /
                    maxRadius;

            final ny =
                (y - centerY) /
                    maxRadius;

            final radiusSquared =
                (nx * nx) +
                    (ny * ny);

            // Barrel distortion:
            //
            // pixels farther from center
            // are pulled outward more strongly.
            final factor =
                1.0 +
                    (
                      distortion *
                      radiusSquared
                    );

            final sourceX =
                centerX +
                    (
                      (x - centerX) /
                      factor
                    );

            final sourceY =
                centerY +
                    (
                      (y - centerY) /
                      factor
                    );

            final sx =
                sourceX
                    .round()
                    .clamp(
                      0,
                      width - 1,
                    );

            final sy =
                sourceY
                    .round()
                    .clamp(
                      0,
                      height - 1,
                    );

            final sourceIndex =
                (
                  (sy * width) +
                  sx
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
            width:
                width,
            height:
                height,
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
                    'Could not encode wide-angle result.',
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