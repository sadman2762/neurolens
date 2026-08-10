enum NeuroLensFilterType {
  color,
  grain,
  zoomBlur,
  wideAngle,
  wavy,
}

class NeuroLensFilter {
  const NeuroLensFilter({
    required this.id,
    required this.name,
    required this.type,
    this.matrix,
    this.defaultIntensity = 1.0,
  });

  final String id;
  final String name;
  final NeuroLensFilterType type;

  /// 4x5 color matrix.
  ///
  /// Used by normal color-based filters.
  final List<double>? matrix;

  /// Value from 0.0 to 1.0.
  final double defaultIntensity;

  bool get isNormal => id == 'normal';

  bool get isColorFilter =>
      type == NeuroLensFilterType.color;

  bool get isAdvancedEffect =>
      type != NeuroLensFilterType.color;
}