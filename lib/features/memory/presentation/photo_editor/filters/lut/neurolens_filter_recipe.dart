class NeuroLensFilterRecipe {
  const NeuroLensFilterRecipe({
    required this.id,
    required this.name,
    this.exposure = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.temperature = 0,
    this.tint = 0,
    this.fade = 0,
    this.vignette = 0,
    this.grain = 0,
    this.sharpen = 0,
    this.shadowLift = 0,
    this.highlightRollOff = 0,
  });

  final String id;
  final String name;

  /// Suggested ranges:
  ///
  /// exposure          -1.0 .. 1.0
  /// contrast          -1.0 .. 1.0
  /// saturation        -1.0 .. 1.0
  /// temperature       -1.0 .. 1.0
  /// tint              -1.0 .. 1.0
  /// fade               0.0 .. 1.0
  /// vignette           0.0 .. 1.0
  /// grain              0.0 .. 1.0
  /// sharpen            0.0 .. 1.0
  /// shadowLift         0.0 .. 1.0
  /// highlightRollOff   0.0 .. 1.0

  final double exposure;
  final double contrast;
  final double saturation;
  final double temperature;
  final double tint;

  final double fade;
  final double vignette;
  final double grain;
  final double sharpen;

  final double shadowLift;
  final double highlightRollOff;

  NeuroLensFilterRecipe withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return NeuroLensFilterRecipe(
      id: id,
      name: name,
      exposure: exposure * t,
      contrast: contrast * t,
      saturation: saturation * t,
      temperature: temperature * t,
      tint: tint * t,
      fade: fade * t,
      vignette: vignette * t,
      grain: grain * t,
      sharpen: sharpen * t,
      shadowLift: shadowLift * t,
      highlightRollOff:
          highlightRollOff * t,
    );
  }
}