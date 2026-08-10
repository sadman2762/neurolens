import 'dart:typed_data';

class HalationProcessor {
  const HalationProcessor._();

  static Uint8List apply({
    required Uint8List pixels,
    required int width,
    required int height,
    required double halation,
  }) {
    final strength = halation.clamp(
      0.0,
      1.0,
    );

    if (strength <= 0.0001 ||
        width < 3 ||
        height < 3) {
      return pixels;
    }

    final source = Uint8List.fromList(
      pixels,
    );

    final output = Uint8List.fromList(
      pixels,
    );

    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final index =
            ((y * width) + x) * 4;

        final r =
            source[index] / 255.0;

        final g =
            source[index + 1] / 255.0;

        final b =
            source[index + 2] / 255.0;

        final luminance =
            (
              (r * 0.2126) +
              (g * 0.7152) +
              (b * 0.0722)
            ).clamp(
              0.0,
              1.0,
            );

        // Only bright pixels generate halation.
        final highlightMask =
            _smoothStep(
          0.64,
          0.94,
          luminance,
        );

        if (highlightMask <= 0.0001) {
          continue;
        }

        final leftIndex =
            ((y * width) + (x - 1)) * 4;

        final rightIndex =
            ((y * width) + (x + 1)) * 4;

        final topIndex =
            (((y - 1) * width) + x) * 4;

        final bottomIndex =
            (((y + 1) * width) + x) * 4;

        final surroundingRed =
            (
              source[leftIndex] +
              source[rightIndex] +
              source[topIndex] +
              source[bottomIndex]
            ) /
            4.0 /
            255.0;

        final surroundingGreen =
            (
              source[leftIndex + 1] +
              source[rightIndex + 1] +
              source[topIndex + 1] +
              source[bottomIndex + 1]
            ) /
            4.0 /
            255.0;

        // Warm reddish-orange glow.
        final bloom =
            strength *
            highlightMask *
            0.16;

        final redBoost =
            bloom *
            (
              0.65 +
              (surroundingRed * 0.35)
            );

        final greenBoost =
            bloom *
            0.42 *
            (
              0.70 +
              (surroundingGreen * 0.30)
            );

        final blueReduction =
            bloom * 0.05;

        output[index] =
            _toChannel(
          r + redBoost,
        );

        output[index + 1] =
            _toChannel(
          g + greenBoost,
        );

        output[index + 2] =
            _toChannel(
          b - blueReduction,
        );

        output[index + 3] =
            source[index + 3];
      }
    }

    return output;
  }

  static double _smoothStep(
    double edge0,
    double edge1,
    double x,
  ) {
    final t =
        (
          (x - edge0) /
          (edge1 - edge0)
        ).clamp(
          0.0,
          1.0,
        );

    return t *
        t *
        (
          3.0 -
          (2.0 * t)
        );
  }

  static int _toChannel(
    double value,
  ) {
    return (
      value.clamp(
            0.0,
            1.0,
          ) *
          255.0
    )
        .round()
        .clamp(
          0,
          255,
        );
  }
}