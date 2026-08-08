import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:neurolens/core/ai/onnx_inference_runner.dart';
import 'package:neurolens/features/memory/data/inpainting/inpainting_preprocessor.dart';

class InpaintingPostprocessor {
  const InpaintingPostprocessor({
    this.blendMaskErosionRadius = 3,
    this.featherRadius = 1,

    /// Additional hard-protection expansion in the postprocessor.
    ///
    /// Keep this at 0 because Adaptive Contact Protection already decides
    /// exactly which protection pixels should remain protected.
    this.protectionRestoreGuardRadius = 0,

    /// Generated strength for pixels deliberately released from Protect
    /// at an object/person contact boundary.
    ///
    /// 1.0 = 100% LaMa result.
    ///
    /// This prevents the original white shirt / skin / subject colour from
    /// contaminating the reconstructed background.
    this.contactGeneratedStrength = 1.0,
  });

  /// Shrinks the visible normal LaMa region slightly before compositing.
  final int blendMaskErosionRadius;

  /// Normal reconstruction-boundary feather.
  final int featherRadius;

  /// Optional extra protection expansion.
  final int protectionRestoreGuardRadius;

  /// How strongly released contact pixels use generated LaMa content.
  ///
  /// Recommended: 1.0.
  final double contactGeneratedStrength;

  // ===========================================================================
  // PROCESS
  // ===========================================================================

