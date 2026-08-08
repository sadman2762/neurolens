import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({
    required this.onFinished,
    super.key,
  });

  final VoidCallback onFinished;

  @override
  State<PremiumSplashScreen> createState() =>
      _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  static const Color _background = Color(0xFF01030D);

  static const double _markSize = 174;
  static const double _ringSize = 166;
  static const double _brainSize = 98;

  late final AnimationController _rotationController;
  late final AnimationController _titleController;
  late final AnimationController _glowController;

  Timer? _titleTimer;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 4800,
      ),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 650,
      ),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1700,
      ),
    )..repeat(
        reverse: true,
      );

    _startAnimation();
  }

  void _startAnimation() {
    Future<void>.delayed(
      const Duration(
        milliseconds: 120,
      ),
      () {
        if (!mounted) {
          return;
        }

        _rotationController.repeat();
      },
    );

    _titleTimer = Timer(
      const Duration(
        milliseconds: 650,
      ),
      () {
        if (mounted) {
          _titleController.forward();
        }
      },
    );

    _finishTimer = Timer(
      const Duration(
        milliseconds: 3200,
      ),
      () {
        if (mounted) {
          widget.onFinished();
        }
      },
    );
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    _finishTimer?.cancel();

    _rotationController.dispose();
    _titleController.dispose();
    _glowController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),

          Center(
            child: SizedBox(
              width: _markSize,
              height: _markSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (
                      context,
                      child,
                    ) {
                      return _CoreGlow(
                        progress: _glowController.value,
                      );
                    },
                  ),

                  //
                  // ONLY THE RING ROTATES.
                  //
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (
                      context,
                      child,
                    ) {
                      return Transform.rotate(
                        angle:
                            _rotationController.value *
                            math.pi *
                            2,
                        child: child,
                      );
                    },
                    child: const CustomPaint(
                      size: Size.square(
                        _ringSize,
                      ),
                      painter: _NeuroLensRingPainter(),
                    ),
                  ),

                  //
                  // BRAIN REMAINS STATIC.
                  //
                  const CustomPaint(
                    size: Size.square(
                      _brainSize,
                    ),
                    painter: _NeuroLensBrainPainter(),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 70,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _titleController,
                curve: Curves.easeOutCubic,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(
                    0,
                    0.18,
                  ),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _titleController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: const _BrandFooter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ROTATING NEUROLENS RING
// ============================================================================

class _NeuroLensRingPainter extends CustomPainter {
  const _NeuroLensRingPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = size.center(
      Offset.zero,
    );

    final outerRadius =
        size.shortestSide *
        0.385;

    final mainRect = Rect.fromCircle(
      center: center,
      radius: outerRadius,
    );

    final shader = const SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 3 / 2,
      colors: [
        Color(0xFFE848ED),
        Color(0xFFD94FEA),
        Color(0xFF9A5CDC),
        Color(0xFF5983DC),
        Color(0xFF29DDE7),
        Color(0xFF20E9F0),
        Color(0xFF5983DC),
        Color(0xFF9A5CDC),
        Color(0xFFE848ED),
      ],
    ).createShader(
      mainRect,
    );

    //
    // SOFT GLOW
    //
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(
        0xFF9A5CDC,
      ).withValues(
        alpha: 0.12,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawArc(
      mainRect,
      0.10,
      math.pi * 1.47,
      false,
      glowPaint,
    );

    //
    // MAIN FAT RING
    //
    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    canvas.drawArc(
      mainRect,
      0.10,
      math.pi * 1.47,
      false,
      mainPaint,
    );

    //
    // INNER PARALLEL RIGHT-HAND ARC
    //
    final innerRadius =
        outerRadius - 10;

    final innerRect = Rect.fromCircle(
      center: center,
      radius: innerRadius,
    );

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    canvas.drawArc(
      innerRect,
      -math.pi / 2 + 0.09,
      math.pi / 2 - 0.18,
      false,
      innerPaint,
    );

    canvas.drawArc(
      innerRect,
      0.09,
      math.pi / 2 - 0.18,
      false,
      innerPaint,
    );

    //
    // THIN COMPANION ARC
    //
    final companionRadius =
        outerRadius - 1.5;

    final companionRect = Rect.fromCircle(
      center: center,
      radius: companionRadius,
    );

    final companionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    canvas.drawArc(
      companionRect,
      -math.pi / 2 + 0.10,
      math.pi / 2 - 0.20,
      false,
      companionPaint,
    );

    canvas.drawArc(
      companionRect,
      0.10,
      math.pi / 2 - 0.20,
      false,
      companionPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================================
// STATIC NEUROLENS BRAIN
// ============================================================================

class _NeuroLensBrainPainter extends CustomPainter {
  const _NeuroLensBrainPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final bounds =
        Offset.zero &
        size;

    final shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFE848ED),
        Color(0xFFB954E6),
        Color(0xFF8065E8),
        Color(0xFF5983DC),
        Color(0xFF29DDE7),
      ],
      stops: [
        0,
        0.25,
        0.50,
        0.73,
        1,
      ],
    ).createShader(
      bounds,
    );

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader;

    final network = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = shader;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    //
    // CENTER DIVIDER
    //
    canvas.drawLine(
      Offset(
        cx,
        h * 0.12,
      ),
      Offset(
        cx,
        h * 0.88,
      ),
      outline,
    );

    //
    // LEFT HEMISPHERE
    //
    final left = Path()
      ..moveTo(
        cx - 2,
        h * 0.14,
      )
      ..cubicTo(
        w * 0.38,
        h * 0.05,
        w * 0.27,
        h * 0.11,
        w * 0.29,
        h * 0.23,
      )
      ..cubicTo(
        w * 0.15,
        h * 0.19,
        w * 0.11,
        h * 0.31,
        w * 0.17,
        h * 0.39,
      )
      ..cubicTo(
        w * 0.06,
        h * 0.43,
        w * 0.07,
        h * 0.56,
        w * 0.16,
        h * 0.60,
      )
      ..cubicTo(
        w * 0.10,
        h * 0.69,
        w * 0.18,
        h * 0.79,
        w * 0.29,
        h * 0.76,
      )
      ..cubicTo(
        w * 0.27,
        h * 0.89,
        w * 0.39,
        h * 0.95,
        cx - 2,
        h * 0.86,
      );

    canvas.drawPath(
      left,
      outline,
    );

    //
    // RIGHT HEMISPHERE
    //
    final right = Path()
      ..moveTo(
        cx + 2,
        h * 0.14,
      )
      ..cubicTo(
        w * 0.62,
        h * 0.05,
        w * 0.73,
        h * 0.11,
        w * 0.71,
        h * 0.23,
      )
      ..cubicTo(
        w * 0.85,
        h * 0.19,
        w * 0.89,
        h * 0.31,
        w * 0.83,
        h * 0.39,
      )
      ..cubicTo(
        w * 0.94,
        h * 0.43,
        w * 0.93,
        h * 0.56,
        w * 0.84,
        h * 0.60,
      )
      ..cubicTo(
        w * 0.90,
        h * 0.69,
        w * 0.82,
        h * 0.79,
        w * 0.71,
        h * 0.76,
      )
      ..cubicTo(
        w * 0.73,
        h * 0.89,
        w * 0.61,
        h * 0.95,
        cx + 2,
        h * 0.86,
      );

    canvas.drawPath(
      right,
      outline,
    );

    final nodes = <Offset>[
      Offset(w * 0.31, h * 0.25),
      Offset(w * 0.18, h * 0.42),
      Offset(w * 0.39, h * 0.42),
      Offset(w * 0.25, h * 0.57),
      Offset(w * 0.39, h * 0.69),
      Offset(w * 0.28, h * 0.79),
      Offset(w * 0.42, h * 0.30),
      Offset(w * 0.18, h * 0.59),

      Offset(w * 0.69, h * 0.25),
      Offset(w * 0.82, h * 0.42),
      Offset(w * 0.61, h * 0.42),
      Offset(w * 0.75, h * 0.57),
      Offset(w * 0.61, h * 0.69),
      Offset(w * 0.72, h * 0.79),
      Offset(w * 0.58, h * 0.30),
      Offset(w * 0.82, h * 0.59),
    ];

    const links = <List<int>>[
      [0, 1],
      [0, 2],
      [0, 6],
      [1, 2],
      [1, 7],
      [2, 3],
      [2, 6],
      [3, 4],
      [3, 7],
      [4, 5],
      [3, 5],
      [2, 4],

      [8, 9],
      [8, 10],
      [8, 14],
      [9, 10],
      [9, 15],
      [10, 11],
      [10, 14],
      [11, 12],
      [11, 15],
      [12, 13],
      [11, 13],
      [10, 12],
    ];

    for (final link in links) {
      canvas.drawLine(
        nodes[link[0]],
        nodes[link[1]],
        network,
      );
    }

    for (
      var i = 0;
      i < nodes.length;
      i++
    ) {
      final double radius =
          switch (i % 4) {
        0 => 5.4,
        1 => 4.2,
        2 => 5.0,
        _ => 3.6,
      };

      canvas.drawCircle(
        nodes[i],
        radius,
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================================
// GLOW
// ============================================================================

class _CoreGlow extends StatelessWidget {
  const _CoreGlow({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(
              0xFF5983DC,
            ).withValues(
              alpha:
                  0.045 +
                  progress * 0.025,
            ),
            const Color(
              0xFF9A5CDC,
            ).withValues(
              alpha:
                  0.025 +
                  progress * 0.015,
            ),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BRAND FOOTER
// ============================================================================

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GradientTitle(),

        SizedBox(
          height: 9,
        ),

        Text(
          'Your memories. Intelligently connected.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(
              0xFF73798D,
            ),
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.38,
          ),
        ),

        SizedBox(
          height: 20,
        ),

        _BottomAccent(),
      ],
    );
  }
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (
        bounds,
      ) {
        return const LinearGradient(
          colors: [
            Color(0xFFB1D1E8),
            Color(0xFF5983DC),
            Color(0xFF9A5CDC),
            Color(0xFF5D22E6),
          ],
          stops: [
            0,
            0.43,
            0.68,
            1,
          ],
        ).createShader(
          bounds,
        );
      },
      child: const Text(
        'NeuroLens',
        style: TextStyle(
          color: Colors.white,
          fontSize: 35,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
          height: 1,
        ),
      ),
    );
  }
}

class _BottomAccent extends StatelessWidget {
  const _BottomAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          99,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5983DC),
            Color(0xFF9A5CDC),
            Color(0xFF5D22E6),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BACKGROUND
// ============================================================================

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(
        0xFF01030D,
      ),
    );
  }
}