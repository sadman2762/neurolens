import 'color_adjustment.dart';
import 'color_grading.dart';
import 'filter_effects.dart';
import 'hsl_adjustment.dart';
import 'light_adjustment.dart';
import 'tone_curve.dart';

class FilterRecipe {
  const FilterRecipe({
    required this.id,
    required this.name,

    this.lutAsset,
    this.toneCurve = ToneCurve.identity,
    this.hsl = HslAdjustments.neutral,
    this.colorGrading = ColorGrading.neutral,
    this.effects = FilterEffects.neutral,
    this.light = const LightAdjustment(),
    this.color = const ColorAdjustment(),

    this.defaultIntensity = 0.55,
  });

  // ===========================================================================
  // BASIC
  // ===========================================================================

  final String id;
  final String name;

  final String? lutAsset;

  // ===========================================================================
  // TONE CURVE
  // ===========================================================================

  final ToneCurve toneCurve;

  // ===========================================================================
  // SELECTIVE HSL
  // ===========================================================================

  final HslAdjustments hsl;

  // ===========================================================================
  // COLOR GRADING
  // ===========================================================================

  final ColorGrading colorGrading;

  // ===========================================================================
  // EFFECTS
  // ===========================================================================

  final FilterEffects effects;

  // ===========================================================================
  // LIGHT
  // ===========================================================================

  final LightAdjustment light;

  // ===========================================================================
  // GLOBAL COLOR / WHITE BALANCE
  // ===========================================================================

  final ColorAdjustment color;

  // ===========================================================================
  // DEFAULT INTENSITY
  // ===========================================================================

  final double defaultIntensity;

  // ===========================================================================
  // INTENSITY
  // ===========================================================================

  FilterRecipe withIntensity(
    double intensity,
  ) {
    final t = intensity.clamp(
      0.0,
      1.0,
    );

    return FilterRecipe(
      id: id,
      name: name,

      lutAsset: lutAsset,

      toneCurve: toneCurve.withIntensity(
        t,
      ),

      hsl: hsl.withIntensity(
        t,
      ),

      colorGrading: colorGrading.withIntensity(
        t,
      ),

      effects: effects.withIntensity(
        t,
      ),

      light: light.withIntensity(
        t,
      ),

      color: color.withIntensity(
        t,
      ),

      defaultIntensity: defaultIntensity,
    );
  }
}