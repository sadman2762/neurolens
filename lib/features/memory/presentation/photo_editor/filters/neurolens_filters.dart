import 'neurolens_filter.dart';

class NeuroLensFilters {
  const NeuroLensFilters._();

  static const List<double> _identity = [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<NeuroLensFilter> all = [
    // =========================================================================
    // NORMAL
    // =========================================================================
    NeuroLensFilter(
      id: 'normal',
      name: 'Normal',
      type: NeuroLensFilterType.color,
      matrix: _identity,
    ),

    // =========================================================================
    // FADE
    // =========================================================================
    NeuroLensFilter(
      id: 'fade',
      name: 'Fade',
      type: NeuroLensFilterType.color,
      matrix: [
        // Red
        0.90, 0.035, 0.020, 0, 10,

        // Green
        0.030, 0.87, 0.030, 0, 11,

        // Blue
        0.020, 0.035, 0.84, 0, 10,

        // Alpha
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),

    NeuroLensFilter(
      id: 'fade_warm',
      name: 'Fade Warm',
      type: NeuroLensFilterType.color,
      matrix: [
        1.08,
        0.06,
        0.01,
        0,
        17,
        0.04,
        0.88,
        0.02,
        0,
        14,
        0.01,
        0.04,
        0.72,
        0,
        20,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    NeuroLensFilter(
      id: 'fade_cool',
      name: 'Fade Cool',
      type: NeuroLensFilterType.color,
      matrix: [
        0.75,
        0.03,
        0.10,
        0,
        19,
        0.02,
        0.88,
        0.08,
        0,
        17,
        0.05,
        0.08,
        1.14,
        0,
        20,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // SIMPLE
    // =========================================================================
    NeuroLensFilter(
      id: 'simple',
      name: 'Simple',
      type: NeuroLensFilterType.color,
      matrix: [
        1.14,
        -0.03,
        -0.03,
        0,
        2,
        -0.03,
        1.14,
        -0.03,
        0,
        2,
        -0.03,
        -0.03,
        1.14,
        0,
        2,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    NeuroLensFilter(
      id: 'simple_warm',
      name: 'Simple Warm',
      type: NeuroLensFilterType.color,
      matrix: [
        1.23,
        0.04,
        -0.01,
        0,
        8,
        0.02,
        1.09,
        0.00,
        0,
        4,
        0.00,
        0.01,
        0.78,
        0,
        1,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    NeuroLensFilter(
      id: 'simple_cool',
      name: 'Simple Cool',
      type: NeuroLensFilterType.color,
      matrix: [
        0.78,
        0.00,
        0.08,
        0,
        3,
        0.00,
        1.07,
        0.07,
        0,
        4,
        0.04,
        0.05,
        1.28,
        0,
        6,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // BOOST
    // =========================================================================
    NeuroLensFilter(
      id: 'boost',
      name: 'Boost',
      type: NeuroLensFilterType.color,
      matrix: [
        1.42,
        -0.13,
        -0.10,
        0,
        -13,
        -0.10,
        1.39,
        -0.10,
        0,
        -12,
        -0.10,
        -0.12,
        1.44,
        0,
        -13,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    NeuroLensFilter(
      id: 'boost_warm',
      name: 'Boost Warm',
      type: NeuroLensFilterType.color,
      matrix: [
        1.48,
        0.03,
        -0.07,
        0,
        -13,
        -0.04,
        1.28,
        -0.04,
        0,
        -8,
        -0.07,
        -0.05,
        0.75,
        0,
        3,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    NeuroLensFilter(
      id: 'boost_cool',
      name: 'Boost Cool',
      type: NeuroLensFilterType.color,
      matrix: [
        0.80,
        -0.05,
        0.16,
        0,
        -7,
        -0.04,
        1.25,
        0.10,
        0,
        -8,
        0.06,
        0.08,
        1.51,
        0,
        -13,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // HYPER
    // =========================================================================
    NeuroLensFilter(
      id: 'hyper',
      name: 'Hyper',
      type: NeuroLensFilterType.color,
      matrix: [
        1.62,
        -0.19,
        -0.12,
        0,
        -22,
        -0.14,
        1.55,
        -0.11,
        0,
        -19,
        -0.12,
        -0.15,
        1.68,
        0,
        -22,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // DAZZ CAM
    // =========================================================================
    NeuroLensFilter(
      id: 'dazz_cam',
      name: 'Dazz Cam',
      type: NeuroLensFilterType.color,
      matrix: [
        // R
        1.38, 0.10, -0.05, 0, 5,

        // G
        0.05, 1.18, -0.03, 0, 1,

        // B
        -0.06, 0.03, 0.78, 0, -2,

        // A
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),

    // =========================================================================
    // EMERALD
    // =========================================================================
    NeuroLensFilter(
      id: 'emerald',
      name: 'Emerald',
      type: NeuroLensFilterType.color,
      matrix: [
        0.68,
        0.10,
        0.03,
        0,
        -3,
        0.02,
        1.46,
        0.11,
        0,
        5,
        0.00,
        0.16,
        0.88,
        0,
        -3,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // MIDNIGHT
    // =========================================================================
    NeuroLensFilter(
      id: 'midnight',
      name: 'Midnight',
      type: NeuroLensFilterType.color,
      matrix: [
        0.68,
        -0.03,
        0.01,
        0,
        -14,
        -0.02,
        0.70,
        0.01,
        0,
        -14,
        0.00,
        0.01,
        0.73,
        0,
        -13,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // ADVANCED EFFECTS
    // =========================================================================
    NeuroLensFilter(
      id: 'grainy',
      name: 'Grainy',
      type: NeuroLensFilterType.grain,
    ),

    NeuroLensFilter(
      id: 'zoom_blur',
      name: 'Zoom Blur',
      type: NeuroLensFilterType.zoomBlur,
    ),

    NeuroLensFilter(
      id: 'wide_angle',
      name: 'Wide Angle',
      type: NeuroLensFilterType.wideAngle,
    ),

    NeuroLensFilter(id: 'wavy', name: 'Wavy', type: NeuroLensFilterType.wavy),

    // =========================================================================
    // PARIS
    // =========================================================================
    NeuroLensFilter(
      id: 'paris',
      name: 'Paris',
      type: NeuroLensFilterType.color,
      matrix: [
        // Red — gentle warmth, preserve skin
        1.12, 0.05, 0.01, 0, 8,

        // Green — soft, slightly bright
        0.02, 1.06, 0.03, 0, 6,

        // Blue — slightly reduced for warm pastel feel
        0.02, 0.02, 0.92, 0, 7,

        // Alpha
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),

    // =========================================================================
    // LOS ANGELES
    // =========================================================================
    NeuroLensFilter(
      id: 'los_angeles',
      name: 'Los Angeles',
      type: NeuroLensFilterType.color,
      matrix: [
        // Red — warm skin and richer reds
        1.24, 0.07, -0.02, 0, 5,

        // Green — mild contrast, keep foliage natural
        0.03, 1.10, 0.01, 0, 2,

        // Blue — slightly suppress cool tones
        -0.02, 0.02, 0.88, 0, 1,

        // Alpha
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),

    // =========================================================================
    // OSLO
    // =========================================================================
    NeuroLensFilter(
      id: 'oslo',
      name: 'Oslo',
      type: NeuroLensFilterType.color,
      matrix: [
        // Red — slightly reduced warmth
        0.92, 0.00, 0.03, 0, -2,

        // Green — mostly neutral
        0.00, 1.00, 0.03, 0, 0,

        // Blue — gentle cool lift
        0.02, 0.04, 1.08, 0, 1,

        // Alpha
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),

    // =========================================================================
    // JAKARTA
    // =========================================================================
    NeuroLensFilter(
      id: 'jakarta',
      name: 'Jakarta',
      type: NeuroLensFilterType.color,
      matrix: [
        1.39,
        0.09,
        -0.05,
        0,
        8,
        0.05,
        1.17,
        -0.03,
        0,
        3,
        -0.05,
        0.02,
        0.65,
        0,
        -3,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // ABU DHABI
    // =========================================================================
    NeuroLensFilter(
      id: 'abu_dhabi',
      name: 'Abu Dhabi',
      type: NeuroLensFilterType.color,
      matrix: [
        1.43,
        0.10,
        -0.06,
        0,
        15,
        0.05,
        1.23,
        -0.04,
        0,
        8,
        -0.06,
        -0.03,
        0.62,
        0,
        1,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // CAIRO
    // =========================================================================
    NeuroLensFilter(
      id: 'cairo',
      name: 'Cairo',
      type: NeuroLensFilterType.color,
      matrix: [
        1.44,
        0.11,
        -0.07,
        0,
        18,
        0.06,
        1.17,
        -0.03,
        0,
        10,
        -0.06,
        0.00,
        0.57,
        0,
        4,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // RIO DE JANEIRO
    // =========================================================================
    NeuroLensFilter(
      id: 'rio_de_janeiro',
      name: 'Rio de Janeiro',
      type: NeuroLensFilterType.color,
      matrix: [
        1.42,
        0.03,
        0.05,
        0,
        -5,
        -0.03,
        1.38,
        0.10,
        0,
        -5,
        0.05,
        0.09,
        1.34,
        0,
        -5,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // FLASH CCD
    // =========================================================================
    NeuroLensFilter(
      id: 'flash_ccd',
      name: 'Flash CCD',
      type: NeuroLensFilterType.color,
      matrix: [
        1.51,
        0.08,
        0.08,
        0,
        22,
        0.06,
        1.40,
        0.08,
        0,
        18,
        0.08,
        0.06,
        1.38,
        0,
        20,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),

    // =========================================================================
    // LARK
    // =========================================================================
    NeuroLensFilter(
      id: 'lark',
      name: 'Lark',
      type: NeuroLensFilterType.color,
      matrix: [
        1.24,
        0.05,
        0.04,
        0,
        8,
        0.04,
        1.28,
        0.06,
        0,
        9,
        0.03,
        0.06,
        1.15,
        0,
        6,
        0.00,
        0.00,
        0.00,
        1,
        0,
      ],
    ),
  ];

  static NeuroLensFilter get normal => all.first;

  static NeuroLensFilter? byId(String id) {
    for (final filter in all) {
      if (filter.id == id) {
        return filter;
      }
    }

    return null;
  }
}
