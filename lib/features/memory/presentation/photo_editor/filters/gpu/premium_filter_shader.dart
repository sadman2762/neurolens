import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PremiumFilterShader extends StatefulWidget {
  const PremiumFilterShader({
    required this.image,
    required this.intensity,
    required this.exposure,
    required this.contrast,
    required this.temperature,
    required this.tint,
    required this.saturation,
    required this.vibrance,
    required this.toneBlack,
    required this.toneShadow,
    required this.toneMid,
    required this.toneHighlight,
    required this.toneWhite,
    required this.vignette,
    required this.centerGlow,
    super.key,
  });

  final ui.Image image;

  final double intensity;

  final double exposure;
  final double contrast;

  final double temperature;
  final double tint;

  final double saturation;
  final double vibrance;

  final double toneBlack;
  final double toneShadow;
  final double toneMid;
  final double toneHighlight;
  final double toneWhite;

  final double vignette;
  final double centerGlow;

  @override
  State<PremiumFilterShader> createState() =>
      _PremiumFilterShaderState();
}

class _PremiumFilterShaderState
    extends State<PremiumFilterShader> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();

    _loadShader();
  }

  Future<void> _loadShader() async {
    final program =
        await ui.FragmentProgram.fromAsset(
      'shaders/neurolens_filter.frag',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _program = program;
    });
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;

    if (program == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _PremiumFilterPainter(
        program: program,
        image: widget.image,
        intensity: widget.intensity,
        exposure: widget.exposure,
        contrast: widget.contrast,
        temperature: widget.temperature,
        tint: widget.tint,
        saturation: widget.saturation,
        vibrance: widget.vibrance,
        toneBlack: widget.toneBlack,
        toneShadow: widget.toneShadow,
        toneMid: widget.toneMid,
        toneHighlight:
            widget.toneHighlight,
        toneWhite: widget.toneWhite,
        vignette: widget.vignette,
        centerGlow:
            widget.centerGlow,
      ),
      size: Size.infinite,
    );
  }
}

