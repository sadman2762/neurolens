class GrainProcessor {
  const GrainProcessor._();

  static List<double> apply({
    required double r,
    required double g,
    required double b,
    required int x,
    required int y,
    required double grain,
  }) {
    final strength = grain.clamp(
      0.0,
      1.0,
    );

    if (strength <= 0.0001) {
      return [
        r.clamp(0.0, 1.0),
        g.clamp(0.0, 1.0),
        b.clamp(0.0, 1.0),
      ];
    }

    // Deterministic pseudo-random noise based on pixel coordinates.
    //
    // This avoids using Random() for every pixel and keeps the
    // result stable between runs.
    final hash = _hash(
      x,
      y,
    );

    // Convert 0..1 noise into -1..1.
    final noise =
        (hash * 2.0) - 1.0;

    // Grain is intentionally subtle.
    final amount =
        noise *
        strength *
        0.075;

    // Slight luminance weighting:
    // grain is strongest in midtones and weaker in pure
    // blacks/highlights.
    final luminance =
        (
          (r * 0.2126) +
          (g * 0.7152) +
          (b * 0.0722)
        ).clamp(
          0.0,
          1.0,
        );

    final midtoneMask =
        1.0 -
        (
          ((luminance - 0.5).abs()) *
          1.7
        ).clamp(
          0.0,
          1.0,
        );

    final weightedNoise =
        amount *
        (
          0.35 +
          (midtoneMask * 0.65)
        );

    return [
      (r + weightedNoise).clamp(
        0.0,
        1.0,
      ),
      (g + weightedNoise).clamp(
        0.0,
        1.0,
      ),
      (b + weightedNoise).clamp(
        0.0,
        1.0,
      ),
    ];
  }

  static double _hash(
    int x,
    int y,
  ) {
    var value =
        (x * 374761393) ^
        (y * 668265263);

    value =
        (value ^
            (value >> 13)) *
        1274126177;

    value =
        value ^
        (value >> 16);

    final normalized =
        (value & 0x7fffffff) /
        0x7fffffff;

    return normalized.clamp(
      0.0,
      1.0,
    );
  }
}