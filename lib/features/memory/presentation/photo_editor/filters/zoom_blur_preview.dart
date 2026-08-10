import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ZoomBlurPreview extends StatelessWidget {
  const ZoomBlurPreview({
    required this.child,
    required this.intensity,
    super.key,
  });

  final Widget child;

  /// 0.0 = no blur
  /// 1.0 = strong zoom blur
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

    final blur = 1.5 + (strength * 8.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,

        Opacity(
          opacity: 0.18 + (strength * 0.32),
          child: Transform.scale(
            scale: 1.02 + (strength * 0.08),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
              ),
              child: child,
            ),
          ),
        ),

        Opacity(
          opacity: 0.10 + (strength * 0.22),
          child: Transform.scale(
            scale: 1.05 + (strength * 0.12),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur * 1.25,
                sigmaY: blur * 1.25,
              ),
              child: child,
            ),
          ),
        ),

        Opacity(
          opacity: 0.05 + (strength * 0.16),
          child: Transform.scale(
            scale: 1.08 + (strength * 0.16),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur * 1.5,
                sigmaY: blur * 1.5,
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}