class _PremiumFilterPainter
    extends CustomPainter {
  const _PremiumFilterPainter({
    required this.program,
    required this.image,
    required this.intensity,
    required this.exposure,
    required this.contrast,
    required this.temperature,
    required this.tint,
    required this.saturation,
    required this.vibrance,
    required this.toneBlack,
    required this.toneShadow,
    required this.toneMid,
    required this.toneHighlight,
    required this.toneWhite,
    required this.vignette,
    required this.centerGlow,
  });

  final ui.FragmentProgram program;

  final ui.Image image;

  final double intensity;

  final double exposure;
  final double contrast;

  final double temperature;
  final double tint;

  final double saturation;
  final double vibrance;

  final double toneBlack;
  final double toneShadow;
  final double toneMid;
  final double toneHighlight;
  final double toneWhite;

  final double vignette;
  final double centerGlow;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final shader =
        program.fragmentShader();

    // =========================================================================
    // FLOAT UNIFORMS
    // =========================================================================
    //
    // Shader uniform order:
    //
    // 0  uSize.x
    // 1  uSize.y
    //
    // 2  uIntensity
    //
    // 3  uExposure
    // 4  uContrast
    //
    // 5  uTemperature
    // 6  uTint
    // 7  uSaturation
    // 8  uVibrance
    //
    // 9  uToneBlack
    // 10 uToneShadow
    // 11 uToneMid
    // 12 uToneHighlight
    // 13 uToneWhite
    //
    // 14 uVignette
    // 15 uCenterGlow
    //
    // sampler2D uTexture:
    // image sampler index 0
    // =========================================================================

    shader.setFloat(
      0,
      size.width,
    );

    shader.setFloat(
      1,
      size.height,
    );

    // -------------------------------------------------------------------------
    // INTENSITY
    // -------------------------------------------------------------------------

    shader.setFloat(
      2,
      intensity.clamp(
        0.0,
        1.0,
      ),
    );

    // -------------------------------------------------------------------------
    // LIGHT
    // -------------------------------------------------------------------------

    shader.setFloat(
      3,
      exposure,
    );

    shader.setFloat(
      4,
      contrast,
    );

    // -------------------------------------------------------------------------
    // WHITE BALANCE / GLOBAL COLOR
    // -------------------------------------------------------------------------

    shader.setFloat(
      5,
      temperature,
    );

    shader.setFloat(
      6,
      tint,
    );

    shader.setFloat(
      7,
      saturation,
    );

    shader.setFloat(
      8,
      vibrance,
    );

    // -------------------------------------------------------------------------
    // TONE CURVE
    // -------------------------------------------------------------------------

    shader.setFloat(
      9,
      toneBlack.clamp(
        0.0,
        1.0,
      ),
    );

    shader.setFloat(
      10,
      toneShadow.clamp(
        0.0,
        1.0,
      ),
    );

    shader.setFloat(
      11,
      toneMid.clamp(
        0.0,
        1.0,
      ),
    );

    shader.setFloat(
      12,
      toneHighlight.clamp(
        0.0,
        1.0,
      ),
    );

    shader.setFloat(
      13,
      toneWhite.clamp(
        0.0,
        1.0,
      ),
    );

    // -------------------------------------------------------------------------
    // SPATIAL EFFECTS
    // -------------------------------------------------------------------------

    shader.setFloat(
      14,
      vignette.clamp(
        0.0,
        1.0,
      ),
    );

    shader.setFloat(
      15,
      centerGlow.clamp(
        0.0,
        1.0,
      ),
    );

    // =========================================================================
    // IMAGE SAMPLER
    // =========================================================================

    shader.setImageSampler(
      0,
      image,
    );

    final paint =
        Paint()
          ..shader =
              shader;

    // =========================================================================
    // IMAGE SIZE
    // =========================================================================

    final imageWidth =
        image.width.toDouble();

    final imageHeight =
        image.height.toDouble();

    if (imageWidth <= 0 ||
        imageHeight <= 0) {
      return;
    }

    // =========================================================================
    // CONTAIN IMAGE INSIDE AVAILABLE BOUNDS
    // =========================================================================

    final scale =
        _containScale(
      sourceWidth:
          imageWidth,
      sourceHeight:
          imageHeight,
      targetWidth:
          size.width,
      targetHeight:
          size.height,
    );

    final outputWidth =
        imageWidth *
        scale;

    final outputHeight =
        imageHeight *
        scale;

    final left =
        (
          size.width -
          outputWidth
        ) /
        2.0;

    final top =
        (
          size.height -
          outputHeight
        ) /
        2.0;

    final destinationRect =
        Rect.fromLTWH(
      left,
      top,
      outputWidth,
      outputHeight,
    );

    // =========================================================================
    // DRAW SHADER
    // =========================================================================

    canvas.save();

    // Do not let the GPU filter leak into
    // the surrounding editor canvas.
    canvas.clipRect(
      destinationRect,
    );

    // Shift shader coordinates so FlutterFragCoord
    // starts at the image's local top-left.
    canvas.translate(
      destinationRect.left,
      destinationRect.top,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        destinationRect.width,
        destinationRect.height,
      ),
      paint,
    );

    canvas.restore();
  }

  // ===========================================================================
  // CONTAIN SCALE
  // ===========================================================================

  static double _containScale({
    required double sourceWidth,
    required double sourceHeight,
    required double targetWidth,
    required double targetHeight,
  }) {
    final scaleX =
        targetWidth /
        sourceWidth;

    final scaleY =
        targetHeight /
        sourceHeight;

    return scaleX < scaleY
        ? scaleX
        : scaleY;
  }

  // ===========================================================================
  // REPAINT
  // ===========================================================================

  @override
  bool shouldRepaint(
    covariant _PremiumFilterPainter
        oldDelegate,
  ) {
    return oldDelegate.program !=
            program ||
        oldDelegate.image !=
            image ||
        oldDelegate.intensity !=
            intensity ||
        oldDelegate.exposure !=
            exposure ||
        oldDelegate.contrast !=
            contrast ||
        oldDelegate.temperature !=
            temperature ||
        oldDelegate.tint !=
            tint ||
        oldDelegate.saturation !=
            saturation ||
        oldDelegate.vibrance !=
            vibrance ||
        oldDelegate.toneBlack !=
            toneBlack ||
        oldDelegate.toneShadow !=
            toneShadow ||
        oldDelegate.toneMid !=
            toneMid ||
        oldDelegate.toneHighlight !=
            toneHighlight ||
        oldDelegate.toneWhite !=
            toneWhite ||
        oldDelegate.vignette !=
            vignette ||
        oldDelegate.centerGlow !=
            centerGlow;
  }
}