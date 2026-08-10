import 'neurolens_filter_recipe.dart';

class NeuroLensFilterRecipes {
  const NeuroLensFilterRecipes._();

  // ===========================================================================
  // NORMAL
  // ===========================================================================

  static const normal =
      NeuroLensFilterRecipe(
    id: 'normal',
    name: 'Normal',
  );

  // ===========================================================================
  // FADE
  // ===========================================================================

  static const fade =
      NeuroLensFilterRecipe(
    id: 'fade',
    name: 'Fade',
    exposure: 0.02,
    contrast: -0.18,
    saturation: -0.10,
    fade: 0.38,
    shadowLift: 0.32,
    highlightRollOff: 0.18,
    vignette: 0.03,
    grain: 0.04,
  );

  static const fadeWarm =
      NeuroLensFilterRecipe(
    id: 'fade_warm',
    name: 'Fade Warm',
    exposure: 0.03,
    contrast: -0.15,
    saturation: -0.07,
    temperature: 0.24,
    tint: 0.025,
    fade: 0.34,
    shadowLift: 0.28,
    highlightRollOff: 0.20,
    vignette: 0.03,
    grain: 0.035,
  );

  static const fadeCool =
      NeuroLensFilterRecipe(
    id: 'fade_cool',
    name: 'Fade Cool',
    exposure: 0.02,
    contrast: -0.15,
    saturation: -0.08,
    temperature: -0.22,
    tint: -0.02,
    fade: 0.33,
    shadowLift: 0.30,
    highlightRollOff: 0.18,
    vignette: 0.03,
    grain: 0.035,
  );

  // ===========================================================================
  // SIMPLE
  // ===========================================================================

  static const simple =
      NeuroLensFilterRecipe(
    id: 'simple',
    name: 'Simple',
    exposure: 0.03,
    contrast: 0.10,
    saturation: 0.06,
    shadowLift: 0.04,
    highlightRollOff: 0.08,
    sharpen: 0.10,
  );

  static const simpleWarm =
      NeuroLensFilterRecipe(
    id: 'simple_warm',
    name: 'Simple Warm',
    exposure: 0.04,
    contrast: 0.11,
    saturation: 0.08,
    temperature: 0.17,
    shadowLift: 0.04,
    highlightRollOff: 0.10,
    sharpen: 0.10,
  );

  static const simpleCool =
      NeuroLensFilterRecipe(
    id: 'simple_cool',
    name: 'Simple Cool',
    exposure: 0.03,
    contrast: 0.10,
    saturation: 0.07,
    temperature: -0.17,
    tint: -0.01,
    shadowLift: 0.04,
    highlightRollOff: 0.08,
    sharpen: 0.10,
  );

  // ===========================================================================
  // BOOST
  // ===========================================================================

  static const boost =
      NeuroLensFilterRecipe(
    id: 'boost',
    name: 'Boost',
    exposure: 0.03,
    contrast: 0.25,
    saturation: 0.19,
    shadowLift: -0.05,
    highlightRollOff: 0.12,
    sharpen: 0.22,
    vignette: 0.035,
  );

  static const boostWarm =
      NeuroLensFilterRecipe(
    id: 'boost_warm',
    name: 'Boost Warm',
    exposure: 0.04,
    contrast: 0.24,
    saturation: 0.18,
    temperature: 0.16,
    tint: 0.015,
    shadowLift: -0.04,
    highlightRollOff: 0.14,
    sharpen: 0.22,
    vignette: 0.035,
  );

  static const boostCool =
      NeuroLensFilterRecipe(
    id: 'boost_cool',
    name: 'Boost Cool',
    exposure: 0.03,
    contrast: 0.23,
    saturation: 0.18,
    temperature: -0.15,
    tint: -0.015,
    shadowLift: -0.04,
    highlightRollOff: 0.13,
    sharpen: 0.22,
    vignette: 0.035,
  );

  // ===========================================================================
  // HYPER
  // ===========================================================================

  static const hyper =
      NeuroLensFilterRecipe(
    id: 'hyper',
    name: 'Hyper',
    exposure: 0.02,
    contrast: 0.36,
    saturation: 0.34,
    shadowLift: -0.08,
    highlightRollOff: 0.16,
    sharpen: 0.28,
    vignette: 0.06,
  );

  // ===========================================================================
  // DAZZ CAM
  // ===========================================================================

  static const dazzCam =
      NeuroLensFilterRecipe(
    id: 'dazz_cam',
    name: 'Dazz Cam',
    exposure: 0.05,
    contrast: 0.19,
    saturation: 0.12,
    temperature: 0.14,
    tint: 0.02,
    fade: 0.09,
    shadowLift: 0.08,
    highlightRollOff: 0.26,
    vignette: 0.10,
    grain: 0.12,
    sharpen: 0.06,
  );

  // ===========================================================================
  // EMERALD
  // ===========================================================================

  static const emerald =
      NeuroLensFilterRecipe(
    id: 'emerald',
    name: 'Emerald',
    exposure: 0.01,
    contrast: 0.16,
    saturation: 0.09,
    temperature: -0.06,
    tint: -0.20,
    shadowLift: 0.03,
    highlightRollOff: 0.12,
    vignette: 0.04,
    sharpen: 0.10,
  );

  // ===========================================================================
  // MIDNIGHT
  // ===========================================================================

