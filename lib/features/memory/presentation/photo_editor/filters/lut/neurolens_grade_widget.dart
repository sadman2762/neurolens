import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'neurolens_filter_recipe.dart';

class NeuroLensGradeWidget extends StatefulWidget {
  const NeuroLensGradeWidget({
    required this.child,
    required this.recipe,
    required this.intensity,
    this.backdrop = false,
    super.key,
  });

  final Widget child;

  final NeuroLensFilterRecipe recipe;

  /// 0.0 = original
  /// 1.0 = full filter
  final double intensity;

  /// false:
  /// Filters [child] directly.
  ///
  /// true:
  /// Filters the already-rendered content behind this widget.
  ///
  /// We use backdrop mode inside ProImageEditor's bodyItemsRecorded.
  final bool backdrop;

  @override
  State<NeuroLensGradeWidget> createState() =>
      _NeuroLensGradeWidgetState();
}

class _NeuroLensGradeWidgetState
    extends State<NeuroLensGradeWidget> {
  static const String _shaderAsset =
      'shaders/neurolens_grade.frag';

  static ui.FragmentProgram? _cachedProgram;

  ui.FragmentShader? _shader;

  bool _loading = true;

  bool _supported = true;

  @override
  void initState() {
    super.initState();

    _loadShader();
  }

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> _loadShader() async {
    try {
      // ImageFilter.shader currently depends on
      // shader-filter support from the active renderer.
      if (!ui.ImageFilter.isShaderFilterSupported) {
        if (!mounted) {
          return;
        }

        setState(() {
          _supported = false;
          _loading = false;
        });

        return;
      }

      final program =
          _cachedProgram ??
          await ui.FragmentProgram.fromAsset(
            _shaderAsset,
          );

      _cachedProgram = program;

      final shader =
          program.fragmentShader();

      if (!mounted) {
        return;
      }

      setState(() {
        _shader = shader;
        _supported = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _supported = false;
        _loading = false;
      });
    }
  }

  // ===========================================================================
  // UNIFORMS
  // ===========================================================================

  void _updateShader() {
    final shader =
        _shader;

    if (shader == null) {
      return;
    }

    final intensity =
        widget.intensity.clamp(
      0.0,
      1.0,
    );

    final recipe =
        widget.recipe.withIntensity(
      intensity,
    );

    // Flutter ImageFilter.shader automatically owns:
    //
    // float 0 = texture width
    // float 1 = texture height
    //
    // Therefore our custom uniforms begin at index 2.

    shader.setFloat(
      2,
      recipe.exposure,
    );

    shader.setFloat(
      3,
      recipe.contrast,
    );

    shader.setFloat(
      4,
      recipe.saturation,
    );

    shader.setFloat(
      5,
      recipe.temperature,
    );

    shader.setFloat(
      6,
      recipe.tint,
    );

    shader.setFloat(
      7,
      recipe.fade,
    );

    shader.setFloat(
      8,
      recipe.shadowLift,
    );

    shader.setFloat(
      9,
      recipe.highlightRollOff,
    );

    shader.setFloat(
      10,
      recipe.vignette,
    );

    // Recipe values have already been interpolated
    // from identity -> full filter.
    shader.setFloat(
      11,
      1.0,
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final intensity =
        widget.intensity.clamp(
      0.0,
      1.0,
    );

    if (intensity <= 0.001) {
      return widget.child;
    }

    if (_loading ||
        !_supported ||
        _shader == null) {
      return widget.child;
    }

    _updateShader();

    final imageFilter =
        ui.ImageFilter.shader(
      _shader!,
    );

    // ProImageEditor bodyItemsRecorded needs
    // to grade the already-rendered image underneath.
    if (widget.backdrop) {
      return ClipRect(
        child: BackdropFilter(
          filter: imageFilter,
          child: widget.child,
        ),
      );
    }

    // Thumbnail / normal widget usage.
    return ClipRect(
      child: ImageFiltered(
        imageFilter:
            imageFilter,
        child:
            widget.child,
      ),
    );
  }
}