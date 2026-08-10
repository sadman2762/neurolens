import 'dart:math' as math;

import 'hsl_adjustment.dart';

class HslProcessor {
  const HslProcessor._();

  static List<double> apply({
    required double r,
    required double g,
    required double b,
    required HslAdjustments adjustments,
  }) {
    if (adjustments.isNeutral) {
      return [
        r.clamp(0.0, 1.0),
        g.clamp(0.0, 1.0),
        b.clamp(0.0, 1.0),
      ];
    }

    final hsl = _rgbToHsl(
      r.clamp(0.0, 1.0),
      g.clamp(0.0, 1.0),
      b.clamp(0.0, 1.0),
    );

    var hue = hsl.$1;
    var saturation = hsl.$2;
    var luminance = hsl.$3;

    // Blend contributions from nearby HSL ranges.
    double hueShift = 0.0;
    double saturationShift = 0.0;
    double luminanceShift = 0.0;
    double totalWeight = 0.0;

    for (final adjustment in adjustments.all) {
      if (adjustment.isNeutral) {
        continue;
      }

      final centerHue =
          _centerHueForRange(
        adjustment.range,
      );

      final distance =
          _circularHueDistance(
        hue,
        centerHue,
      );

      // Each HSL band influences roughly ±45° around its center.
      const radius = 0.125;

      if (distance >= radius) {
        continue;
      }

      final normalized =
          1.0 -
          (
            distance /
            radius
          ).clamp(
            0.0,
            1.0,
          );

      final weight =
          _smoothStep(
        normalized,
      );

      hueShift +=
          adjustment.hue *
          weight;

      saturationShift +=
          adjustment.saturation *
          weight;

      luminanceShift +=
          adjustment.luminance *
          weight;

      totalWeight += weight;
    }

    if (totalWeight > 0.000001) {
      hueShift /= totalWeight;
      saturationShift /= totalWeight;
      luminanceShift /= totalWeight;

      // Hue adjustment uses a controlled scale.
      //
      // ±1.0 means approximately ±30 degrees.
      hue +=
          hueShift *
          (30.0 / 360.0);

      saturation +=
          saturationShift *
          0.55;

      luminance +=
          luminanceShift *
          0.40;
    }

    hue = _wrapHue(
      hue,
    );

    saturation =
        saturation.clamp(
      0.0,
      1.0,
    );

    luminance =
        luminance.clamp(
      0.0,
      1.0,
    );

    return _hslToRgb(
      hue,
      saturation,
      luminance,
    );
  }

  static double _centerHueForRange(
    HslColorRange range,
  ) {
    switch (range) {
      case HslColorRange.red:
        return 0.0;

      case HslColorRange.orange:
        return 30.0 / 360.0;

      case HslColorRange.yellow:
        return 60.0 / 360.0;

      case HslColorRange.green:
        return 120.0 / 360.0;

      case HslColorRange.aqua:
        return 180.0 / 360.0;

      case HslColorRange.blue:
        return 240.0 / 360.0;

      case HslColorRange.purple:
        return 275.0 / 360.0;

      case HslColorRange.magenta:
        return 315.0 / 360.0;
    }
  }

  static double _circularHueDistance(
    double a,
    double b,
  ) {
    final direct =
        (a - b).abs();

    return math.min(
      direct,
      1.0 - direct,
    );
  }

  static double _smoothStep(
    double x,
  ) {
    final t = x.clamp(
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

  static double _wrapHue(
    double hue,
  ) {
    var result = hue % 1.0;

    if (result < 0.0) {
      result += 1.0;
    }

    return result;
  }

  static (double, double, double) _rgbToHsl(
    double r,
    double g,
    double b,
  ) {
    final maxValue =
        math.max(
      r,
      math.max(
        g,
        b,
      ),
    );

    final minValue =
        math.min(
      r,
      math.min(
        g,
        b,
      ),
    );

    final delta =
        maxValue -
        minValue;

    final luminance =
        (
          maxValue +
          minValue
        ) /
        2.0;

    if (delta <= 0.000001) {
      return (
        0.0,
        0.0,
        luminance,
      );
    }

    final saturation =
        luminance > 0.5
            ? delta /
                (
                  2.0 -
                  maxValue -
                  minValue
                )
            : delta /
                (
                  maxValue +
                  minValue
                );

    double hue;

    if (maxValue == r) {
      hue =
          (
            (g - b) /
            delta
          ) +
          (
            g < b
                ? 6.0
                : 0.0
          );
    } else if (maxValue == g) {
      hue =
          (
            (b - r) /
            delta
          ) +
          2.0;
    } else {
      hue =
          (
            (r - g) /
            delta
          ) +
          4.0;
    }

    hue /= 6.0;

    return (
      _wrapHue(
        hue,
      ),
      saturation.clamp(
        0.0,
        1.0,
      ),
      luminance.clamp(
        0.0,
        1.0,
      ),
    );
  }

  static List<double> _hslToRgb(
    double h,
    double s,
    double l,
  ) {
    if (s <= 0.000001) {
      return [
        l,
        l,
        l,
      ];
    }

    final q =
        l < 0.5
            ? l *
                (
                  1.0 +
                  s
                )
            : l +
                s -
                (
                  l *
                  s
                );

    final p =
        (
          2.0 *
          l
        ) -
        q;

    final red =
        _hueToRgb(
      p,
      q,
      h +
          (1.0 / 3.0),
    );

    final green =
        _hueToRgb(
      p,
      q,
      h,
    );

    final blue =
        _hueToRgb(
      p,
      q,
      h -
          (1.0 / 3.0),
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

  static double _hueToRgb(
    double p,
    double q,
    double t,
  ) {
    var hue = t;

    if (hue < 0.0) {
      hue += 1.0;
    }

    if (hue > 1.0) {
      hue -= 1.0;
    }

    if (hue < 1.0 / 6.0) {
      return p +
          (
            (q - p) *
            6.0 *
            hue
          );
    }

    if (hue < 1.0 / 2.0) {
      return q;
    }

    if (hue < 2.0 / 3.0) {
      return p +
          (
            (q - p) *
            (
              (2.0 / 3.0) -
              hue
            ) *
            6.0
          );
    }

    return p;
  }
}