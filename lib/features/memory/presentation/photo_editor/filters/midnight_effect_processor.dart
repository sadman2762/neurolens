import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class MidnightEffectProcessor {
  const MidnightEffectProcessor._();

  /// Applies a radial Midnight effect.
  ///
  /// intensity:
  /// 0.0 = no effect
  /// 1.0 = strongest effect
  ///
  /// Result:
  /// - center is softly lifted / glowing
  /// - middle stays relatively natural
  /// - edges become progressively darker
  /// - corners are darkest
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
            'Could not decode Midnight image pixels.',
          );
        }

        final source =
            byteData.buffer.asUint8List(
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

        final maxDistance = math.sqrt(
          (centerX * centerX) +
              (centerY * centerY),
        );

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
            final index =
                ((y * width) + x) * 4;

            final dx =
                x - centerX;

            final dy =
                y - centerY;

            final distance = math.sqrt(
              (dx * dx) +
                  (dy * dy),
            );

            final normalizedDistance =
                (
                  distance /
                  maxDistance
                ).clamp(
                  0.0,
                  1.0,
                );

            // ===============================================================
            // DARK EDGE VIGNETTE
            // ===============================================================
            //
            // Center:
            // almost untouched.
            //
            // Around 35% radius:
            // darkening starts.
            //
            // Toward corners:
            // progressively stronger.
            // ===============================================================

            double vignette;

            if (normalizedDistance <= 0.35) {
              vignette = 0.0;
            } else {
              final t =
                  (
                    (
                      normalizedDistance -
                      0.35
                    ) /
                    0.65
                  ).clamp(
                    0.0,
                    1.0,
                  );

              vignette =
                  t *
                  t *
                  (
                    3.0 -
                    (2.0 * t)
                  );
            }

            // At 100 intensity:
            // corners can become about 48% darker.
            final maxDarkness =
                0.48 *
                strength;

            final darkness =
                vignette *
                maxDarkness;

            // ===============================================================
            // CENTER GLOW
            // ===============================================================
            //
            // Strongest at exact center.
            // Smoothly fades out before edge darkness becomes dominant.
            // ===============================================================

            const centerGlowRadius =
                0.52;

            final rawGlow =
                (
                  1.0 -
                  (
                    normalizedDistance /
                    centerGlowRadius
                  ).clamp(
                    0.0,
                    1.0,
                  )
                );

            final smoothGlow =
                rawGlow *
                rawGlow *
                (
                  3.0 -
                  (2.0 * rawGlow)
                );

            // Main center brightness lift.
            final glowAmount =
                0.24 *
                strength *
                smoothGlow;

            // Slight warm-neutral lift so center feels illuminated
            // instead of simply overexposed.
            final redGlow =
                1.0 +
                (
                  glowAmount *
                  1.02
                );

            final greenGlow =
                1.0 +
                glowAmount;

            final blueGlow =
                1.0 +
                (
                  glowAmount *
                  0.94
                );

            // ===============================================================
            // FINAL DARKNESS MULTIPLIER
            // ===============================================================

            final edgeMultiplier =
                1.0 -
                darkness;

            // ===============================================================
            // APPLY RGB
            // ===============================================================

            final red =
                source[index] *
                edgeMultiplier *
                redGlow;

            final green =
                source[index + 1] *
                edgeMultiplier *
                greenGlow;

            final blue =
                source[index + 2] *
                edgeMultiplier *
                blueGlow;

            output[index] =
                _clampChannel(
              red,
            );

            output[index + 1] =
                _clampChannel(
              green,
            );

            output[index + 2] =
                _clampChannel(
              blue,
            );

            // Preserve alpha.
            output[index + 3] =
                source[index + 3];
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
                    'Could not encode Midnight effect.',
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

  static int _clampChannel(
    num value,
  ) {
    return value
        .round()
        .clamp(
          0,
          255,
        );
  }
}