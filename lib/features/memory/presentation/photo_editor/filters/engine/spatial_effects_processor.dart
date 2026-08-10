import 'dart:math' as math;

import 'filter_effects.dart';

class SpatialEffectsProcessor {
  const SpatialEffectsProcessor._();

  static List<double> apply({
    required double r,
    required double g,
    required double b,
    required int x,
    required int y,
    required int width,
    required int height,
    required FilterEffects effects,
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

    if (width <= 1 ||
        height <= 1) {
      return [
        red,
        green,
        blue,
      ];
    }

    // =========================================================================
    // IMAGE POSITION
    // =========================================================================

    final centerX =
        (width - 1) / 2.0;

    final centerY =
        (height - 1) / 2.0;

    final dx =
        x - centerX;

    final dy =
        y - centerY;

    final maxDistance =
        math.sqrt(
      (centerX * centerX) +
          (centerY * centerY),
    );

    if (maxDistance <= 0.000001) {
      return [
        red,
        green,
        blue,
      ];
    }

    final normalizedDistance =
        (
          math.sqrt(
                (dx * dx) +
                    (dy * dy),
              ) /
              maxDistance
        ).clamp(
          0.0,
          1.0,
        );

    // =========================================================================
    // CENTER PROTECTION
    // =========================================================================
    //
    // Keeps the central subject / selfie brighter.
    //
    // Near center:
    // strong protection
    //
    // Moving outward:
    // protection gradually disappears
    // =========================================================================

    final centerProtection =
        1.0 -
        _smoothStep(
          0.08,
          0.58,
          normalizedDistance,
        );

    // =========================================================================
    // CENTER GLOW
    // =========================================================================

    if (effects.centerGlow > 0.0001) {
      final glowMask =
          1.0 -
          _smoothStep(
            0.05,
            0.58,
            normalizedDistance,
          );

      final smoothGlow =
          _smoothCurve(
        glowMask,
      );

      final glow =
          effects.centerGlow *
          0.52 *
          smoothGlow;

      // Slightly warm / skin-friendly.
      red +=
          glow *
          1.08;

      green +=
          glow *
          1.00;

      blue +=
          glow *
          0.88;
    }

    // =========================================================================
    // CENTER MIDTONE LIFT
    // =========================================================================
    //
    // Keeps a face/person readable.
    //
    // It avoids lifting already-bright highlights too much.
    // =========================================================================

    final centerLuminance =
        _luminance(
      red,
      green,
      blue,
    );

    final subjectLiftMask =
        centerProtection *
        (
          1.0 -
          _smoothStep(
            0.72,
            0.96,
            centerLuminance,
          )
        );

    final subjectLift =
        effects.centerGlow *
        0.45 *
        subjectLiftMask;

    red +=
        subjectLift *
        1.03;

    green +=
        subjectLift;

    blue +=
        subjectLift *
        0.94;

    // =========================================================================
    // NIGHT EDGE DARKNESS
    // =========================================================================
    //
    // Stronger than a classic vignette.
    //
    // Darkness starts earlier and increases significantly
    // toward the sides and corners.
    // =========================================================================

    if (effects.vignette > 0.0001) {
      final rawEdgeMask =
          _smoothStep(
        0.24,
        1.0,
        normalizedDistance,
      );

      final edgeMask =
          math.pow(
            rawEdgeMask,
            1.55,
          ).toDouble();

      final nightDarkness =
          (
            0.18 +
            (
              effects.vignette *
              0.82
            )
          ) *
          edgeMask;

      final darkness =
          nightDarkness.clamp(
        0.0,
        0.82,
      );

      final multiplier =
          1.0 -
          darkness;

      red *=
          multiplier;

      green *=
          multiplier;

      blue *=
          multiplier;
    }

    // =========================================================================
    // OUTER NIGHT EXPOSURE
    // =========================================================================
    //
    // This makes the outside of the image feel like actual
    // night rather than merely having a vignette overlay.
    // =========================================================================

    final rawOuterMask =
        _smoothStep(
      0.46,
      1.0,
      normalizedDistance,
    );

    final outerMask =
        math.pow(
          rawOuterMask,
          1.30,
        ).toDouble();

    if (effects.vignette > 0.0001) {
      final outerStrength =
          effects.vignette.clamp(
        0.0,
        1.0,
      );

      final outerExposure =
          _lerp(
        1.0,
        0.64,
        outerMask *
            outerStrength,
      );

      red *=
          outerExposure;

      green *=
          outerExposure;

      blue *=
          outerExposure;
    }

    // =========================================================================
    // DEEPEN OUTER BLACKS
    // =========================================================================

    final outerLuminance =
        _luminance(
      red,
      green,
      blue,
    );

    final shadowMask =
        1.0 -
        _smoothStep(
          0.20,
          0.68,
          outerLuminance,
        );

    final deepBlackAmount =
        outerMask *
        shadowMask *
        effects.vignette.clamp(
          0.0,
          1.0,
        ) *
        0.16;

    red -=
        deepBlackAmount;

    green -=
        deepBlackAmount;

    blue -=
        deepBlackAmount;

    // =========================================================================
    // SUBTLE COOL NIGHT EDGE
    // =========================================================================
    //
    // Very small color shift.
    //
    // This should feel like a night environment,
    // but should NOT make the photo strongly blue.
    // =========================================================================

    final coolEdge =
        outerMask *
        effects.vignette.clamp(
          0.0,
          1.0,
        );

    red -=
        0.010 *
        coolEdge;

    green -=
        0.004 *
        coolEdge;

    blue +=
        0.008 *
        coolEdge;

    // =========================================================================
    // CENTER HIGHLIGHT PRESERVATION
    // =========================================================================

    final highlightLuminance =
        _luminance(
      red,
      green,
      blue,
    );

    final centerHighlight =
        centerProtection *
        _smoothStep(
          0.58,
          0.90,
          highlightLuminance,
        );

    final highlightBoost =
        effects.centerGlow *
        centerHighlight;

    red +=
        0.025 *
        highlightBoost;

    green +=
        0.018 *
        highlightBoost;

    blue +=
        0.010 *
        highlightBoost;

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

  // ===========================================================================
  // LUMINANCE
  // ===========================================================================

  static double _luminance(
    double r,
    double g,
    double b,
  ) {
    return (
      (r * 0.2126) +
      (g * 0.7152) +
      (b * 0.0722)
    ).clamp(
      0.0,
      1.0,
    );
  }

  // ===========================================================================
  // SMOOTH STEP
  // ===========================================================================

  static double _smoothStep(
    double edge0,
    double edge1,
    double value,
  ) {
    if ((edge1 - edge0).abs() <=
        0.000001) {
      return value >= edge1
          ? 1.0
          : 0.0;
    }

    final t =
        (
          (value - edge0) /
          (edge1 - edge0)
        ).clamp(
          0.0,
          1.0,
        );

    return _smoothCurve(
      t,
    );
  }

  // ===========================================================================
  // SMOOTH CURVE
  // ===========================================================================

  static double _smoothCurve(
    double value,
  ) {
    final t =
        value.clamp(
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

  // ===========================================================================
  // LERP
  // ===========================================================================

  static double _lerp(
    double a,
    double b,
    double t,
  ) {
    final amount =
        t.clamp(
      0.0,
      1.0,
    );

    return a +
        (
          (b - a) *
          amount
        );
  }
}