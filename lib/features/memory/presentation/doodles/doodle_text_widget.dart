import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_text.dart';

class DoodleTextWidget extends StatefulWidget {
  const DoodleTextWidget({
    required this.textElement,
    required this.selected,
    required this.onSelected,
    required this.onChanged,
    required this.onDelete,
    super.key,
  });

  final DoodleText textElement;
  final bool selected;
  final VoidCallback onSelected;
  final ValueChanged<DoodleText> onChanged;
  final VoidCallback onDelete;

  @override
  State<DoodleTextWidget> createState() =>
      _DoodleTextWidgetState();
}

class _DoodleTextWidgetState extends State<DoodleTextWidget> {
  Offset _gesturePosition = Offset.zero;

  double _gestureStartScale = 1;
  double _gestureStartRotation = 0;

  @override
  Widget build(BuildContext context) {
    final element = widget.textElement;

    final curved =
        element.curveAmount.abs() > 0.01;

    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onSelected,

        onScaleStart: (_) {
          widget.onSelected();

          _gesturePosition =
              element.position;

          _gestureStartScale =
              element.scale;

          _gestureStartRotation =
              element.rotation;
        },

        onScaleUpdate: (details) {
          _gesturePosition +=
              details.focalPointDelta;

          final nextScale = (
            _gestureStartScale *
                details.scale
          ).clamp(
            0.25,
            8.0,
          );

          final nextRotation =
              _gestureStartRotation +
              details.rotation;

          widget.onChanged(
            element.copyWith(
              position:
                  _gesturePosition,
              scale:
                  nextScale,
              rotation:
                  nextRotation,
            ),
          );
        },

        child: Transform.rotate(
          angle: element.rotation,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: element.scale,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ===========================================================
                // TEXT + OUTLINE BUBBLE
                // ===========================================================

                Container(
                  constraints: BoxConstraints(
                    minWidth: 80,
                    maxWidth:
                        curved ? 360 : 300,
                  ),
                  padding:
                      const EdgeInsets.all(
                    4,
                  ),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    border:
                        widget.selected
                            ? Border.all(
                                color:
                                    const Color(
                                  0xFFC4B5FD,
                                ),
                                width:
                                    1.5,
                              )
                            : null,
                  ),
                  child:
                      _BubbleContainer(
                    element:
                        element,
                    child:
                        _DoodleTextRender(
                      element:
                          element,
                    ),
                  ),
                ),

                // ===========================================================
                // DELETE
                // ===========================================================

                if (widget.selected)
                  Positioned(
                    top:
                        -13,
                    right:
                        -13,
                    child:
                        GestureDetector(
                      behavior:
                          HitTestBehavior.opaque,
                      onTap:
                          widget.onDelete,
                      child:
                          Container(
                        width:
                            28,
                        height:
                            28,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEF4444,
                          ),
                          shape:
                              BoxShape.circle,
                          border:
                              Border.all(
                            color:
                                Colors.white,
                            width:
                                2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black
                                      .withValues(
                                alpha:
                                    0.3,
                              ),
                              blurRadius:
                                  8,
                            ),
                          ],
                        ),
                        child:
                            const Icon(
                          Icons.close_rounded,
                          color:
                              Colors.white,
                          size:
                              16,
                        ),
                      ),
                    ),
                  ),

                // ===========================================================
                // TRANSFORM HANDLE
                // ===========================================================

                if (widget.selected)
                  Positioned(
                    bottom:
                        -11,
                    left:
                        -11,
                    child:
                        IgnorePointer(
                      child:
                          Container(
                        width:
                            24,
                        height:
                            24,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF8B5CF6,
                          ),
                          shape:
                              BoxShape.circle,
                          border:
                              Border.all(
                            color:
                                Colors.white,
                            width:
                                2,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons.open_in_full_rounded,
                          color:
                              Colors.white,
                          size:
                              12,
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

// =============================================================================
// OUTLINE BUBBLE CONTAINER
// =============================================================================

class _BubbleContainer extends StatelessWidget {
  const _BubbleContainer({
    required this.element,
    required this.child,
  });

  final DoodleText element;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        element.bubbleColor.withValues(
      alpha:
          element.bubbleOpacity.clamp(
        0.0,
        1.0,
      ),
    );

    const strokeWidth = 3.0;

    switch (element.bubble) {
      // =====================================================================
      // NONE
      // =====================================================================

      case DoodleTextBubble.none:
        return Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                6,
            vertical:
                4,
          ),
          child:
              child,
        );

      // =====================================================================
      // PILL OUTLINE
      // =====================================================================

      case DoodleTextBubble.pill:
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                18,
            vertical:
                10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              999,
            ),
            border:
                Border.all(
              color:
                  bubbleColor,
              width:
                  strokeWidth,
            ),
          ),
          child:
              child,
        );

      // =====================================================================
      // HIGHLIGHT OUTLINE
      // =====================================================================

      case DoodleTextBubble.highlight:
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                14,
            vertical:
                7,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              4,
            ),
            border:
                Border.all(
              color:
                  bubbleColor,
              width:
                  strokeWidth,
            ),
          ),
          child:
              child,
        );

      // =====================================================================
      // BADGE OUTLINE
      // =====================================================================

      case DoodleTextBubble.badge:
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                16,
            vertical:
                10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border:
                Border.all(
              color:
                  bubbleColor,
              width:
                  strokeWidth,
            ),
          ),
          child:
              child,
        );

      // =====================================================================
      // CARD OUTLINE
      // =====================================================================

      case DoodleTextBubble.softCard:
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                18,
            vertical:
                13,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  bubbleColor,
              width:
                  strokeWidth,
            ),
          ),
          child:
              child,
        );

      // =====================================================================
      // SPEECH OUTLINE
      // =====================================================================

      case DoodleTextBubble.speech:
        return CustomPaint(
          painter:
              _SpeechBubblePainter(
            color:
                bubbleColor,
            strokeWidth:
                strokeWidth,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets.fromLTRB(
              19,
              13,
              19,
              24,
            ),
            child:
                child,
          ),
        );

      // =====================================================================
      // CLOUD OUTLINE
      // =====================================================================

      case DoodleTextBubble.cloud:
        return CustomPaint(
          painter:
              _CloudBubblePainter(
            color:
                bubbleColor,
            strokeWidth:
                strokeWidth,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  28,
              vertical:
                  22,
            ),
            child:
                child,
          ),
        );
    }
  }
}