  Future<Uint8List> process({
    required Uint8List originalImageBytes,
    required PreparedInpaintingInput preparedInput,
    required OnnxFloatOutput modelOutput,
  }) async {
    if (originalImageBytes.isEmpty) {
      throw const InpaintingPostprocessorException(
        'The original image is empty.',
      );
    }

    const expectedShape = <int>[
      1,
      3,
      InpaintingPreprocessor.modelSize,
      InpaintingPreprocessor.modelSize,
    ];

    _validateOutputShape(
      actual: modelOutput.shape,
      expected: expectedShape,
    );

    const modelSize = InpaintingPreprocessor.modelSize;
    const pixelCount = modelSize * modelSize;

    if (modelOutput.values.length != pixelCount * 3) {
      throw InpaintingPostprocessorException(
        'Unexpected LaMa output length: '
        '${modelOutput.values.length}.',
      );
    }

    if (preparedInput.modelMask.length != pixelCount) {
      throw InpaintingPostprocessorException(
        'Unexpected model mask length: '
        '${preparedInput.modelMask.length}.',
      );
    }

    if (preparedInput.protectionMask.length != pixelCount) {
      throw InpaintingPostprocessorException(
        'Unexpected protection mask length: '
        '${preparedInput.protectionMask.length}.',
      );
    }

    if (preparedInput.contactReleaseMask.length != pixelCount) {
      throw InpaintingPostprocessorException(
        'Unexpected contact release mask length: '
        '${preparedInput.contactReleaseMask.length}.',
      );
    }

    ui.Image? originalImage;
    ui.Image? originalModelCrop;
    ui.Image? opaqueRepairedCrop;

    try {
      // =====================================================================
      // DECODE ORIGINAL
      // =====================================================================

      originalImage = await _decodeImage(
        originalImageBytes,
      );

      if (originalImage.width != preparedInput.originalWidth ||
          originalImage.height != preparedInput.originalHeight) {
        throw InpaintingPostprocessorException(
          'Original image dimensions changed. '
          'Expected '
          '${preparedInput.originalWidth}x'
          '${preparedInput.originalHeight}, '
          'received '
          '${originalImage.width}x'
          '${originalImage.height}.',
        );
      }

      // =====================================================================
      // ORIGINAL LOCAL CROP -> 512
      // =====================================================================

      originalModelCrop = await _renderCrop(
        sourceImage: originalImage,
        sourceRect: preparedInput.cropRect,
        outputWidth: modelSize,
        outputHeight: modelSize,
        filterQuality: ui.FilterQuality.high,
      );

      final originalCropRgba = await _readRgba(
        originalModelCrop,
      );

      // =====================================================================
      // HARD PROTECTION
      // =====================================================================

      final hardProtectionMask = _createHardProtectionMask(
        preparedInput.protectionMask,
        width: modelSize,
        height: modelSize,
      );

      // =====================================================================
      // CONTACT RELEASE
      //
      // These pixels have deliberately been removed from Protect by the
      // adaptive contact algorithm.
      //
      // They must never accidentally become protected again here.
      // =====================================================================

      final contactReleaseMask = _createBinaryMask(
        preparedInput.contactReleaseMask,
        width: modelSize,
        height: modelSize,
      );

      // =====================================================================
      // NORMAL BLEND MASK
      // =====================================================================

      final blendMask = _createBlendMask(
        preparedInput.modelMask,
        protectionMask: hardProtectionMask,
        contactReleaseMask: contactReleaseMask,
        width: modelSize,
        height: modelSize,
      );

      final outputRange = _detectOutputRange(
        modelOutput.values,
      );

      debugPrint(
        'LaMa output range: ${outputRange.name}',
      );

      // =====================================================================
      // FINAL PIXEL COMPOSITE
      //
      // Priority:
      //
      // 1. Contact-release pixel -> GENERATED
      // 2. Protected pixel      -> ORIGINAL
      // 3. Everything else      -> normal blend
      //
      // IMPORTANT:
      //
      // Contact release is checked FIRST because those pixels originally
      // belonged to Protect but have intentionally been released.
      // =====================================================================

      final compositedRgba = _createOpaqueComposite(
        originalRgba: originalCropRgba,
        generatedOutput: modelOutput.values,
        blendMask: blendMask,
        protectionMask: hardProtectionMask,
        contactReleaseMask: contactReleaseMask,
        outputRange: outputRange,
      );

      opaqueRepairedCrop = await _rgbaToImage(
        compositedRgba,
        width: modelSize,
        height: modelSize,
      );

      // =====================================================================
      // DRAW ORIGINAL FULL IMAGE
      // =====================================================================

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
      );

      final fullImageRect = ui.Rect.fromLTWH(
        0,
        0,
        originalImage.width.toDouble(),
        originalImage.height.toDouble(),
      );

      canvas.drawImageRect(
        originalImage,
        fullImageRect,
        fullImageRect,
        ui.Paint()
          ..filterQuality = ui.FilterQuality.none,
      );

      // =====================================================================
      // DRAW REPAIRED CROP
      // =====================================================================

      canvas.drawImageRect(
        opaqueRepairedCrop,
        ui.Rect.fromLTWH(
          0,
          0,
          modelSize.toDouble(),
          modelSize.toDouble(),
        ),
        preparedInput.cropRect,
        ui.Paint()
          ..filterQuality = ui.FilterQuality.high,
      );

      final picture = recorder.endRecording();

      ui.Image? finalImage;

      try {
        finalImage = await picture.toImage(
          preparedInput.originalWidth,
          preparedInput.originalHeight,
        );

        final byteData = await finalImage.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData == null) {
          throw const InpaintingPostprocessorException(
            'Could not encode the final inpainted image.',
          );
        }

        final result = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );

        debugPrint(
          '===== Offline inpainting composite =====',
        );

        debugPrint(
          'Full image: '
          '${preparedInput.originalWidth}x'
          '${preparedInput.originalHeight}',
        );

        debugPrint(
          'Local crop: '
          '${preparedInput.cropRect.width.toStringAsFixed(0)}x'
          '${preparedInput.cropRect.height.toStringAsFixed(0)}',
        );

        debugPrint(
          'Blend erosion: '
          '$blendMaskErosionRadius px',
        );

        debugPrint(
          'Blend feather: '
          '$featherRadius px',
        );

        debugPrint(
          'Protection restore guard: '
          '$protectionRestoreGuardRadius px',
        );

        debugPrint(
          'Protected original-pixel restoration: '
          '${preparedInput.hasProtection ? 'enabled' : 'disabled'}',
        );

        debugPrint(
          'Contact-release generated forcing: '
          '${preparedInput.hasContactRelease ? 'enabled' : 'disabled'}',
        );

        debugPrint(
          'Contact generated strength: '
          '${contactGeneratedStrength.toStringAsFixed(2)}',
        );

