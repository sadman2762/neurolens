import 'package:flutter/material.dart';

class MidnightVignette extends StatelessWidget {
  const MidnightVignette({
    required this.child,
    required this.intensity,
    super.key,
  });

  final Widget child;

  /// 0.0 = no Midnight spatial effect
  /// 1.0 = strongest Midnight spatial effect
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final value = intensity.clamp(
      0.0,
      1.0,
    );

    if (value <= 0.001) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,

        // =====================================================================
        // CENTER GLOW
        // =====================================================================

        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center:
                    Alignment.center,

                radius:
                    0.70,

                colors: [
                  Colors.white.withValues(
                    alpha:
                        0.22 *
                        value,
                  ),

                  const Color(
                    0xFFFFF5EB,
                  ).withValues(
                    alpha:
                        0.12 *
                        value,
                  ),

                  Colors.transparent,

                  Colors.transparent,
                ],

                stops: const [
                  0.0,
                  0.22,
                  0.52,
                  1.0,
                ],
              ),
            ),
          ),
        ),

        // =====================================================================
        // DARK EDGES
        // =====================================================================

        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center:
                    Alignment.center,

                radius:
                    0.98,

                colors: [
                  Colors.transparent,
                  Colors.transparent,

                  Colors.black.withValues(
                    alpha:
                        0.04 *
                        value,
                  ),

                  Colors.black.withValues(
                    alpha:
                        0.20 *
                        value,
                  ),

                  Colors.black.withValues(
                    alpha:
                        0.48 *
                        value,
                  ),
                ],

                stops: const [
                  0.0,
                  0.38,
                  0.60,
                  0.80,
                  1.0,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}