// =============================================================================
// SPEECH BUBBLE OUTLINE
// =============================================================================

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..color =
              color
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              strokeWidth
          ..strokeJoin =
              StrokeJoin.round
          ..strokeCap =
              StrokeCap.round;

    final inset =
        strokeWidth / 2;

    final bodyBottom =
        size.height - 14;

    final path =
        Path();

    // Start top-left after corner.
    path.moveTo(
      22,
      inset,
    );

    // Top edge.
    path.lineTo(
      size.width - 22,
      inset,
    );

    // Top-right rounded corner.
    path.quadraticBezierTo(
      size.width - inset,
      inset,
      size.width - inset,
      22,
    );

    // Right edge.
    path.lineTo(
      size.width - inset,
      bodyBottom - 20,
    );

    // Bottom-right rounded corner.
    path.quadraticBezierTo(
      size.width - inset,
      bodyBottom,
      size.width - 22,
      bodyBottom,
    );

    // Bottom edge until tail.
    path.lineTo(
      size.width * 0.45,
      bodyBottom,
    );

    // Tail.
    path.lineTo(
      size.width * 0.31,
      size.height - inset,
    );

    path.lineTo(
      size.width * 0.33,
      bodyBottom,
    );

    // Continue bottom.
    path.lineTo(
      22,
      bodyBottom,
    );

    // Bottom-left rounded corner.
    path.quadraticBezierTo(
      inset,
      bodyBottom,
      inset,
      bodyBottom - 20,
    );

    // Left edge.
    path.lineTo(
      inset,
      22,
    );

    // Top-left rounded corner.
    path.quadraticBezierTo(
      inset,
      inset,
      22,
      inset,
    );

    path.close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SpeechBubblePainter oldDelegate,
  ) {
    return oldDelegate.color !=
            color ||
        oldDelegate.strokeWidth !=
            strokeWidth;
  }
}