  static const midnight =
      NeuroLensFilterRecipe(
    id: 'midnight',
    name: 'Midnight',
    exposure: -0.12,
    contrast: 0.30,
    saturation: -0.08,
    temperature: -0.20,
    tint: 0.04,
    shadowLift: -0.10,
    highlightRollOff: 0.24,
    vignette: 0.18,
    sharpen: 0.12,
  );

  // ===========================================================================
  // PARIS
  // ===========================================================================

  static const paris =
      NeuroLensFilterRecipe(
    id: 'paris',
    name: 'Paris',
    exposure: 0.05,
    contrast: -0.02,
    saturation: -0.04,
    temperature: 0.10,
    tint: 0.05,
    fade: 0.16,
    shadowLift: 0.12,
    highlightRollOff: 0.18,
    vignette: 0.02,
  );

  // ===========================================================================
  // LOS ANGELES
  // ===========================================================================

  static const losAngeles =
      NeuroLensFilterRecipe(
    id: 'los_angeles',
    name: 'Los Angeles',
    exposure: 0.07,
    contrast: 0.17,
    saturation: 0.15,
    temperature: 0.20,
    tint: 0.02,
    shadowLift: 0.02,
    highlightRollOff: 0.16,
    vignette: 0.04,
    sharpen: 0.08,
  );

  // ===========================================================================
  // OSLO
  // ===========================================================================

  static const oslo =
      NeuroLensFilterRecipe(
    id: 'oslo',
    name: 'Oslo',
    exposure: 0.03,
    contrast: 0.08,
    saturation: -0.02,
    temperature: -0.21,
    tint: -0.03,
    shadowLift: 0.10,
    highlightRollOff: 0.15,
    fade: 0.08,
  );

  // ===========================================================================
  // JAKARTA
  // ===========================================================================

  static const jakarta =
      NeuroLensFilterRecipe(
    id: 'jakarta',
    name: 'Jakarta',
    exposure: 0.04,
    contrast: 0.21,
    saturation: 0.18,
    temperature: 0.23,
    tint: 0.01,
    shadowLift: -0.03,
    highlightRollOff: 0.14,
    vignette: 0.05,
    sharpen: 0.10,
  );

  // ===========================================================================
  // ABU DHABI
  // ===========================================================================

  static const abuDhabi =
      NeuroLensFilterRecipe(
    id: 'abu_dhabi',
    name: 'Abu Dhabi',
    exposure: 0.06,
    contrast: 0.18,
    saturation: 0.10,
    temperature: 0.29,
    tint: 0.02,
    shadowLift: 0.01,
    highlightRollOff: 0.20,
    vignette: 0.06,
  );

  // ===========================================================================
  // CAIRO
  // ===========================================================================

  static const cairo =
      NeuroLensFilterRecipe(
    id: 'cairo',
    name: 'Cairo',
    exposure: 0.04,
    contrast: 0.23,
    saturation: 0.06,
    temperature: 0.34,
    tint: 0.015,
    fade: 0.04,
    shadowLift: -0.02,
    highlightRollOff: 0.22,
    vignette: 0.08,
    grain: 0.025,
  );

  // ===========================================================================
  // RIO DE JANEIRO
  // ===========================================================================

  static const rioDeJaneiro =
      NeuroLensFilterRecipe(
    id: 'rio_de_janeiro',
    name: 'Rio de Janeiro',
    exposure: 0.04,
    contrast: 0.24,
    saturation: 0.27,
    temperature: 0.06,
    tint: 0.04,
    shadowLift: -0.03,
    highlightRollOff: 0.13,
    vignette: 0.03,
    sharpen: 0.14,
  );

  // ===========================================================================
  // FLASH CCD
  // ===========================================================================

  static const flashCcd =
      NeuroLensFilterRecipe(
    id: 'flash_ccd',
    name: 'Flash CCD',
    exposure: 0.15,
    contrast: 0.20,
    saturation: 0.03,
    temperature: -0.03,
    tint: 0.04,
    shadowLift: 0.12,
    highlightRollOff: 0.30,
    grain: 0.08,
    sharpen: 0.16,
    vignette: 0.05,
  );

  // ===========================================================================
  // LARK
  // ===========================================================================

  static const lark =
      NeuroLensFilterRecipe(
    id: 'lark',
    name: 'Lark',
    exposure: 0.08,
    contrast: 0.08,
    saturation: 0.12,
    temperature: 0.03,
    tint: -0.02,
    shadowLift: 0.10,
    highlightRollOff: 0.14,
    fade: 0.05,
    sharpen: 0.08,
  );

  // ===========================================================================
  // ALL
  // ===========================================================================

  static const all = [
    normal,

    fade,
    fadeWarm,
    fadeCool,

    simple,
    simpleWarm,
    simpleCool,

    boost,
    boostWarm,
    boostCool,

    hyper,
    dazzCam,
    emerald,
    midnight,

    paris,
    losAngeles,
    oslo,
    jakarta,
    abuDhabi,
    cairo,
    rioDeJaneiro,
    flashCcd,
    lark,
  ];

  // ===========================================================================
  // LOOKUP
  // ===========================================================================

  static NeuroLensFilterRecipe? byId(
    String id,
  ) {
    for (final recipe in all) {
      if (recipe.id == id) {
        return recipe;
      }
    }

    return null;
  }

  static NeuroLensFilterRecipe? byName(
    String name,
  ) {
    for (final recipe in all) {
      if (recipe.name == name) {
        return recipe;
      }
    }

    return null;
  }
}