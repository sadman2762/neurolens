class ColorAdjustment {
  const ColorAdjustment({
    this.temperature = 0.0,
    this.tint = 0.0,
    this.saturation = 0.0,
    this.vibrance = 0.0,
  });

  /// Suggested range:
  ///
  /// -1.0 = cooler
  ///  0.0 = neutral
  ///  1.0 = warmer
  final double temperature;

  /// Suggested range:
  ///
  /// -1.0 = greener
  ///  0.0 = neutral
  ///  1.0 = more magenta
  final double tint;

  /// Suggested range:
  ///
  /// -1.0 = fully desaturated
  ///  0.0 = unchanged
  ///  1.0 = strongly saturated
  final double saturation;

  /// Vibrance increases weaker colors more than
  /// already-saturated colors.
  ///
  /// Suggested range:
  ///
  /// -1.0 = reduce weaker colors
  ///  0.0 = unchanged
  ///  1.0 = boost weaker colors
  final double vibrance;

  ColorAdjustment withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return ColorAdjustment(
      temperature: temperature * t,
      tint: tint * t,
      saturation: saturation * t,
      vibrance: vibrance * t,
    );
  }

  List<double> apply({
    required double r,
    required double g,
    required double b,
  }) {
    var red = r.clamp(
      0.0,
      1.0,
    );

    var green = g.clamp(
      0.0,
      1.0,
    );

    var blue = b.clamp(
      0.0,
      1.0,
    );

    // =========================================================================
    // TEMPERATURE
    // =========================================================================
    //
    // Positive:
    // red/yellow warmth.
    //
    // Negative:
    // blue/cool shift.
    // =========================================================================

    red += temperature * 0.10;

    green += temperature * 0.025;

    blue -= temperature * 0.10;

    // =========================================================================
    // TINT
    // =========================================================================
    //
    // Positive:
    // magenta.
    //
    // Negative:
    // green.
    // =========================================================================

    red += tint * 0.035;

    green -= tint * 0.055;

    blue += tint * 0.035;

    red = red.clamp(
      0.0,
      1.0,
    );

    green = green.clamp(
      0.0,
      1.0,
    );

    blue = blue.clamp(
      0.0,
      1.0,
    );

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
    // SATURATION
    // =========================================================================

    final saturationFactor =
        1.0 +
        saturation;

    red =
        luminance +
        (
          (red - luminance) *
          saturationFactor
        );

    green =
        luminance +
        (
          (green - luminance) *
          saturationFactor
        );

    blue =
        luminance +
        (
          (blue - luminance) *
          saturationFactor
        );

    // =========================================================================
    // VIBRANCE
    // =========================================================================
    //
    // Estimate how saturated this pixel already is.
    //
    // Lower-saturation pixels get a stronger boost.
    // Highly saturated pixels get less.
    // =========================================================================

    final maxChannel =
        _max3(
      red,
      green,
      blue,
    );

    final minChannel =
        _min3(
      red,
      green,
      blue,
    );

    final chroma =
        (
          maxChannel -
          minChannel
        ).clamp(
          0.0,
          1.0,
        );

    final weakColorMask =
        1.0 -
        chroma;

    final vibranceFactor =
        1.0 +
        (
          vibrance *
          weakColorMask
        );

    red =
        luminance +
        (
          (red - luminance) *
          vibranceFactor
        );

    green =
        luminance +
        (
          (green - luminance) *
          vibranceFactor
        );

    blue =
        luminance +
        (
          (blue - luminance) *
          vibranceFactor
        );

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

  static double _max3(
    double a,
    double b,
    double c,
  ) {
    var result = a;

    if (b > result) {
      result = b;
    }

    if (c > result) {
      result = c;
    }

    return result;
  }

  static double _min3(
    double a,
    double b,
    double c,
  ) {
    var result = a;

    if (b < result) {
      result = b;
    }

    if (c < result) {
      result = c;
    }

    return result;
  }
}