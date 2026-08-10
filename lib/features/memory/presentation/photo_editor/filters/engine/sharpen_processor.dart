import 'dart:typed_data';

class SharpenProcessor {
  const SharpenProcessor._();

  static Uint8List apply({
    required Uint8List pixels,
    required int width,
    required int height,
    required double sharpen,
  }) {
    final strength = sharpen.clamp(
      0.0,
      1.0,
    );

    if (strength <= 0.0001 ||
        width < 3 ||
        height < 3) {
      return pixels;
    }

    // Work from the original processed pixels.
    //
    // Never read from the output while sharpening,
    // otherwise the effect compounds as we move
    // across the image.
    final source = Uint8List.fromList(
      pixels,
    );

    final output = Uint8List.fromList(
      pixels,
    );

    // Keep sharpening controlled.
    //
    // 1.0 recipe strength does NOT mean an extreme
    // Photoshop-style sharpen.
    final amount =
        strength * 0.85;

    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final index =
            ((y * width) + x) * 4;

        final leftIndex =
            ((y * width) + (x - 1)) * 4;

        final rightIndex =
            ((y * width) + (x + 1)) * 4;

        final topIndex =
            (((y - 1) * width) + x) * 4;

        final bottomIndex =
            (((y + 1) * width) + x) * 4;

        // Process RGB only.
        for (var channel = 0; channel < 3; channel++) {
          final center =
              source[index + channel].toDouble();

          final left =
              source[leftIndex + channel].toDouble();

          final right =
              source[rightIndex + channel].toDouble();

          final top =
              source[topIndex + channel].toDouble();

          final bottom =
              source[bottomIndex + channel].toDouble();

          // Four-neighbour blur estimate.
          final surroundingAverage =
              (
                left +
                right +
                top +
                bottom
              ) /
              4.0;

          // High-frequency detail.
          final detail =
              center -
              surroundingAverage;

          // Threshold prevents tiny noise from being
          // sharpened unnecessarily.
          final absoluteDetail =
              detail.abs();

          double detailMask;

          if (absoluteDetail <= 1.5) {
            detailMask = 0.0;
          } else if (absoluteDetail >= 18.0) {
            detailMask = 1.0;
          } else {
            final t =
                (
                  (absoluteDetail - 1.5) /
                  (18.0 - 1.5)
                ).clamp(
                  0.0,
                  1.0,
                );

            detailMask =
                t *
                t *
                (
                  3.0 -
                  (2.0 * t)
                );
          }

          final sharpened =
              center +
              (
                detail *
                amount *
                detailMask
              );

          output[index + channel] =
              sharpened
                  .round()
                  .clamp(
                    0,
                    255,
                  );
        }

        // Preserve alpha exactly.
        output[index + 3] =
            source[index + 3];
      }
    }

    return output;
  }
}