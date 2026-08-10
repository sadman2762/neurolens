class FilterEffects {
  const FilterEffects({
    this.grain = 0.0,
    this.vignette = 0.0,
    this.centerGlow = 0.0,
    this.sharpen = 0.0,
    this.halation = 0.0,
  });

  /// 0.0 = none
  /// 1.0 = strongest
  final double grain;

  /// 0.0 = none
  /// 1.0 = strongest edge darkening
  final double vignette;

  /// 0.0 = none
  /// 1.0 = strongest center glow
  final double centerGlow;

  /// 0.0 = none
  /// 1.0 = strongest sharpening
  final double sharpen;

  /// 0.0 = none
  /// 1.0 = strongest red/orange highlight bloom
  final double halation;

  static const neutral = FilterEffects();

  FilterEffects withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return FilterEffects(
      grain: grain * t,
      vignette: vignette * t,
      centerGlow: centerGlow * t,
      sharpen: sharpen * t,
      halation: halation * t,
    );
  }

  bool get isNeutral {
    return grain.abs() <= 0.0001 &&
        vignette.abs() <= 0.0001 &&
        centerGlow.abs() <= 0.0001 &&
        sharpen.abs() <= 0.0001 &&
        halation.abs() <= 0.0001;
  }
}