// =============================================================================
// CLOUD BUBBLE OUTLINE
// =============================================================================

class _CloudBubblePainter extends CustomPainter {
  const _CloudBubblePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..color =
              color
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              strokeWidth
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round;

    final w =
        size.width;

    final h =
        size.height;

    final path =
        Path();

    path.moveTo(
      w * 0.16,
      h * 0.76,
    );

    // Lower-left bump.
    path.cubicTo(
      w * 0.04,
      h * 0.73,
      w * 0.02,
      h * 0.58,
      w * 0.08,
      h * 0.48,
    );

    // Left upper bump.
    path.cubicTo(
      w * 0.10,
      h * 0.36,
      w * 0.18,
      h * 0.31,
      w * 0.27,
      h * 0.34,
    );

    // Upper-left cloud bump.
    path.cubicTo(
      w * 0.27,
      h * 0.17,
      w * 0.40,
      h * 0.08,
      w * 0.51,
      h * 0.20,
    );

    // Upper-right large bump.
    path.cubicTo(
      w * 0.61,
      h * 0.04,
      w * 0.79,
      h * 0.13,
      w * 0.79,
      h * 0.31,
    );

    // Right bump.
    path.cubicTo(
      w * 0.93,
      h * 0.29,
      w * 0.99,
      h * 0.43,
      w * 0.94,
      h * 0.55,
    );

    // Lower-right bump.
    path.cubicTo(
      w * 0.98,
      h * 0.69,
      w * 0.86,
      h * 0.80,
      w * 0.75,
      h * 0.77,
    );

    // Bottom-right/center bump.
    path.cubicTo(
      w * 0.68,
      h * 0.91,
      w * 0.51,
      h * 0.92,
      w * 0.43,
      h * 0.80,
    );

    // Bottom-left bump.
    path.cubicTo(
      w * 0.34,
      h * 0.88,
      w * 0.21,
      h * 0.86,
      w * 0.16,
      h * 0.76,
    );

    path.close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CloudBubblePainter oldDelegate,
  ) {
    return oldDelegate.color !=
            color ||
        oldDelegate.strokeWidth !=
            strokeWidth;
  }
}

// =============================================================================
// TEXT RENDERER
// =============================================================================

class _DoodleTextRender extends StatelessWidget {
  const _DoodleTextRender({
    required this.element,
  });

  final DoodleText element;

  @override
  Widget build(BuildContext context) {
    if (element.curveAmount.abs() >
        0.01) {
      return SizedBox(
        width:
            320,
        height:
            160,
        child:
            CustomPaint(
          painter:
              _CurvedTextPainter(
            element:
                element,
          ),
        ),
      );
    }

    return _buildStraightText();
  }

  Widget _buildStraightText() {
    final alignment =
        switch (element.alignment) {
      DoodleTextAlign.left =>
        TextAlign.left,
      DoodleTextAlign.center =>
        TextAlign.center,
      DoodleTextAlign.right =>
        TextAlign.right,
    };

    final baseStyle =
        _textStyle(
      color:
          element.color,
    );

    if (!element.outlineEnabled) {
      return Text(
        element.text,
        textAlign:
            alignment,
        style:
            baseStyle,
      );
    }

    return Stack(
      children: [
        Text(
          element.text,
          textAlign:
              alignment,
          style:
              baseStyle.copyWith(
            foreground:
                Paint()
                  ..style =
                      PaintingStyle.stroke
                  ..strokeWidth =
                      3
                  ..color =
                      element.outlineColor,
            color:
                null,
          ),
        ),
        Text(
          element.text,
          textAlign:
              alignment,
          style:
              baseStyle,
        ),
      ],
    );
  }

