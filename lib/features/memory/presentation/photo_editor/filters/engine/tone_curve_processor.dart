import 'tone_curve.dart';

class ToneCurveProcessor {
  const ToneCurveProcessor._();

  static double apply(
    double value,
    ToneCurve curve,
  ) {
    final input = value.clamp(
      0.0,
      1.0,
    );

    final points = curve.points;

    if (points.length < 2) {
      return input;
    }

    if (input <= points.first.x) {
      return points.first.y.clamp(
        0.0,
        1.0,
      );
    }

    if (input >= points.last.x) {
      return points.last.y.clamp(
        0.0,
        1.0,
      );
    }

    for (
      var i = 0;
      i < points.length - 1;
      i++
    ) {
      final start = points[i];
      final end = points[i + 1];

      if (input >= start.x &&
          input <= end.x) {
        final range =
            end.x -
            start.x;

        if (range.abs() <= 0.000001) {
          return start.y.clamp(
            0.0,
            1.0,
          );
        }

        final t =
            (
              (input - start.x) /
              range
            ).clamp(
              0.0,
              1.0,
            );

        // Smooth interpolation instead of a hard
        // straight-line transition.
        final smoothT =
            t *
            t *
            (
              3.0 -
              (2.0 * t)
            );

        final output =
            start.y +
            (
              (end.y - start.y) *
              smoothT
            );

        return output.clamp(
          0.0,
          1.0,
        );
      }
    }

    return input;
  }

  static List<double> applyRgb({
    required double r,
    required double g,
    required double b,
    required ToneCurve curve,
  }) {
    return [
      apply(
        r,
        curve,
      ),
      apply(
        g,
        curve,
      ),
      apply(
        b,
        curve,
      ),
    ];
  }

  static List<double> applyLuminancePreserving({
    required double r,
    required double g,
    required double b,
    required ToneCurve curve,
  }) {
    final red = r.clamp(
      0.0,
      1.0,
    );

    final green = g.clamp(
      0.0,
      1.0,
    );

    final blue = b.clamp(
      0.0,
      1.0,
    );

    final luminance =
        (
          (red * 0.2126) +
          (green * 0.7152) +
          (blue * 0.0722)
        ).clamp(
          0.0,
          1.0,
        );

    final curvedLuminance =
        apply(
      luminance,
      curve,
    );

    if (luminance <= 0.000001) {
      return [
        curvedLuminance,
        curvedLuminance,
        curvedLuminance,
      ];
    }

    final ratio =
        curvedLuminance /
        luminance;

    return [
      (red * ratio).clamp(
        0.0,
        1.0,
      ),
      (green * ratio).clamp(
        0.0,
        1.0,
      ),
      (blue * ratio).clamp(
        0.0,
        1.0,
      ),
    ];
  }
}