        debugPrint(
          'Contact-release pixels: '
          '${preparedInput.contactReleasedPixelCount}',
        );

        debugPrint(
          'Opaque pixel compositing: enabled',
        );

        debugPrint(
          'Final PNG bytes: ${result.length}',
        );

        debugPrint(
          '========================================',
        );

        return result;
      } finally {
        finalImage?.dispose();
        picture.dispose();
      }
    } finally {
      opaqueRepairedCrop?.dispose();
      originalModelCrop?.dispose();
      originalImage?.dispose();
    }
  }

  // ===========================================================================
  // BINARY MASK
  // ===========================================================================

  Float32List _createBinaryMask(
    Float32List source, {
    required int width,
    required int height,
  }) {
    if (source.length != width * height) {
      throw const InpaintingPostprocessorException(
        'Invalid binary mask dimensions.',
      );
    }

    final result = Float32List(
      source.length,
    );

    for (var index = 0; index < source.length; index++) {
      result[index] = source[index] >= 0.5 ? 1.0 : 0.0;
    }

    return result;
  }

  // ===========================================================================
  // HARD PROTECTION
  // ===========================================================================

  Float32List _createHardProtectionMask(
    Float32List source, {
    required int width,
    required int height,
  }) {
    final binary = _createBinaryMask(
      source,
      width: width,
      height: height,
    );

    if (protectionRestoreGuardRadius <= 0) {
      return binary;
    }

    return _dilateMask(
      binary,
      width: width,
      height: height,
      radius: protectionRestoreGuardRadius,
    );
  }

  // ===========================================================================
  // OPAQUE COMPOSITE
  // ===========================================================================

  Uint8List _createOpaqueComposite({
    required Uint8List originalRgba,
    required Float32List generatedOutput,
    required Float32List blendMask,
    required Float32List protectionMask,
    required Float32List contactReleaseMask,
    required _ModelOutputRange outputRange,
  }) {
    const size = InpaintingPreprocessor.modelSize;
    const pixelCount = size * size;

    if (originalRgba.length != pixelCount * 4) {
      throw const InpaintingPostprocessorException(
        'Unexpected original crop buffer size.',
      );
    }

    if (blendMask.length != pixelCount) {
      throw const InpaintingPostprocessorException(
        'Unexpected blend mask size.',
      );
    }

    if (protectionMask.length != pixelCount) {
      throw const InpaintingPostprocessorException(
        'Unexpected protection mask size.',
      );
    }

    if (contactReleaseMask.length != pixelCount) {
      throw const InpaintingPostprocessorException(
        'Unexpected contact release mask size.',
      );
    }

    final output = Uint8List(
      pixelCount * 4,
    );

    const redOffset = 0;
    const greenOffset = pixelCount;
    const blueOffset = pixelCount * 2;

    var restoredProtectedPixels = 0;
    var forcedGeneratedContactPixels = 0;

    for (var index = 0; index < pixelCount; index++) {
      final rgbaIndex = index * 4;

      // =====================================================================
      // GENERATED RGB
      // =====================================================================

      final generatedRed = _normalizeOutputValue(
        generatedOutput[
          redOffset + index
        ],
        outputRange,
      );

      final generatedGreen = _normalizeOutputValue(
        generatedOutput[
          greenOffset + index
        ],
        outputRange,
      );

      final generatedBlue = _normalizeOutputValue(
        generatedOutput[
          blueOffset + index
        ],
        outputRange,
      );

      // =====================================================================
      // PRIORITY 1
      // CONTACT RELEASE -> GENERATED BACKGROUND
      //
      // This is the critical new rule.
      //
      // The adaptive preprocessor specifically said:
      //
      // "This pixel was previously protected, but it lies in the actual
      // Remove/Protect collision strip. Let reconstruction own it."
      //
      // Therefore we do NOT use normal feathering here.
      // =====================================================================

      if (contactReleaseMask[index] >= 0.5) {
        final strength = contactGeneratedStrength
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

        if (strength >= 0.999) {
          output[rgbaIndex] =
              (generatedRed * 255)
                  .round()
                  .clamp(
                    0,
                    255,
                  );

          output[rgbaIndex + 1] =
              (generatedGreen * 255)
                  .round()
                  .clamp(
                    0,
                    255,
                  );

          output[rgbaIndex + 2] =
              (generatedBlue * 255)
                  .round()
                  .clamp(
                    0,
                    255,
                  );
        } else {
          final originalRed =
              originalRgba[rgbaIndex] /
              255.0;

          final originalGreen =
              originalRgba[
                      rgbaIndex + 1] /
                  255.0;

          final originalBlue =
              originalRgba[
                      rgbaIndex + 2] /
                  255.0;

          final inverseStrength =
              1.0 - strength;

          final red =
              generatedRed *
                  strength +
              originalRed *
                  inverseStrength;

          final green =
              generatedGreen *
                  strength +
              originalGreen *
                  inverseStrength;

          final blue =
              generatedBlue *
                  strength +
              originalBlue *
                  inverseStrength;

          output[rgbaIndex] =
              (red * 255)
                  .round()
                  .clamp(
                    0,
                    255,
                  );

          output[rgbaIndex + 1] =
              (green * 255)
                  .round()
                  .clamp(
                    0,
                    255,
                  );

          output[rgbaIndex + 2] =
              (blue * 255)
                  .round()
                  .clamp(
                    0,
                    255,
                  );
        }

        output[rgbaIndex + 3] =
            255;

        forcedGeneratedContactPixels++;

        continue;
      }

      // =====================================================================
      // PRIORITY 2
      // STRICT PROTECTION -> EXACT ORIGINAL
      // =====================================================================

      if (protectionMask[index] >= 0.5) {
        output[rgbaIndex] =
            originalRgba[rgbaIndex];

        output[rgbaIndex + 1] =
            originalRgba[rgbaIndex + 1];

        output[rgbaIndex + 2] =
            originalRgba[rgbaIndex + 2];

        output[rgbaIndex + 3] =
            255;

        restoredProtectedPixels++;

        continue;
      }

      // =====================================================================
      // PRIORITY 3
      // NORMAL BLEND
      // =====================================================================

      final originalRed =
          originalRgba[rgbaIndex] /
          255.0;

      final originalGreen =
          originalRgba[
                  rgbaIndex + 1] /
              255.0;

      final originalBlue =
          originalRgba[
                  rgbaIndex + 2] /
              255.0;

      var alpha = blendMask[index]
          .clamp(
            0.0,
            1.0,
          )
          .toDouble();

      if (alpha < 0.03) {
        alpha = 0.0;
      } else if (alpha > 0.97) {
        alpha = 1.0;
      } else {
        alpha = _smoothStep(
          alpha,
        );
      }

      final inverseAlpha =
          1.0 - alpha;

      final finalRed =
          generatedRed *
              alpha +
          originalRed *
              inverseAlpha;

      final finalGreen =
          generatedGreen *
              alpha +
          originalGreen *
              inverseAlpha;

      final finalBlue =
          generatedBlue *
              alpha +
          originalBlue *
              inverseAlpha;

      output[rgbaIndex] =
          (finalRed * 255)
              .round()
              .clamp(
                0,
                255,
              );

      output[rgbaIndex + 1] =
          (finalGreen * 255)
              .round()
              .clamp(
                0,
                255,
              );

      output[rgbaIndex + 2] =
          (finalBlue * 255)
              .round()
              .clamp(
                0,
                255,
              );

      output[rgbaIndex + 3] =
          255;
    }

    debugPrint(
      'Protected pixels restored from original: '
      '$restoredProtectedPixels',
    );

    debugPrint(
      'Contact pixels forced generated: '
      '$forcedGeneratedContactPixels',
    );

    return output;
  }

  // ===========================================================================
  // BLEND MASK
  // ===========================================================================

  Float32List _createBlendMask(
    Float32List inferenceMask, {
    required Float32List protectionMask,
    required Float32List contactReleaseMask,
    required int width,
    required int height,
  }) {
    if (inferenceMask.length != width * height) {
      throw const InpaintingPostprocessorException(
        'Invalid inference mask dimensions.',
      );
    }

    if (protectionMask.length != width * height) {
      throw const InpaintingPostprocessorException(
        'Invalid protection mask dimensions.',
      );
    }

    if (contactReleaseMask.length != width * height) {
      throw const InpaintingPostprocessorException(
        'Invalid contact release mask dimensions.',
      );
    }

    // =======================================================================
    // 1. NORMAL RECONSTRUCTION EROSION
    // =======================================================================

    final eroded = _erodeMask(
      inferenceMask,
      width: width,
      height: height,
      radius: blendMaskErosionRadius,
    );

    Float32List blendMask;

    // =======================================================================
    // 2. NORMAL FEATHER
    // =======================================================================

    if (featherRadius > 0) {
      blendMask = _boxBlur(
        eroded,
        width: width,
        height: height,
        radius: featherRadius,
      );

      for (var index = 0;
          index < eroded.length;
          index++) {
        if (eroded[index] >= 0.99) {
          blendMask[index] =
              1.0;
        }
      }
    } else {
      blendMask =
          Float32List.fromList(
        eroded,
      );
    }

    var zeroedProtectedPixels = 0;
    var forcedContactPixels = 0;

    // =======================================================================
    // 3. FINAL MASK PRIORITIES
    //
    // contactRelease -> alpha 1
    //
    // protection     -> alpha 0
    //
    // everything else keeps normal blend.
    // =======================================================================

    for (var index = 0;
        index < blendMask.length;
        index++) {
      if (contactReleaseMask[index] >=
          0.5) {
        blendMask[index] =
            1.0;

        forcedContactPixels++;

        continue;
      }

      if (protectionMask[index] >=
          0.5) {
        blendMask[index] =
            0.0;

        zeroedProtectedPixels++;
      }
    }

    debugPrint(
      'Blend pixels forced original by protection: '
      '$zeroedProtectedPixels',
    );

    debugPrint(
      'Blend pixels forced generated by contact release: '
      '$forcedContactPixels',
    );

    return blendMask;
  }

  // ===========================================================================
  // DILATION
  // ===========================================================================

  Float32List _dilateMask(
    Float32List source, {
    required int width,
    required int height,
    required int radius,
  }) {
    if (radius <= 0) {
      return Float32List.fromList(
        source,
      );
    }

    if (source.length != width * height) {
      throw const InpaintingPostprocessorException(
        'Invalid mask dimensions for dilation.',
      );
    }

    final horizontal =
        Float32List(
      source.length,
    );

    final output =
        Float32List(
      source.length,
    );

    for (var y = 0; y < height; y++) {
      final row =
          y * width;

      for (var x = 0; x < width; x++) {
        final minX =
            math.max(
          0,
          x - radius,
        );

        final maxX =
            math.min(
          width - 1,
          x + radius,
        );

        for (var sampleX = minX;
            sampleX <= maxX;
            sampleX++) {
          if (source[
                  row + sampleX] >=
              0.5) {
            horizontal[
              row + x
            ] = 1.0;

            break;
          }
        }
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final minY =
            math.max(
          0,
          y - radius,
        );

        final maxY =
            math.min(
          height - 1,
          y + radius,
        );

        for (var sampleY = minY;
            sampleY <= maxY;
            sampleY++) {
          if (horizontal[
                  sampleY *
                          width +
                      x] >=
              0.5) {
            output[
              y * width + x
            ] = 1.0;

            break;
          }
        }
      }
    }

    return output;
  }

  // ===========================================================================
  // EROSION
  // ===========================================================================

  Float32List _erodeMask(
    Float32List source, {
    required int width,
    required int height,
    required int radius,
  }) {
    if (radius <= 0) {
      return Float32List.fromList(
        source,
      );
    }

    if (source.length != width * height) {
      throw const InpaintingPostprocessorException(
        'Invalid mask dimensions for erosion.',
      );
    }

    final horizontal =
        Float32List(
      source.length,
    );

    final output =
        Float32List(
      source.length,
    );

    // Horizontal minimum.

    for (var y = 0; y < height; y++) {
      final row =
          y * width;

      for (var x = 0; x < width; x++) {
        var minimum = 1.0;

        final minX =
            math.max(
          0,
          x - radius,
        );

        final maxX =
            math.min(
          width - 1,
          x + radius,
        );

        for (var sampleX = minX;
            sampleX <= maxX;
            sampleX++) {
          final value =
              source[
            row + sampleX
          ];

          if (value < minimum) {
            minimum = value;
          }

          if (minimum <= 0) {
            break;
          }
        }

        horizontal[
          row + x
        ] = minimum;
      }
    }

    // Vertical minimum.

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var minimum = 1.0;

        final minY =
            math.max(
          0,
          y - radius,
        );

        final maxY =
            math.min(
          height - 1,
          y + radius,
        );

        for (var sampleY = minY;
            sampleY <= maxY;
            sampleY++) {
          final value =
              horizontal[
            sampleY *
                    width +
                x
          ];

          if (value < minimum) {
            minimum = value;
          }

          if (minimum <= 0) {
            break;
          }
        }

        output[
          y * width + x
        ] = minimum;
      }
    }

    return output;
  }

  // ===========================================================================
  // FEATHER
  // ===========================================================================

  Float32List _boxBlur(
    Float32List source, {
    required int width,
    required int height,
    required int radius,
  }) {
    if (radius <= 0) {
      return Float32List.fromList(
        source,
      );
    }

    final horizontal =
        Float32List(
      source.length,
    );

    final output =
        Float32List(
      source.length,
    );

    final kernelSize =
        radius * 2 + 1;

    // Horizontal.

    for (var y = 0; y < height; y++) {
      final rowOffset =
          y * width;

      var sum = 0.0;

      for (var x = -radius;
          x <= radius;
          x++) {
        final sampleX = x
            .clamp(
              0,
              width - 1,
            )
            .toInt();

        sum +=
            source[
          rowOffset + sampleX
        ];
      }

      for (var x = 0; x < width; x++) {
        horizontal[
          rowOffset + x
        ] = sum / kernelSize;

        final removeX =
            (x - radius)
                .clamp(
                  0,
                  width - 1,
                )
                .toInt();

        final addX =
            (x +
                    radius +
                    1)
                .clamp(
                  0,
                  width - 1,
                )
                .toInt();

        sum -=
            source[
          rowOffset + removeX
        ];

        sum +=
            source[
          rowOffset + addX
        ];
      }
    }

    // Vertical.

    for (var x = 0; x < width; x++) {
      var sum = 0.0;

      for (var y = -radius;
          y <= radius;
          y++) {
        final sampleY = y
            .clamp(
              0,
              height - 1,
            )
            .toInt();

        sum +=
            horizontal[
          sampleY *
                  width +
              x
        ];
      }

      for (var y = 0; y < height; y++) {
        output[
          y * width + x
        ] = sum / kernelSize;

        final removeY =
            (y - radius)
                .clamp(
                  0,
                  height - 1,
                )
                .toInt();

        final addY =
            (y +
                    radius +
                    1)
                .clamp(
                  0,
                  height - 1,
                )
                .toInt();

        sum -=
            horizontal[
          removeY *
                  width +
              x
        ];

        sum +=
            horizontal[
          addY *
                  width +
              x
        ];
      }
    }

    return output;
  }

  // ===========================================================================
  // SMOOTH STEP
  // ===========================================================================

  double _smoothStep(
    double value,
  ) {
    final x = value
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    return x *
        x *
        (3.0 - 2.0 * x);
  }

  // ===========================================================================
  // OUTPUT RANGE
  // ===========================================================================

  _ModelOutputRange _detectOutputRange(
    Float32List output,
  ) {
    var minimum =
        double.infinity;

    var maximum =
        double.negativeInfinity;

    final step =
        math.max(
      1,
      output.length ~/ 10000,
    );

    for (var index = 0;
        index < output.length;
        index += step) {
      final value =
          output[index];

      if (value < minimum) {
        minimum = value;
      }

      if (value > maximum) {
        maximum = value;
      }
    }

    debugPrint(
      'LaMa output sampled min/max: '
      '${minimum.toStringAsFixed(3)} / '
      '${maximum.toStringAsFixed(3)}',
    );

    if (minimum < -0.05) {
      return _ModelOutputRange
          .minusOneToOne;
    }

    return _ModelOutputRange
        .zeroToOne;
  }

  double _normalizeOutputValue(
    double value,
    _ModelOutputRange range,
  ) {
    switch (range) {
      case _ModelOutputRange.zeroToOne:
        return value
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

      case _ModelOutputRange.minusOneToOne:
        return ((value + 1.0) / 2.0)
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();
    }
  }

  // ===========================================================================
  // RENDER CROP
  // ===========================================================================

  Future<ui.Image> _renderCrop({
    required ui.Image sourceImage,
    required ui.Rect sourceRect,
    required int outputWidth,
    required int outputHeight,
    required ui.FilterQuality filterQuality,
  }) async {
    final recorder =
        ui.PictureRecorder();

    final canvas =
        ui.Canvas(
      recorder,
    );

    final destinationRect =
        ui.Rect.fromLTWH(
      0,
      0,
      outputWidth.toDouble(),
      outputHeight.toDouble(),
    );

    canvas.drawImageRect(
      sourceImage,
      sourceRect,
      destinationRect,
      ui.Paint()
        ..filterQuality =
            filterQuality,
    );

    final picture =
        recorder.endRecording();

    try {
      return await picture.toImage(
        outputWidth,
        outputHeight,
      );
    } finally {
      picture.dispose();
    }
  }

  // ===========================================================================
  // RAW RGBA
  // ===========================================================================

  Future<Uint8List> _readRgba(
    ui.Image image,
  ) async {
    final byteData =
        await image.toByteData(
      format:
          ui.ImageByteFormat.rawRgba,
    );

    if (byteData == null) {
      throw const InpaintingPostprocessorException(
        'Could not read original crop pixels.',
      );
    }

    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }

  // ===========================================================================
  // IMAGE DECODING
  // ===========================================================================

  Future<ui.Image> _decodeImage(
    Uint8List bytes,
  ) async {
    final codec =
        await ui.instantiateImageCodec(
      bytes,
    );

    try {
      final frame =
          await codec.getNextFrame();

      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  // ===========================================================================
  // RGBA -> IMAGE
  // ===========================================================================

  Future<ui.Image> _rgbaToImage(
    Uint8List rgba, {
    required int width,
    required int height,
  }) async {
    if (rgba.length !=
        width * height * 4) {
      throw const InpaintingPostprocessorException(
        'Invalid composited crop pixel buffer.',
      );
    }

    final buffer =
        await ui.ImmutableBuffer
            .fromUint8List(
      rgba,
    );

    final descriptor =
        ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat:
          ui.PixelFormat.rgba8888,
    );

    ui.Codec? codec;
    ui.Image? temporaryImage;

    try {
      codec = await descriptor
          .instantiateCodec();

      final frame =
          await codec.getNextFrame();

      temporaryImage =
          frame.image;

      final pngData =
          await temporaryImage.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (pngData == null) {
        throw const InpaintingPostprocessorException(
          'Could not encode composited crop.',
        );
      }

      final pngBytes =
          pngData.buffer.asUint8List(
        pngData.offsetInBytes,
        pngData.lengthInBytes,
      );

      return _decodeImage(
        pngBytes,
      );
    } finally {
      temporaryImage?.dispose();
      codec?.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  void _validateOutputShape({
    required List<int> actual,
    required List<int> expected,
  }) {
    if (actual.length != expected.length) {
      throw InpaintingPostprocessorException(
        'Unexpected LaMa output shape. '
        'Expected $expected, '
        'received $actual.',
      );
    }

    for (var index = 0;
        index < expected.length;
        index++) {
      if (actual[index] != expected[index]) {
        throw InpaintingPostprocessorException(
          'Unexpected LaMa output shape. '
          'Expected $expected, '
          'received $actual.',
        );
      }
    }
  }
}

// =============================================================================
// OUTPUT RANGE
// =============================================================================

enum _ModelOutputRange {
  zeroToOne,
  minusOneToOne,
}

// =============================================================================
// EXCEPTION
// =============================================================================

class InpaintingPostprocessorException
    implements Exception {
  const InpaintingPostprocessorException(
    this.message,
  );

  final String message;

  @override
  String toString() =>
      message;
}