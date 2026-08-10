import 'color_grading_processor.dart';
import 'filter_recipe.dart';
import 'hsl_processor.dart';
import 'tone_curve_processor.dart';

class FilterPixelPipeline {
  const FilterPixelPipeline._();

  static List<double> apply({
    required double r,
    required double g,
    required double b,
    required FilterRecipe recipe,
  }) {
    var red = r.clamp(0.0, 1.0);
    var green = g.clamp(0.0, 1.0);
    var blue = b.clamp(0.0, 1.0);

    // =========================================================================
    // 1. LIGHT
    // =========================================================================

    final lightResult = recipe.light.apply(
      r: red,
      g: green,
      b: blue,
    );

    red = lightResult[0];
    green = lightResult[1];
    blue = lightResult[2];

    // =========================================================================
    // 2. WHITE BALANCE / GLOBAL COLOR
    // =========================================================================

    final colorResult = recipe.color.apply(
      r: red,
      g: green,
      b: blue,
    );

    red = colorResult[0];
    green = colorResult[1];
    blue = colorResult[2];

    // =========================================================================
    // 3. TONE CURVE
    // =========================================================================

    final toneResult =
        ToneCurveProcessor.applyLuminancePreserving(
      r: red,
      g: green,
      b: blue,
      curve: recipe.toneCurve,
    );

    red = toneResult[0];
    green = toneResult[1];
    blue = toneResult[2];

    // =========================================================================
    // 4. SELECTIVE HSL
    // =========================================================================

    final hslResult = HslProcessor.apply(
      r: red,
      g: green,
      b: blue,
      adjustments: recipe.hsl,
    );

    red = hslResult[0];
    green = hslResult[1];
    blue = hslResult[2];

    // =========================================================================
    // 5. SHADOW / MIDTONE / HIGHLIGHT GRADING
    // =========================================================================

    final gradingResult =
        ColorGradingProcessor.apply(
      r: red,
      g: green,
      b: blue,
      grading: recipe.colorGrading,
    );

    red = gradingResult[0];
    green = gradingResult[1];
    blue = gradingResult[2];

    // =========================================================================
    // FINAL CLAMP
    // =========================================================================

    return [
      red.clamp(0.0, 1.0),
      green.clamp(0.0, 1.0),
      blue.clamp(0.0, 1.0),
    ];
  }
}