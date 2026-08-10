import 'dart:math' as math;

class LightAdjustment {
  const LightAdjustment({
    this.exposure = 0.0,
    this.contrast = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.whites = 0.0,
    this.blacks = 0.0,
  });

  final double exposure;
  final double contrast;
  final double highlights;
  final double shadows;
  final double whites;
  final double blacks;

  LightAdjustment withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return LightAdjustment(
      exposure: exposure * t,
      contrast: contrast * t,
      highlights: highlights * t,
      shadows: shadows * t,
      whites: whites * t,
      blacks: blacks * t,
    );
  }

  /// Applies light adjustments to one RGB pixel.
  ///
  /// Input/output channels use normalized 0.0 .. 1.0 values.
  List<double> apply({
    required double r,
    required double g,
    required double b,
  }) {
    var red = r.clamp(0.0, 1.0);
    var green = g.clamp(0.0, 1.0);
    var blue = b.clamp(0.0, 1.0);

    // =========================================================================
    // EXPOSURE
    // =========================================================================

    final exposureMultiplier =
        math.pow(
          2.0,
          exposure,
        ).toDouble();

    red *= exposureMultiplier;
    green *= exposureMultiplier;
    blue *= exposureMultiplier;

    // =========================================================================
    // CONTRAST
    // =========================================================================

    final contrastFactor =
        1.0 +
        contrast;

    red =
        ((red - 0.5) *
                contrastFactor) +
            0.5;

    green =
        ((green - 0.5) *
                contrastFactor) +
            0.5;

    blue =
        ((blue - 0.5) *
                contrastFactor) +
            0.5;

    // =========================================================================
    // LUMINANCE
    // =========================================================================

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
    // SHADOWS
    // =========================================================================

    final shadowMask =
        1.0 -
        _smoothStep(
          0.0,
          0.55,
          luminance,
        );

    final shadowLift =
        shadows *
        0.32 *
        shadowMask;

    red += shadowLift;
    green += shadowLift;
    blue += shadowLift;

    // =========================================================================
    // HIGHLIGHTS
    // =========================================================================

    final highlightMask =
        _smoothStep(
          0.45,
          1.0,
          luminance,
        );

    final highlightAmount =
        highlights *
        0.28 *
        highlightMask;

    red += highlightAmount;
    green += highlightAmount;
    blue += highlightAmount;

    // =========================================================================
    // BLACKS
    // =========================================================================

    final blackMask =
        1.0 -
        _smoothStep(
          0.0,
          0.35,
          luminance,
        );

    final blackAmount =
        blacks *
        0.24 *
        blackMask;

    red += blackAmount;
    green += blackAmount;
    blue += blackAmount;

    // =========================================================================
    // WHITES
    // =========================================================================

    final whiteMask =
        _smoothStep(
          0.65,
          1.0,
          luminance,
        );

    final whiteAmount =
        whites *
        0.20 *
        whiteMask;

    red += whiteAmount;
    green += whiteAmount;
    blue += whiteAmount;

    // =========================================================================
    // FINAL CLAMP
    // =========================================================================

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

  static double _smoothStep(
    double edge0,
    double edge1,
    double x,
  ) {
    if (edge0 == edge1) {
      return x < edge0 ? 0.0 : 1.0;
    }

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
}