import 'filter_recipe.dart';

class FilterEngineResult {
  const FilterEngineResult({
    required this.recipe,
    required this.intensity,
  });

  final FilterRecipe recipe;
  final double intensity;
}

class FilterEngine {
  const FilterEngine._();

  /// Resolves a filter recipe at the requested visible intensity.
  ///
  /// Example:
  /// intensity 0.0  -> identity / no effect
  /// intensity 0.55 -> 55% of recipe strength
  /// intensity 1.0  -> full recipe
  static FilterEngineResult resolve({
    required FilterRecipe recipe,
    required double intensity,
  }) {
    final normalizedIntensity = intensity.clamp(
      0.0,
      1.0,
    );

    final resolvedRecipe =
        recipe.withIntensity(
      normalizedIntensity,
    );

    return FilterEngineResult(
      recipe: resolvedRecipe,
      intensity: normalizedIntensity,
    );
  }

  /// Resolves a recipe using its own default intensity.
  static FilterEngineResult resolveDefault({
    required FilterRecipe recipe,
  }) {
    return resolve(
      recipe: recipe,
      intensity: recipe.defaultIntensity,
    );
  }
}