enum HslColorRange {
  red,
  orange,
  yellow,
  green,
  aqua,
  blue,
  purple,
  magenta,
}

class HslAdjustment {
  const HslAdjustment({
    required this.range,
    this.hue = 0.0,
    this.saturation = 0.0,
    this.luminance = 0.0,
  });

  final HslColorRange range;

  /// Suggested normalized range:
  ///
  /// -1.0 = maximum shift left
  ///  0.0 = unchanged
  ///  1.0 = maximum shift right
  final double hue;

  /// -1.0 = desaturate strongly
  ///  0.0 = unchanged
  ///  1.0 = saturate strongly
  final double saturation;

  /// -1.0 = darker
  ///  0.0 = unchanged
  ///  1.0 = brighter
  final double luminance;

  HslAdjustment withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return HslAdjustment(
      range: range,
      hue: hue * t,
      saturation: saturation * t,
      luminance: luminance * t,
    );
  }

  bool get isNeutral {
    return hue.abs() <= 0.0001 &&
        saturation.abs() <= 0.0001 &&
        luminance.abs() <= 0.0001;
  }
}

class HslAdjustments {
  const HslAdjustments({
    this.red = const HslAdjustment(
      range: HslColorRange.red,
    ),
    this.orange = const HslAdjustment(
      range: HslColorRange.orange,
    ),
    this.yellow = const HslAdjustment(
      range: HslColorRange.yellow,
    ),
    this.green = const HslAdjustment(
      range: HslColorRange.green,
    ),
    this.aqua = const HslAdjustment(
      range: HslColorRange.aqua,
    ),
    this.blue = const HslAdjustment(
      range: HslColorRange.blue,
    ),
    this.purple = const HslAdjustment(
      range: HslColorRange.purple,
    ),
    this.magenta = const HslAdjustment(
      range: HslColorRange.magenta,
    ),
  });

  final HslAdjustment red;
  final HslAdjustment orange;
  final HslAdjustment yellow;
  final HslAdjustment green;
  final HslAdjustment aqua;
  final HslAdjustment blue;
  final HslAdjustment purple;
  final HslAdjustment magenta;

  static const neutral = HslAdjustments();

  HslAdjustments withIntensity(
    double intensity,
  ) {
    return HslAdjustments(
      red: red.withIntensity(
        intensity,
      ),
      orange: orange.withIntensity(
        intensity,
      ),
      yellow: yellow.withIntensity(
        intensity,
      ),
      green: green.withIntensity(
        intensity,
      ),
      aqua: aqua.withIntensity(
        intensity,
      ),
      blue: blue.withIntensity(
        intensity,
      ),
      purple: purple.withIntensity(
        intensity,
      ),
      magenta: magenta.withIntensity(
        intensity,
      ),
    );
  }

  List<HslAdjustment> get all => [
        red,
        orange,
        yellow,
        green,
        aqua,
        blue,
        purple,
        magenta,
      ];

  bool get isNeutral {
    return all.every(
      (adjustment) =>
          adjustment.isNeutral,
    );
  }
}