import 'package:flutter/material.dart';

class WideAnglePreview extends StatelessWidget {
  const WideAnglePreview({
    required this.child,
    required this.intensity,
    super.key,
  });

  final Widget child;

  /// 0.0 = normal
  /// 1.0 = strong wide-angle feel
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final strength = intensity.clamp(0.0, 1.0);

    if (strength <= 0.001) {
      return child;
    }

    final horizontalScale = 1.0 + (strength * 0.16);

    final verticalScale = 1.0 - (strength * 0.05);

    final perspective = 0.0007 * strength;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..scaleByDouble(horizontalScale, verticalScale, 1.0, 1.0);

    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: child,
      ),
    );
  }
}
