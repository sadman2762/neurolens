import 'dart:math' as math;

import 'color_grading.dart';

class ColorGradingProcessor {
  const ColorGradingProcessor._();

  static List<double> apply({
    required double r,
    required double g,
    required double b,
    required ColorGrading grading,
  }) {
    if (grading.isNeutral) {
      return [
        r.clamp(0.0, 1.0),
        g.clamp(0.0, 1.0),
        b.clamp(0.0, 1.0),
      ];
    }

    var red = r.clamp(0.0, 1.0);
    var green = g.clamp(0.0, 1.0);
    var blue = b.clamp(0.0, 1.0);

    final luminance =
        (
          (red * 0.2126) +
          (green * 0.7152) +
          (blue * 0.0722)
        ).clamp(
          0.0,
          1.0,
        );

    // =========================================================================
    // TONAL REGION MASKS
    // =========================================================================

    final balance = grading.balance.clamp(
      -1.0,
      1.0,
    );

    final blending = grading.blending.clamp(
      0.0,
      1.0,
    );

    final shadowCenter =
        0.28 +
        (balance * 0.08);

    final midtoneCenter =
        0.50 +
        (balance * 0.06);

    final highlightCenter =
        0.72 +
        (balance * 0.08);

    final width =
        0.28 +
        (blending * 0.18);

    final shadowWeight =
        _gaussianWeight(
      luminance,
      shadowCenter,
      width,
    );

    final midtoneWeight =
        _gaussianWeight(
      luminance,
      midtoneCenter,
      width,
    );

    final highlightWeight =
        _gaussianWeight(
      luminance,
      highlightCenter,
      width,
    );

    final totalWeight =
        shadowWeight +
        midtoneWeight +
        highlightWeight;

    if (totalWeight <= 0.000001) {
      return [
        red,
        green,
        blue,
      ];
    }

    // Normalize masks so they blend smoothly.
    final sWeight =
        shadowWeight /
        totalWeight;

    final mWeight =
        midtoneWeight /
        totalWeight;

    final hWeight =
        highlightWeight /
        totalWeight;

    // =========================================================================
    // APPLY SHADOW GRADE
    // =========================================================================

    final shadowRgb =
        _gradeColor(
      grading.shadows,
    );

    red +=
        (
          shadowRgb.$1 -
          red
        ) *
        grading.shadows.saturation *
        sWeight *
        0.35;

    green +=
        (
          shadowRgb.$2 -
          green
        ) *
        grading.shadows.saturation *
        sWeight *
        0.35;

    blue +=
        (
          shadowRgb.$3 -
          blue
        ) *
        grading.shadows.saturation *
        sWeight *
        0.35;

    final shadowLum =
        grading.shadows.luminance *
        sWeight *
        0.25;

    red += shadowLum;
    green += shadowLum;
    blue += shadowLum;

    // =========================================================================
    // APPLY MIDTONE GRADE
    // =========================================================================

    final midtoneRgb =
        _gradeColor(
      grading.midtones,
    );

    red +=
        (
          midtoneRgb.$1 -
          red
        ) *
        grading.midtones.saturation *
        mWeight *
        0.35;

    green +=
        (
          midtoneRgb.$2 -
          green
        ) *
        grading.midtones.saturation *
        mWeight *
        0.35;

    blue +=
        (
          midtoneRgb.$3 -
          blue
        ) *
        grading.midtones.saturation *
        mWeight *
        0.35;

    final midtoneLum =
        grading.midtones.luminance *
        mWeight *
        0.25;

    red += midtoneLum;
    green += midtoneLum;
    blue += midtoneLum;

    // =========================================================================
    // APPLY HIGHLIGHT GRADE
    // =========================================================================

    final highlightRgb =
        _gradeColor(
      grading.highlights,
    );

    red +=
        (
          highlightRgb.$1 -
          red
        ) *
        grading.highlights.saturation *
        hWeight *
        0.35;

    green +=
        (
          highlightRgb.$2 -
          green
        ) *
        grading.highlights.saturation *
        hWeight *
        0.35;

    blue +=
        (
          highlightRgb.$3 -
          blue
        ) *
        grading.highlights.saturation *
        hWeight *
        0.35;

    final highlightLum =
        grading.highlights.luminance *
        hWeight *
        0.25;

    red += highlightLum;
    green += highlightLum;
    blue += highlightLum;

    return [
      red.clamp(
        0.0,
        1.0,
      ),
      green.clamp(
        0.0,
        1.0,
      ),
      blue.clamp(
        0.0,
        1.0,
      ),
    ];
  }

  // ===========================================================================
  // HUE -> RGB
  // ===========================================================================

  static (double, double, double) _gradeColor(
    ColorGrade grade,
  ) {
    final hue = grade.hue % 1.0;

    return _hsvToRgb(
      hue,
      1.0,
      1.0,
    );
  }

  static (double, double, double) _hsvToRgb(
    double h,
    double s,
    double v,
  ) {
    final hue =
        (
          h %
          1.0
        );

    final scaled =
        hue *
        6.0;

    final sector =
        scaled.floor();

    final fraction =
        scaled -
        sector;

    final p =
        v *
        (
          1.0 -
          s
        );

    final q =
        v *
        (
          1.0 -
          (
            s *
            fraction
          )
        );

    final t =
        v *
        (
          1.0 -
          (
            s *
            (
              1.0 -
              fraction
            )
          )
        );

    switch (sector % 6) {
      case 0:
        return (
          v,
          t,
          p,
        );

      case 1:
        return (
          q,
          v,
          p,
        );

      case 2:
        return (
          p,
          v,
          t,
        );

      case 3:
        return (
          p,
          q,
          v,
        );

      case 4:
        return (
          t,
          p,
          v,
        );

      default:
        return (
          v,
          p,
          q,
        );
    }
  }

  // ===========================================================================
  // TONAL MASK
  // ===========================================================================

  static double _gaussianWeight(
    double value,
    double center,
    double width,
  ) {
    if (width <= 0.000001) {
      return 0.0;
    }

    final distance =
        (
          value -
          center
        ) /
        width;

    return math.exp(
      -0.5 *
          distance *
          distance,
    );
  }
}