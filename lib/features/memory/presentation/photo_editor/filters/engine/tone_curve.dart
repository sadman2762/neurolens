class ToneCurvePoint {
  const ToneCurvePoint({
    required this.x,
    required this.y,
  });

  /// Input luminance position.
  ///
  /// Range:
  /// 0.0 = black
  /// 1.0 = white
  final double x;

  /// Output luminance position.
  ///
  /// Range:
  /// 0.0 = black
  /// 1.0 = white
  final double y;

  ToneCurvePoint scaled(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    // Interpolate between identity and the target point.
    final identityY = x;

    return ToneCurvePoint(
      x: x,
      y: identityY +
          ((y - identityY) * t),
    );
  }
}

class ToneCurve {
  const ToneCurve({
    required this.points,
  });

  /// Curve control points ordered from left to right.
  ///
  /// Example identity curve:
  ///
  /// (0,0)
  /// (0.25,0.25)
  /// (0.5,0.5)
  /// (0.75,0.75)
  /// (1,1)
  final List<ToneCurvePoint> points;

  // ===========================================================================
  // PRESETS
  // ===========================================================================

  static const identity = ToneCurve(
    points: [
      ToneCurvePoint(
        x: 0.0,
        y: 0.0,
      ),
      ToneCurvePoint(
        x: 0.25,
        y: 0.25,
      ),
      ToneCurvePoint(
        x: 0.50,
        y: 0.50,
      ),
      ToneCurvePoint(
        x: 0.75,
        y: 0.75,
      ),
      ToneCurvePoint(
        x: 1.0,
        y: 1.0,
      ),
    ],
  );

  /// Soft faded curve.
  ///
  /// Blacks are lifted and highlights are slightly softened.
  static const fade = ToneCurve(
    points: [
      ToneCurvePoint(
        x: 0.0,
        y: 0.08,
      ),
      ToneCurvePoint(
        x: 0.20,
        y: 0.24,
      ),
      ToneCurvePoint(
        x: 0.50,
        y: 0.52,
      ),
      ToneCurvePoint(
        x: 0.80,
        y: 0.78,
      ),
      ToneCurvePoint(
        x: 1.0,
        y: 0.95,
      ),
    ],
  );

  /// Gentle contrast S-curve.
  static const softContrast = ToneCurve(
    points: [
      ToneCurvePoint(
        x: 0.0,
        y: 0.0,
      ),
      ToneCurvePoint(
        x: 0.20,
        y: 0.16,
      ),
      ToneCurvePoint(
        x: 0.50,
        y: 0.50,
      ),
      ToneCurvePoint(
        x: 0.80,
        y: 0.84,
      ),
      ToneCurvePoint(
        x: 1.0,
        y: 1.0,
      ),
    ],
  );

  /// Strong cinematic contrast.
  static const strongContrast = ToneCurve(
    points: [
      ToneCurvePoint(
        x: 0.0,
        y: 0.0,
      ),
      ToneCurvePoint(
        x: 0.18,
        y: 0.10,
      ),
      ToneCurvePoint(
        x: 0.50,
        y: 0.50,
      ),
      ToneCurvePoint(
        x: 0.82,
        y: 0.90,
      ),
      ToneCurvePoint(
        x: 1.0,
        y: 1.0,
      ),
    ],
  );

  /// Dark cinematic curve.
  ///
  /// Useful later for Midnight.
  static const midnight = ToneCurve(
    points: [
      ToneCurvePoint(
        x: 0.0,
        y: 0.0,
      ),
      ToneCurvePoint(
        x: 0.20,
        y: 0.10,
      ),
      ToneCurvePoint(
        x: 0.48,
        y: 0.39,
      ),
      ToneCurvePoint(
        x: 0.78,
        y: 0.72,
      ),
      ToneCurvePoint(
        x: 1.0,
        y: 0.93,
      ),
    ],
  );

  // ===========================================================================
  // INTENSITY
  // ===========================================================================

  ToneCurve withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    if (t <= 0.001) {
      return identity;
    }

    return ToneCurve(
      points: points
          .map(
            (point) => point.scaled(
              t,
            ),
          )
          .toList(
            growable: false,
          ),
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  bool get isValid {
    if (points.length < 2) {
      return false;
    }

    double previousX = -1;

    for (final point in points) {
      if (point.x < 0 ||
          point.x > 1 ||
          point.y < 0 ||
          point.y > 1) {
        return false;
      }

      if (point.x <= previousX) {
        return false;
      }

      previousX = point.x;
    }

    return true;
  }
}