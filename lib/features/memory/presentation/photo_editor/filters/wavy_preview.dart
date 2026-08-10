import 'dart:math' as math;

import 'package:flutter/material.dart';

class WavyPreview extends StatelessWidget {
  const WavyPreview({
    required this.child,
    required this.intensity,
    super.key,
  });

  final Widget child;

  /// 0.0 = normal
  /// 1.0 = strong wave distortion
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final strength = intensity.clamp(
      0.0,
      1.0,
    );

    if (strength <= 0.001) {
      return child;
    }

    return ClipRect(
      child: CustomPaint(
        foregroundPainter: _WavyPreviewPainter(
          intensity: strength,
        ),
        child: child,
      ),
    );
  }
}

class _WavyPreviewPainter extends CustomPainter {
  const _WavyPreviewPainter({
    required this.intensity,
  });

  final double intensity;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(
        alpha: 0.04 + (0.06 * intensity),
      );

    final path = Path();

    final amplitude =
        size.width *
        0.025 *
        intensity;

    final waveCount =
        2.0 +
        (intensity * 2.0);

    final frequency =
        (
          math.pi *
          2 *
          waveCount
        ) /
        size.height;

    for (
      double y = 0;
      y <= size.height;
      y += 3
    ) {
      final dx =
          math.sin(
            y * frequency,
          ) *
          amplitude;

      if (y == 0) {
        path.moveTo(
          dx,
          y,
        );
      } else {
        path.lineTo(
          dx,
          y,
        );
      }
    }

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _WavyPreviewPainter oldDelegate,
  ) {
    return oldDelegate.intensity !=
        intensity;
  }
}