  TextStyle _textStyle({
    required Color color,
  }) {
    return TextStyle(
      color:
          color,
      fontSize:
          element.fontSize,
      fontWeight:
          element.bold
              ? FontWeight.w800
              : FontWeight.w500,
      fontFamily:
          element.fontFamily,
      height:
          1.05,
      letterSpacing:
          0.1,
      shadows:
          element.shadowEnabled
              ? [
                  Shadow(
                    color:
                        Colors.black.withValues(
                      alpha:
                          0.6,
                    ),
                    blurRadius:
                        8,
                    offset:
                        const Offset(
                      2,
                      3,
                    ),
                  ),
                ]
              : null,
    );
  }
}

// =============================================================================
// CURVED TEXT PAINTER
// =============================================================================

class _CurvedTextPainter extends CustomPainter {
  const _CurvedTextPainter({
    required this.element,
  });

  final DoodleText element;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final text =
        element.text.replaceAll(
      '\n',
      ' ',
    );

    if (text.isEmpty) {
      return;
    }

    final characters =
        text.characters.toList();

    final style =
        TextStyle(
      color:
          element.color,
      fontSize:
          element.fontSize,
      fontFamily:
          element.fontFamily,
      fontWeight:
          element.bold
              ? FontWeight.w800
              : FontWeight.w500,
      shadows:
          element.shadowEnabled
              ? [
                  Shadow(
                    color:
                        Colors.black.withValues(
                      alpha:
                          0.6,
                    ),
                    blurRadius:
                        8,
                    offset:
                        const Offset(
                      2,
                      3,
                    ),
                  ),
                ]
              : null,
    );

    final painters =
        <TextPainter>[];

    var totalWidth =
        0.0;

    for (final character
        in characters) {
      final painter =
          TextPainter(
        text:
            TextSpan(
          text:
              character,
          style:
              style,
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      painters.add(
        painter,
      );

      totalWidth +=
          painter.width;
    }

    const spacing =
        1.2;

    totalWidth +=
        spacing *
        math.max(
          0,
          painters.length - 1,
        );

    final availableWidth =
        size.width - 16;

    final widthScale =
        totalWidth >
                availableWidth
            ? availableWidth /
                totalWidth
            : 1.0;

    final effectiveWidth =
        totalWidth *
        widthScale;

    var currentX =
        (
                size.width -
                    effectiveWidth) /
            2;

    final centerX =
        size.width / 2;

    final centerY =
        size.height / 2;

    final bendStrength =
        element.curveAmount *
        58;

    for (final painter
        in painters) {
      final characterWidth =
          painter.width *
          widthScale;

      final characterCenterX =
          currentX +
          characterWidth /
              2;

      final normalizedX =
          (
                  characterCenterX -
                      centerX) /
              math.max(
                effectiveWidth /
                    2,
                1,
              );

      final yOffset =
          bendStrength *
          normalizedX *
          normalizedX;

      final y =
          centerY -
          yOffset;

      final slope =
          -2 *
          bendStrength *
          normalizedX /
          math.max(
            effectiveWidth /
                2,
            1,
          );

      final angle =
          math.atan(
        slope,
      );

      canvas.save();

      canvas.translate(
        characterCenterX,
        y,
      );

      canvas.rotate(
        angle,
      );

      canvas.scale(
        widthScale,
      );

      final drawOffset =
          Offset(
        -painter.width /
            2,
        -painter.height /
            2,
      );

      if (element.outlineEnabled) {
        final outlinePainter =
            TextPainter(
          text:
              TextSpan(
            text:
                painter.text
                        ?.toPlainText() ??
                    '',
            style:
                style.copyWith(
              foreground:
                  Paint()
                    ..style =
                        PaintingStyle.stroke
                    ..strokeWidth =
                        3
                    ..color =
                        element.outlineColor,
              color:
                  null,
            ),
          ),
          textDirection:
              TextDirection.ltr,
        )..layout();

        outlinePainter.paint(
          canvas,
          drawOffset,
        );
      }

      painter.paint(
        canvas,
        drawOffset,
      );

      canvas.restore();

      currentX +=
          characterWidth +
          spacing;
    }
  }

  @override
  bool shouldRepaint(
    covariant _CurvedTextPainter oldDelegate,
  ) {
    return oldDelegate.element !=
        element;
  }
}