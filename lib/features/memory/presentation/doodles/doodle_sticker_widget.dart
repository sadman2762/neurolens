import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_sticker.dart';

class DoodleStickerWidget extends StatefulWidget {
  const DoodleStickerWidget({
    required this.sticker,
    required this.selected,
    required this.onChanged,
    required this.onSelected,
    required this.onDelete,
    super.key,
  });

  final DoodleSticker sticker;
  final bool selected;

  final ValueChanged<DoodleSticker> onChanged;
  final VoidCallback onSelected;
  final VoidCallback onDelete;

  @override
  State<DoodleStickerWidget> createState() =>
      _DoodleStickerWidgetState();
}

class _DoodleStickerWidgetState
    extends State<DoodleStickerWidget> {
  static const double _baseSize = 120;

  Offset _gesturePosition = Offset.zero;

  double _gestureStartScale = 1;
  double _gestureStartRotation = 0;

  @override
  Widget build(BuildContext context) {
    final sticker = widget.sticker;

    final flipScaleX = sticker.flipX ? -1.0 : 1.0;
    final flipScaleY = sticker.flipY ? -1.0 : 1.0;

    return Positioned(
      left: sticker.position.dx - _baseSize / 2,
      top: sticker.position.dy - _baseSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,

        // ===================================================================
        // SELECT
        // ===================================================================

        onTap: widget.onSelected,

        // ===================================================================
        // START TRANSFORM
        // ===================================================================

        onScaleStart: (details) {
          widget.onSelected();

          //
          // IMPORTANT:
          //
          // We store a mutable gesture position here.
          // During every update we ADD focalPointDelta to this position.
          //
          // The old implementation kept adding focalPointDelta to the
          // original sticker position, which caused the sticker to barely
          // move or appear to snap back.
          //
          _gesturePosition = sticker.position;

          _gestureStartScale = sticker.scale;
          _gestureStartRotation = sticker.rotation;
        },

        // ===================================================================
        // MOVE + SCALE + ROTATE
        // ===================================================================

        onScaleUpdate: (details) {
          //
          // Accumulate translation.
          //
          _gesturePosition += details.focalPointDelta;

          final nextScale = (
            _gestureStartScale * details.scale
          ).clamp(
            0.20,
            8.0,
          );

          final nextRotation =
              _gestureStartRotation + details.rotation;

          widget.onChanged(
            sticker.copyWith(
              position: _gesturePosition,
              scale: nextScale,
              rotation: nextRotation,
            ),
          );
        },

        child: Transform.rotate(
          angle: sticker.rotation,
          child: Transform.scale(
            scale: sticker.scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ===========================================================
                // STICKER
                // ===========================================================

                Container(
                  width: _baseSize,
                  height: _baseSize,
                  padding: const EdgeInsets.all(
                    10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                    border: widget.selected
                        ? Border.all(
                            color: const Color(
                              0xFFC4B5FD,
                            ),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scaleByDouble(
                        flipScaleX,
                        flipScaleY,
                        1.0,
                        1.0,
                      ),
                    child: Image.asset(
                      sticker.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        debugPrint(
                          'Could not load doodle sticker: '
                          '${sticker.assetPath}',
                        );

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white38,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ===========================================================
                // DELETE
                // ===========================================================

                if (widget.selected)
                  Positioned(
                    top: -13,
                    right: -13,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onDelete,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEF4444,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 8,
                              offset: const Offset(
                                0,
                                3,
                              ),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // ===========================================================
                // TRANSFORM INDICATOR
                // ===========================================================

                if (widget.selected)
                  Positioned(
                    left: -10,
                    bottom: -10,
                    child: IgnorePointer(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B5CF6,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: const Icon(
                            Icons.open_in_full_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}