import '../engine/color_adjustment.dart';
import '../engine/color_grading.dart';
import '../engine/filter_effects.dart';
import '../engine/filter_recipe.dart';
import '../engine/hsl_adjustment.dart';
import '../engine/light_adjustment.dart';
import '../engine/tone_curve.dart';

class NeuroLensFilterPresets {
  const NeuroLensFilterPresets._();

  // ===========================================================================
  // NORMAL
  // ===========================================================================

  static const normal = FilterRecipe(
    id: 'normal',
    name: 'Normal',
    defaultIntensity: 0.0,
  );

  // ===========================================================================
  // MIDNIGHT
  // ===========================================================================

  static const midnight = FilterRecipe(
    id: 'midnight',
    name: 'Midnight',

    // LUT will be added later.
    lutAsset: null,

    // -----------------------------------------------------------------------
    // TONE CURVE
    // -----------------------------------------------------------------------

    toneCurve: ToneCurve.midnight,

    // -----------------------------------------------------------------------
    // LIGHT
    // -----------------------------------------------------------------------

    light: LightAdjustment(
      exposure: -0.08,
      contrast: 0.16,
      highlights: -0.14,
      shadows: -0.10,
      whites: -0.05,
      blacks: -0.16,
    ),

    // -----------------------------------------------------------------------
    // COLOR / WHITE BALANCE
    // -----------------------------------------------------------------------

    color: ColorAdjustment(
      // Very small cool shift.
      // We don't want the old blue-looking Midnight.
      temperature: -0.035,
      tint: 0.005,

      // Slightly reduce overall color intensity.
      saturation: -0.06,
      vibrance: -0.02,
    ),

    // -----------------------------------------------------------------------
    // SELECTIVE HSL
    // -----------------------------------------------------------------------

    hsl: HslAdjustments(
      red: HslAdjustment(
        range: HslColorRange.red,
        saturation: -0.03,
        luminance: -0.02,
      ),

      orange: HslAdjustment(
        range: HslColorRange.orange,

        // Preserve skin better.
        saturation: -0.02,
        luminance: 0.025,
      ),

      yellow: HslAdjustment(
        range: HslColorRange.yellow,
        saturation: -0.08,
        luminance: -0.03,
      ),

      green: HslAdjustment(
        range: HslColorRange.green,
        saturation: -0.12,
        luminance: -0.06,
      ),

      aqua: HslAdjustment(
        range: HslColorRange.aqua,
        saturation: -0.04,
        luminance: -0.05,
      ),

      blue: HslAdjustment(
        range: HslColorRange.blue,

        // Keep blues dark rather than highly saturated.
        saturation: -0.08,
        luminance: -0.10,
      ),

      purple: HslAdjustment(
        range: HslColorRange.purple,
        saturation: -0.08,
      ),

      magenta: HslAdjustment(
        range: HslColorRange.magenta,
        saturation: -0.06,
      ),
    ),

    // -----------------------------------------------------------------------
    // COLOR GRADING
    // -----------------------------------------------------------------------

    colorGrading: ColorGrading(
      // Slightly cool shadows.
      shadows: ColorGrade(
        hue: 0.60,
        saturation: 0.055,
        luminance: -0.035,
      ),

      // Keep midtones almost neutral.
      midtones: ColorGrade(
        hue: 0.58,
        saturation: 0.015,
        luminance: -0.015,
      ),

      // Tiny warm highlight lift helps faces/lights
      // stay alive inside the dark grade.
      highlights: ColorGrade(
        hue: 0.10,
        saturation: 0.025,
        luminance: 0.035,
      ),

      balance: -0.08,
      blending: 0.72,
    ),

    // -----------------------------------------------------------------------
    // EFFECTS
    // -----------------------------------------------------------------------

    effects: FilterEffects(
      // Stronger outer darkness.
      vignette: 0.56,

      // Keeps center brighter / glowing.
      centerGlow: 0.22,

      // Very mild sharpening.
      sharpen: 0.045,

      grain: 0.015,

      // Midnight should not have obvious warm halation.
      halation: 0.0,
    ),

    // Your desired starting intensity.
    defaultIntensity: 0.55,
  );

  // ===========================================================================
  // ALL
  // ===========================================================================

  static const all = [
    normal,
    midnight,
  ];

  // ===========================================================================
  // LOOKUP
  // ===========================================================================

  static FilterRecipe? byId(
    String id,
  ) {
    for (final preset in all) {
      if (preset.id == id) {
        return preset;
      }
    }

    return null;
  }

  static FilterRecipe? byName(
    String name,
  ) {
    for (final preset in all) {
      if (preset.name == name) {
        return preset;
      }
    }

    return null;
  }
}