import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class GrainEffectProcessor {
  const GrainEffectProcessor._();

  static Future<Uint8List> apply({
    required Uint8List imageBytes,
    required double intensity,
  }) async {
    final normalized = intensity.clamp(
      0.0,
      1.0,
    );

    // 0 = return original unchanged.
    if (normalized <= 0.001) {
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

        final pixels = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );

        final random = math.Random(1337);

        // Maximum pixel variation at intensity 100.
        final maxNoise =
            34 * normalized;

        for (
          var index = 0;
          index < pixels.length;
          index += 4
        ) {
          final noise =
              ((random.nextDouble() * 2) - 1) *
                  maxNoise;

          pixels[index] = _clampChannel(
            pixels[index] + noise,
          );

          pixels[index + 1] = _clampChannel(
            pixels[index + 1] + noise,
          );

          pixels[index + 2] = _clampChannel(
            pixels[index + 2] + noise,
          );

          // Alpha at index + 3 stays untouched.
        }

        final completer =
            ui.ImmutableBuffer.fromUint8List(
          pixels,
        );

        final buffer = await completer;

        try {
          final descriptor =
              ui.ImageDescriptor.raw(
            buffer,
            width: image.width,
            height: image.height,
            pixelFormat:
                ui.PixelFormat.rgba8888,
          );

          try {
            final processedCodec =
                await descriptor.instantiateCodec();

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
                    'Could not encode grain image.',
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