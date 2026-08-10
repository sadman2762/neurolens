import 'dart:math' as math;

import 'package:flutter/material.dart';

class GrainOverlay extends StatelessWidget {
  const GrainOverlay({
    required this.intensity,
    this.seed = 1337,
    super.key,
  });

  /// 0.0 = no grain
  /// 1.0 = maximum grain
  final double intensity;

  final int seed;

  @override
  Widget build(BuildContext context) {
    final normalized = intensity.clamp(
      0.0,
      1.0,
    );

    if (normalized <= 0.001) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainPainter(
            intensity: normalized,
            seed: seed,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({
    required this.intensity,
    required this.seed,
  });

  final double intensity;
  final int seed;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        intensity <= 0) {
      return;
    }

    final random = math.Random(
      seed,
    );

    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Grain density increases slightly with intensity.
    final spacing = 3.8 -
        (intensity * 1.4);

    // Strong enough to be visible,
    // but still photographic rather than noisy.
    final maxAlpha =
        0.05 +
        (0.17 * intensity);

    for (
      double y = 0;
      y < size.height;
      y += spacing
    ) {
      for (
        double x = 0;
        x < size.width;
        x += spacing
      ) {
        // Don't draw on every possible point.
        if (random.nextDouble() >
            0.72) {
          continue;
        }

        final alpha =
            maxAlpha *
            (
              0.35 +
              random.nextDouble() *
                  0.65
            );

        final isLight =
            random.nextBool();

        paint.color = isLight
            ? Colors.white.withValues(
                alpha: alpha,
              )
            : Colors.black.withValues(
                alpha:
                    alpha * 0.90,
              );

        final radius =
            0.35 +
            random.nextDouble() *
                0.75;

        final offsetX =
            (
              random.nextDouble() -
              0.5
            ) *
            spacing;

        final offsetY =
            (
              random.nextDouble() -
              0.5
            ) *
            spacing;

        canvas.drawCircle(
          Offset(
            x + offsetX,
            y + offsetY,
          ),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _GrainPainter oldDelegate,
  ) {
    return oldDelegate.intensity !=
            intensity ||
        oldDelegate.seed != seed;
  }
}