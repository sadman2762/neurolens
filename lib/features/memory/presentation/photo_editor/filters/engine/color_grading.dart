class ColorGrade {
  const ColorGrade({
    this.hue = 0.0,
    this.saturation = 0.0,
    this.luminance = 0.0,
  });

  /// Hue in normalized form.
  ///
  /// Recommended:
  /// 0.0 .. 1.0
  ///
  /// Example:
  /// 0.0   = red
  /// 0.16  = yellow
  /// 0.33  = green
  /// 0.50  = cyan
  /// 0.66  = blue
  /// 0.83  = magenta
  final double hue;

  /// 0.0 = no color grade
  /// 1.0 = strongest grade
  final double saturation;

  /// -1.0 = darker
  ///  0.0 = unchanged
  ///  1.0 = brighter
  final double luminance;

  ColorGrade withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return ColorGrade(
      // Hue stays fixed.
      hue: hue,

      saturation:
          saturation * t,

      luminance:
          luminance * t,
    );
  }

  bool get isNeutral {
    return saturation.abs() <= 0.0001 &&
        luminance.abs() <= 0.0001;
  }
}

class ColorGrading {
  const ColorGrading({
    this.shadows = const ColorGrade(),
    this.midtones = const ColorGrade(),
    this.highlights = const ColorGrade(),

    this.balance = 0.0,
    this.blending = 0.5,
  });

  final ColorGrade shadows;
  final ColorGrade midtones;
  final ColorGrade highlights;

  /// Controls where shadows/midtones/highlights meet.
  ///
  /// -1.0 = grading favors darker tonal regions
  ///  0.0 = neutral
  ///  1.0 = grading favors brighter tonal regions
  final double balance;

  /// How softly the three tonal grading regions blend.
  ///
  /// 0.0 = harder separation
  /// 1.0 = very smooth blending
  final double blending;

  static const neutral = ColorGrading();

  ColorGrading withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return ColorGrading(
      shadows:
          shadows.withIntensity(
        t,
      ),

      midtones:
          midtones.withIntensity(
        t,
      ),

      highlights:
          highlights.withIntensity(
        t,
      ),

      balance:
          balance * t,

      // Blending describes the transition shape,
      // so we keep it fixed rather than reducing it
      // with filter intensity.
      blending:
          blending,
    );
  }

  bool get isNeutral {
    return shadows.isNeutral &&
        midtones.isNeutral &&
        highlights.isNeutral;
  }
}