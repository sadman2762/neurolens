import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'filter_processor.dart';
import 'neurolens_filter.dart';

class FilterThumbnail extends StatelessWidget {
  const FilterThumbnail({
    required this.imageBytes,
    required this.filter,
    required this.selected,
    required this.intensity,
    required this.onTap,
    super.key,
  });

  final Uint8List imageBytes;
  final NeuroLensFilter filter;
  final bool selected;
  final double intensity;
  final VoidCallback onTap;

  static const double _size = 82;

  @override
  Widget build(BuildContext context) {
    final matrix = FilterProcessor.matrixFor(
      filter: filter,
      intensity: intensity,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 160,
              ),
              width: _size,
              height: _size,
              padding: EdgeInsets.all(
                selected ? 2.5 : 0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(
                        color: Colors.white,
                        width: 2,
                      )
                    : null,
              ),
              child: ClipOval(
                child: filter.isColorFilter
                    ? ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          matrix,
                        ),
                        child: _ThumbnailImage(
                          imageBytes: imageBytes,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          _ThumbnailImage(
                            imageBytes: imageBytes,
                          ),

                          if (filter.type ==
                              NeuroLensFilterType.grain)
                            const _GrainPreviewOverlay(),

                          if (filter.type ==
                              NeuroLensFilterType.zoomBlur)
                            const _EffectBadge(
                              icon: Icons.zoom_out_map_rounded,
                            ),

                          if (filter.type ==
                              NeuroLensFilterType.wideAngle)
                            const _EffectBadge(
                              icon: Icons.panorama_wide_angle_rounded,
                            ),

                          if (filter.type ==
                              NeuroLensFilterType.wavy)
                            const _EffectBadge(
                              icon: Icons.waves_rounded,
                            ),
                        ],
                      ),
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              filter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(
                        alpha: 0.52,
                      ),
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      imageBytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _EffectBadge extends StatelessWidget {
  const _EffectBadge({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(
        alpha: 0.18,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(
            alpha: 0.72,
          ),
        ),
        child: Icon(
          icon,
          size: 15,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GrainPreviewOverlay extends StatelessWidget {
  const _GrainPreviewOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPreviewPainter(),
      ),
    );
  }
}

class _GrainPreviewPainter extends CustomPainter {
  const _GrainPreviewPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint();

    const spacing = 5.0;

    for (
      double y = 2;
      y < size.height;
      y += spacing
    ) {
      for (
        double x = 2;
        x < size.width;
        x += spacing
      ) {
        final seed =
            ((x * 17) + (y * 31)).toInt();

        final bright =
            seed % 3 == 0;

        paint.color = bright
            ? Colors.white.withValues(
                alpha: 0.10,
              )
            : Colors.black.withValues(
                alpha: 0.08,
              );

        canvas.drawCircle(
          Offset(
            x,
            y,
          ),
          0.65,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _GrainPreviewPainter oldDelegate,
  ) {
    return false;
  }
}