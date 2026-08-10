import 'dart:math' as math;

import 'neurolens_filter.dart';

class FilterProcessor {
  const FilterProcessor._();

  static const List<double> _identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  /// Returns a color matrix based on filter intensity.
  ///
  /// intensity:
  /// 0.0 = Normal
  /// 1.0 = Full filter
  static List<double> matrixFor({
    required NeuroLensFilter filter,
    required double intensity,
  }) {
    if (!filter.isColorFilter) {
      return _identity;
    }

    final matrix = filter.matrix;

    if (matrix == null || matrix.length != 20) {
      return _identity;
    }

    if (filter.isNormal) {
      return _identity;
    }

    final normalizedIntensity = intensity.clamp(0.0, 1.0);

    return interpolateMatrix(
      from: _identity,
      to: matrix,
      amount: normalizedIntensity,
    );
  }

  /// Same as [matrixFor], but accepts the UI's 0–100 value.
  static List<double> matrixForPercentage({
    required NeuroLensFilter filter,
    required double percentage,
  }) {
    return matrixFor(
      filter: filter,
      intensity: percentageToIntensity(
        percentage,
      ),
    );
  }

  /// Converts:
  ///
  /// 0   -> 0.0
  /// 50  -> 0.5
  /// 100 -> 1.0
  static double percentageToIntensity(
    double percentage,
  ) {
    return (percentage / 100).clamp(
      0.0,
      1.0,
    );
  }

  static double intensityToPercentage(
    double intensity,
  ) {
    return intensity.clamp(
          0.0,
          1.0,
        ) *
        100;
  }

  static List<double> interpolateMatrix({
    required List<double> from,
    required List<double> to,
    required double amount,
  }) {
    if (from.length != 20 || to.length != 20) {
      throw ArgumentError(
        'Color matrices must contain exactly 20 values.',
      );
    }

    final t = amount.clamp(
      0.0,
      1.0,
    );

    return List<double>.generate(
      20,
      (index) {
        return _lerp(
          from[index],
          to[index],
          t,
        );
      },
      growable: false,
    );
  }

  static double _lerp(
    double start,
    double end,
    double amount,
  ) {
    return start +
        ((end - start) * amount);
  }

  /// Useful later for effects like Grain, Zoom Blur, Wavy, etc.
  ///
  /// This gives us a slightly smoother feeling than purely linear intensity.
  static double easedIntensity(
    double intensity,
  ) {
    final value = intensity.clamp(
      0.0,
      1.0,
    );

    return 1 -
        math.pow(
          1 - value,
          2,
        ).toDouble();
  }
}