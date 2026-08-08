import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

class InpaintingPreprocessor {
  const InpaintingPreprocessor({
    this.cropPaddingFactor = 0.85,
    this.minimumPaddingPixels = 64,
    this.minimumCropSidePixels = 512,
    this.maskThreshold = 0.20,

    /// Small guaranteed expansion around explicitly selected remove pixels.
    this.coreRemovalExpansionRadius = 2,

    /// Wider cleanup/context region.
    this.inputMaskDilationRadius = 10,

    /// Global protection safety expansion.
    this.protectionSafetyRadius = 1,

    /// Radius around Remove/Protect collisions considered a contact zone.
    this.contactZoneRadius = 3,

    /// How far Protect is pulled inward only at contact boundaries.
    this.contactProtectionErosionRadius = 3,
  });

  static const int modelSize = 512;
  static const int imageChannels = 3;
  static const int totalChannels = 4;

  final double cropPaddingFactor;
  final int minimumPaddingPixels;
  final int minimumCropSidePixels;

  final double maskThreshold;

  final int coreRemovalExpansionRadius;
  final int inputMaskDilationRadius;
  final int protectionSafetyRadius;

  final int contactZoneRadius;
  final int contactProtectionErosionRadius;

  // ===========================================================================
  // PREPARE
  // ===========================================================================

  Future<PreparedInpaintingInput> prepare({
    required Uint8List imageBytes,
    required Uint8List maskBytes,
    Uint8List? protectionMaskBytes,
  }) async {
    if (imageBytes.isEmpty) {
      throw const InpaintingPreprocessorException(
        'The source image is empty.',
      );
    }

    if (maskBytes.isEmpty) {
      throw const InpaintingPreprocessorException(
        'The removal mask is empty.',
      );
    }

    ui.Image? sourceImage;
    ui.Image? removalImage;
    ui.Image? protectionImage;

    ui.Image? modelImage;
    ui.Image? modelRemovalMask;
    ui.Image? modelProtectionMask;

    try {
      // =====================================================================
      // DECODE
      // =====================================================================

      sourceImage = await _decodeImage(
        imageBytes,
      );

      removalImage = await _decodeImage(
        maskBytes,
      );

      if (protectionMaskBytes != null &&
          protectionMaskBytes.isNotEmpty) {
        protectionImage = await _decodeImage(
          protectionMaskBytes,
        );
      }

      final originalWidth = sourceImage.width;
      final originalHeight = sourceImage.height;

      if (originalWidth <= 0 ||
          originalHeight <= 0) {
        throw const InpaintingPreprocessorException(
          'The source image has invalid dimensions.',
        );
      }

      if (removalImage.width <= 0 ||
          removalImage.height <= 0) {
        throw const InpaintingPreprocessorException(
          'The removal mask has invalid dimensions.',
        );
      }

      if (protectionImage != null &&
          (protectionImage.width <= 0 ||
              protectionImage.height <= 0)) {
        throw const InpaintingPreprocessorException(
          'The protection mask has invalid dimensions.',
        );
      }

      debugPrint(
        '===== NeuroLens LaMa preprocessing =====',
      );

      debugPrint(
        'Image: ${originalWidth}x$originalHeight',
      );

      debugPrint(
        'Removal mask: '
        '${removalImage.width}x${removalImage.height}',
      );

      debugPrint(
        protectionImage == null
            ? 'Protection: disabled'
            : 'Protection mask: '
                '${protectionImage.width}x'
                '${protectionImage.height}',
      );

      // =====================================================================
      // REMOVE BOUNDS
      // =====================================================================

      final removalBounds = await _findMaskBounds(
        removalImage,
      );

      if (removalBounds == null) {
        throw const InpaintingPreprocessorException(
          'The removal mask contains no selected pixels.',
        );
      }

      final removalScaleX =
          originalWidth / removalImage.width;

      final removalScaleY =
          originalHeight / removalImage.height;

      final removalBoundsInImage = ui.Rect.fromLTRB(
        removalBounds.left * removalScaleX,
        removalBounds.top * removalScaleY,
        removalBounds.right * removalScaleX,
        removalBounds.bottom * removalScaleY,
      );

      // =====================================================================
      // LOCAL CROP
      // =====================================================================

      final cropRect = _buildCropRect(
        maskBounds: removalBoundsInImage,
        imageWidth: originalWidth,
        imageHeight: originalHeight,
      );

      debugPrint(
        'Removal bounds: '
        '${_formatRect(removalBoundsInImage)}',
      );

      debugPrint(
        'LaMa crop: '
        '${_formatRect(cropRect)}',
      );

      final removalCropRect = ui.Rect.fromLTRB(
        cropRect.left / removalScaleX,
        cropRect.top / removalScaleY,
        cropRect.right / removalScaleX,
        cropRect.bottom / removalScaleY,
      );

      // =====================================================================
      // SOURCE -> 512
      // =====================================================================

      modelImage = await _renderCrop(
        sourceImage: sourceImage,
        sourceRect: cropRect,
        outputWidth: modelSize,
        outputHeight: modelSize,
        filterQuality: ui.FilterQuality.high,
      );

      // =====================================================================
      // REMOVE MASK -> 512
      // =====================================================================

      modelRemovalMask = await _renderCrop(
        sourceImage: removalImage,
        sourceRect: removalCropRect,
        outputWidth: modelSize,
        outputHeight: modelSize,
        filterQuality: ui.FilterQuality.none,
      );

      // =====================================================================
      // PROTECTION MASK -> SAME 512 CROP
      // =====================================================================

      if (protectionImage != null) {
        final protectionScaleX =
            originalWidth / protectionImage.width;

        final protectionScaleY =
            originalHeight / protectionImage.height;

        final protectionCropRect = ui.Rect.fromLTRB(
          cropRect.left / protectionScaleX,
          cropRect.top / protectionScaleY,
          cropRect.right / protectionScaleX,
          cropRect.bottom / protectionScaleY,
        );

        modelProtectionMask = await _renderCrop(
          sourceImage: protectionImage,
          sourceRect: protectionCropRect,
          outputWidth: modelSize,
          outputHeight: modelSize,
          filterQuality: ui.FilterQuality.none,
        );
      }

      // =====================================================================
      // READ PIXELS
      // =====================================================================

      final imageRgba = await _readRgba(
        modelImage,
      );

      final removalRgba = await _readRgba(
        modelRemovalMask,
      );

      Uint8List? protectionRgba;

      if (modelProtectionMask != null) {
        protectionRgba = await _readRgba(
          modelProtectionMask,
        );
      }

      // =====================================================================
      // BUILD FINAL TENSOR
      // =====================================================================

      final tensorResult = _createInputTensor(
        imageRgba: imageRgba,
        removalRgba: removalRgba,
        protectionRgba: protectionRgba,
      );

      if (tensorResult.selectedPixels == 0) {
        throw const InpaintingPreprocessorException(
          'Nothing remains to remove.',
        );
      }

      // =====================================================================
      // LOGGING
      // =====================================================================

      debugPrint(
        'Final reconstruction: '
        '${tensorResult.selectedPixels} / '
        '${modelSize * modelSize}',
      );

      debugPrint(
        'Core cleanup radius: '
        '$coreRemovalExpansionRadius px',
      );

      debugPrint(
        'Outer dilation radius: '
        '$inputMaskDilationRadius px',
      );

      debugPrint(
        'Protection safety: '
        '$protectionSafetyRadius px',
      );

      debugPrint(
        'Contact zone radius: '
        '$contactZoneRadius px',
      );

      debugPrint(
        'Contact protection erosion: '
        '$contactProtectionErosionRadius px',
      );

      debugPrint(
        'Contact-zone pixels: '
        '${tensorResult.contactZonePixels}',
      );

      debugPrint(
        'Contact-release pixels: '
        '${tensorResult.releasedProtectionPixels}',
      );

      debugPrint(
        'Outer pixels blocked by protection: '
        '${tensorResult.blockedPixels}',
      );

      debugPrint(
        'Core pixels overriding protection: '
        '${tensorResult.coreOverridePixels}',
      );

      debugPrint(
        'Selected fraction: '
        '${(
          tensorResult.selectedPixels /
          (modelSize * modelSize) *
          100
        ).toStringAsFixed(2)}%',
      );

      debugPrint(
        tensorResult.protectedPixels > 0
            ? 'Smart Protect: ACTIVE'
            : 'Smart Protect: OFF',
      );

      debugPrint(
        tensorResult.releasedProtectionPixels > 0
            ? 'Adaptive Contact Protection: ACTIVE'
            : 'Adaptive Contact Protection: IDLE',
      );

      debugPrint(
        tensorResult.releasedProtectionPixels > 0
            ? 'Contact generated-pixel forcing: READY'
            : 'Contact generated-pixel forcing: IDLE',
      );

      debugPrint(
        'Mask priority: '
        'core > adaptive protect > outer cleanup',
      );

      debugPrint(
        '=========================================',
      );

      return PreparedInpaintingInput(
        tensor: tensorResult.tensor,
        modelMask: tensorResult.modelMask,

        /// Pixels still protected after adaptive contact erosion.
        protectionMask:
            tensorResult.protectionMask,

        /// NEW:
        ///
        /// Pixels that used to belong to Protect but were released at
        /// an actual Remove/Protect contact boundary.
        ///
        /// The postprocessor can now force these pixels to use the
        /// GENERATED LaMa output rather than mixing them with original
        /// shirt/person colours.
        contactReleaseMask:
            tensorResult.contactReleaseMask,

        cropRect: cropRect,

        originalWidth: originalWidth,
        originalHeight: originalHeight,

        modelWidth: modelSize,
        modelHeight: modelSize,

        selectedPixelCount:
            tensorResult.selectedPixels,

        protectedPixelCount:
            tensorResult.protectedPixels,

        contactReleasedPixelCount:
            tensorResult.releasedProtectionPixels,

        blockedPixelCount:
            tensorResult.blockedPixels,

        coreOverridePixelCount:
            tensorResult.coreOverridePixels,
      );
    } finally {
      modelProtectionMask?.dispose();
      modelRemovalMask?.dispose();
      modelImage?.dispose();

      protectionImage?.dispose();
      removalImage?.dispose();
      sourceImage?.dispose();
    }
  }

  // ===========================================================================
  // MASK BOUNDS
  // ===========================================================================

  Future<ui.Rect?> _findMaskBounds(
    ui.Image maskImage,
  ) async {
    final rgba = await _readRgba(
      maskImage,
    );

    final width = maskImage.width;
    final height = maskImage.height;

    var minX = width;
    var minY = height;

    var maxX = -1;
    var maxY = -1;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index =
            (y * width + x) * 4;

        if (_maskStrength(
              rgba,
              index,
            ) <
            maskThreshold) {
          continue;
        }

        minX = math.min(
          minX,
          x,
        );

        minY = math.min(
          minY,
          y,
        );

        maxX = math.max(
          maxX,
          x,
        );

        maxY = math.max(
          maxY,
          y,
        );
      }
    }

    if (maxX < minX ||
        maxY < minY) {
      return null;
    }

    return ui.Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      (maxX + 1).toDouble(),
      (maxY + 1).toDouble(),
    );
  }

  // ===========================================================================
  // CROP
  // ===========================================================================

  ui.Rect _buildCropRect({
    required ui.Rect maskBounds,
    required int imageWidth,
    required int imageHeight,
  }) {
    final selectedWidth =
        maskBounds.width;

    final selectedHeight =
        maskBounds.height;

    final largestDimension =
        math.max(
      selectedWidth,
      selectedHeight,
    );

    final padding =
        math.max(
      largestDimension *
          cropPaddingFactor,
      minimumPaddingPixels
          .toDouble(),
    );

    var desiredSide =
        largestDimension +
        padding * 2;

    desiredSide =
        math.max(
      desiredSide,
      minimumCropSidePixels
          .toDouble(),
    );

    final maxSquareSide =
        math.min(
      imageWidth,
      imageHeight,
    ).toDouble();

    if (largestDimension <=
        maxSquareSide) {
      final side =
          math.min(
        desiredSide,
        maxSquareSide,
      );

      final center =
          maskBounds.center;

      var left =
          center.dx -
          side / 2;

      var top =
          center.dy -
          side / 2;

      left = left
          .clamp(
            0.0,
            imageWidth -
                side,
          )
          .toDouble();

      top = top
          .clamp(
            0.0,
            imageHeight -
                side,
          )
          .toDouble();

      return ui.Rect.fromLTWH(
        left,
        top,
        side,
        side,
      );
    }

    debugPrint(
      'Selection too large for local square crop. '
      'Using full image.',
    );

    return ui.Rect.fromLTWH(
      0,
      0,
      imageWidth.toDouble(),
      imageHeight.toDouble(),
    );
  }

  // ===========================================================================
  // BUILD TENSOR
  // ===========================================================================

  _TensorBuildResult _createInputTensor({
    required Uint8List imageRgba,
    required Uint8List removalRgba,
    Uint8List? protectionRgba,
  }) {
    const pixelCount =
        modelSize * modelSize;

    _validateRgbaBuffer(
      imageRgba,
      'image',
    );

    _validateRgbaBuffer(
      removalRgba,
      'removal mask',
    );

    if (protectionRgba != null) {
      _validateRgbaBuffer(
        protectionRgba,
        'protection mask',
      );
    }

    // =======================================================================
    // 1. RAW REMOVE MASK
    // =======================================================================

    final rawRemove =
        Float32List(
      pixelCount,
    );

    var rawRemoveCount = 0;

    for (var index = 0;
        index < pixelCount;
        index++) {
      final rgbaIndex =
          index * 4;

      if (_maskStrength(
            removalRgba,
            rgbaIndex,
          ) >=
          maskThreshold) {
        rawRemove[index] =
            1.0;

        rawRemoveCount++;
      }
    }

    if (rawRemoveCount == 0) {
      throw const InpaintingPreprocessorException(
        'The prepared removal mask is empty.',
      );
    }

    debugPrint(
      'Raw removal pixels: '
      '$rawRemoveCount',
    );

    // =======================================================================
    // 2. GUARANTEED CORE
    // =======================================================================

    final expandedCore =
        _dilateMask(
      rawRemove,
      width: modelSize,
      height: modelSize,
      radius:
          coreRemovalExpansionRadius,
    );

    final expandedCoreCount =
        _countMaskPixels(
      expandedCore,
    );

    debugPrint(
      'Guaranteed core pixels: '
      '$expandedCoreCount',
    );

    debugPrint(
      'Core cleanup added: '
      '${expandedCoreCount - rawRemoveCount}',
    );

    // =======================================================================
    // 3. OUTER CLEANUP
    // =======================================================================

    final expandedOuter =
        _dilateMask(
      rawRemove,
      width: modelSize,
      height: modelSize,
      radius:
          inputMaskDilationRadius,
    );

    final expandedOuterCount =
        _countMaskPixels(
      expandedOuter,
    );

    debugPrint(
      'Outer expanded pixels: '
      '$expandedOuterCount',
    );

    debugPrint(
      'Outer expansion added: '
      '${expandedOuterCount - rawRemoveCount}',
    );

    // =======================================================================
    // 4. NORMAL PROTECTION
    // =======================================================================

    var protectionMask =
        Float32List(
      pixelCount,
    );

    var protectedPixels = 0;

    if (protectionRgba != null) {
      final rawProtection =
          Float32List(
        pixelCount,
      );

      var rawProtectionCount = 0;

      for (var index = 0;
          index < pixelCount;
          index++) {
        final rgbaIndex =
            index * 4;

        if (_maskStrength(
              protectionRgba,
              rgbaIndex,
            ) >=
            maskThreshold) {
          rawProtection[index] =
              1.0;

          rawProtectionCount++;
        }
      }

      debugPrint(
        'Raw protected pixels: '
        '$rawProtectionCount',
      );

      if (rawProtectionCount > 0) {
        protectionMask =
            _dilateMask(
          rawProtection,
          width: modelSize,
          height: modelSize,
          radius:
              protectionSafetyRadius,
        );

        protectedPixels =
            _countMaskPixels(
          protectionMask,
        );
      }

      debugPrint(
        'Protected pixels before contact adaptation: '
        '$protectedPixels',
      );
    }

    // =======================================================================
    // 5. ADAPTIVE CONTACT PROTECTION
    // =======================================================================

    final adaptiveResult =
        _createAdaptiveProtectionMask(
      removeMask:
          expandedOuter,
      protectionMask:
          protectionMask,
      width: modelSize,
      height: modelSize,
    );

    protectionMask =
        adaptiveResult.mask;

    protectedPixels =
        _countMaskPixels(
      protectionMask,
    );

    debugPrint(
      'Protected pixels after contact adaptation: '
      '$protectedPixels',
    );

    debugPrint(
      'Contact-zone pixels: '
      '${adaptiveResult.contactZonePixels}',
    );

    debugPrint(
      'Protection released at contact: '
      '${adaptiveResult.releasedPixels}',
    );

    // =======================================================================
    // 6. FINAL MASK
    //
    // expandedCore
    //
    // OR
    //
    // expandedOuter AND NOT adaptiveProtection
    // =======================================================================

    final finalMask =
        Float32List(
      pixelCount,
    );

    var selectedPixels = 0;
    var blockedPixels = 0;
    var coreOverridePixels = 0;

    for (var index = 0;
        index < pixelCount;
        index++) {
      final corePixel =
          expandedCore[index] >=
          0.5;

      final outerPixel =
          expandedOuter[index] >=
          0.5;

      final protectedPixel =
          protectionMask[index] >=
          0.5;

      late final bool shouldRemove;

      if (corePixel) {
        shouldRemove = true;

        if (protectedPixel) {
          coreOverridePixels++;
        }
      } else {
        shouldRemove =
            outerPixel &&
            !protectedPixel;

        if (outerPixel &&
            protectedPixel) {
          blockedPixels++;
        }
      }

      finalMask[index] =
          shouldRemove
              ? 1.0
              : 0.0;

      if (shouldRemove) {
        selectedPixels++;
      }
    }

    debugPrint(
      'Protection blocked outer pixels: '
      '$blockedPixels',
    );

    debugPrint(
      'Core cleanup overriding protection: '
      '$coreOverridePixels',
    );

    debugPrint(
      'Final LaMa pixels: '
      '$selectedPixels',
    );

    // =======================================================================
    // 7. CONTACT RELEASE MASK
    //
    // IMPORTANT:
    //
    // adaptiveResult.releaseMask contains ONLY pixels that:
    //
    // - originally belonged to protection
    // - are inside a true Remove/Protect contact zone
    // - were deliberately released by adaptive erosion
    //
    // We additionally intersect it with expandedOuter.
    //
    // This guarantees the postprocessor only forces generated pixels
    // where LaMa actually has a reconstruction region.
    // =======================================================================

    final contactReleaseMask =
        Float32List(
      pixelCount,
    );

    var usableContactReleasePixels = 0;

    for (var index = 0;
        index < pixelCount;
        index++) {
      final released =
          adaptiveResult.releaseMask[
              index] >=
          0.5;

      final inRemovalRegion =
          expandedOuter[index] >=
          0.5;

      if (released &&
          inRemovalRegion) {
        contactReleaseMask[index] =
            1.0;

        usableContactReleasePixels++;
      }
    }

    debugPrint(
      'Usable contact-release pixels: '
      '$usableContactReleasePixels',
    );

    // =======================================================================
    // 8. BUILD LAMA [1,4,512,512]
    // =======================================================================

    final tensor =
        Float32List(
      totalChannels *
          pixelCount,
    );

    const redOffset = 0;

    const greenOffset =
        pixelCount;

    const blueOffset =
        pixelCount * 2;

    const maskOffset =
        pixelCount * 3;

    for (var index = 0;
        index < pixelCount;
        index++) {
      final rgbaIndex =
          index * 4;

      final mask =
          finalMask[index];

      final red =
          imageRgba[rgbaIndex] /
          255.0;

      final green =
          imageRgba[
                  rgbaIndex + 1] /
              255.0;

      final blue =
          imageRgba[
                  rgbaIndex + 2] /
              255.0;

      final keep =
          1.0 - mask;

      tensor[
        redOffset +
            index
      ] = red * keep;

      tensor[
        greenOffset +
            index
      ] = green * keep;

      tensor[
        blueOffset +
            index
      ] = blue * keep;

      tensor[
        maskOffset +
            index
      ] = mask;
    }

    return _TensorBuildResult(
      tensor: tensor,
      modelMask: finalMask,
      protectionMask:
          protectionMask,
      contactReleaseMask:
          contactReleaseMask,
      selectedPixels:
          selectedPixels,
      protectedPixels:
          protectedPixels,
      blockedPixels:
          blockedPixels,
      coreOverridePixels:
          coreOverridePixels,
      contactZonePixels:
          adaptiveResult.contactZonePixels,
      releasedProtectionPixels:
          usableContactReleasePixels,
    );
  }

  // ===========================================================================
  // ADAPTIVE CONTACT PROTECTION
  // ===========================================================================

  _AdaptiveProtectionResult
      _createAdaptiveProtectionMask({
    required Float32List removeMask,
    required Float32List protectionMask,
    required int width,
    required int height,
  }) {
    if (removeMask.length !=
            width * height ||
        protectionMask.length !=
            width * height) {
      throw const InpaintingPreprocessorException(
        'Invalid adaptive protection mask dimensions.',
      );
    }

    final emptyReleaseMask =
        Float32List(
      width * height,
    );

    if (contactProtectionErosionRadius <=
        0) {
      return _AdaptiveProtectionResult(
        mask:
            Float32List.fromList(
          protectionMask,
        ),
        releaseMask:
            emptyReleaseMask,
        contactZonePixels:
            0,
        releasedPixels:
            0,
      );
    }

    // =======================================================================
    // STEP 1
    // REMOVE x PROTECT overlap
    // =======================================================================

    final contactSeed =
        Float32List(
      protectionMask.length,
    );

    var seedPixels = 0;

    for (var index = 0;
        index < contactSeed.length;
        index++) {
      if (removeMask[index] >=
              0.5 &&
          protectionMask[index] >=
              0.5) {
        contactSeed[index] =
            1.0;

        seedPixels++;
      }
    }

    if (seedPixels == 0) {
      return _AdaptiveProtectionResult(
        mask:
            Float32List.fromList(
          protectionMask,
        ),
        releaseMask:
            emptyReleaseMask,
        contactZonePixels:
            0,
        releasedPixels:
            0,
      );
    }

    debugPrint(
      'Adaptive contact seed: '
      '$seedPixels pixels',
    );

    // =======================================================================
    // STEP 2
    // LOCAL CONTACT ZONE
    // =======================================================================

    final contactZone =
        _dilateMask(
      contactSeed,
      width: width,
      height: height,
      radius:
          contactZoneRadius,
    );

    final contactZonePixels =
        _countMaskPixels(
      contactZone,
    );

    // =======================================================================
    // STEP 3
    // ERODED PROTECTION
    // =======================================================================

    final erodedProtection =
        _erodeMask(
      protectionMask,
      width: width,
      height: height,
      radius:
          contactProtectionErosionRadius,
    );

    // =======================================================================
    // STEP 4
    // APPLY EROSION ONLY INSIDE CONTACT
    //
    // AND BUILD RELEASE MASK.
    // =======================================================================

    final adaptiveProtection =
        Float32List.fromList(
      protectionMask,
    );

    final releaseMask =
        Float32List(
      protectionMask.length,
    );

    var releasedPixels = 0;

    for (var index = 0;
        index < adaptiveProtection.length;
        index++) {
      if (contactZone[index] <
          0.5) {
        continue;
      }

      final originalProtected =
          protectionMask[index] >=
          0.5;

      final erodedProtected =
          erodedProtection[index] >=
          0.5;

      adaptiveProtection[index] =
          erodedProtected
              ? 1.0
              : 0.0;

      // ---------------------------------------------------------------
      // This is precisely the strip that used to be protected but was
      // deliberately released at an object/person contact boundary.
      //
      // We expose it to the postprocessor.
      // ---------------------------------------------------------------

      if (originalProtected &&
          !erodedProtected) {
        releaseMask[index] =
            1.0;

        releasedPixels++;
      }
    }

    return _AdaptiveProtectionResult(
      mask:
          adaptiveProtection,
      releaseMask:
          releaseMask,
      contactZonePixels:
          contactZonePixels,
      releasedPixels:
          releasedPixels,
    );
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

    if (source.length !=
        width * height) {
      throw const InpaintingPreprocessorException(
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

    // Horizontal maximum.

    for (var y = 0;
        y < height;
        y++) {
      final row =
          y * width;

      for (var x = 0;
          x < width;
          x++) {
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

    // Vertical maximum.

    for (var y = 0;
        y < height;
        y++) {
      for (var x = 0;
          x < width;
          x++) {
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

    if (source.length !=
        width * height) {
      throw const InpaintingPreprocessorException(
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

    for (var y = 0;
        y < height;
        y++) {
      final row =
          y * width;

      for (var x = 0;
          x < width;
          x++) {
        var keep = true;

        for (var sampleX =
                x - radius;
            sampleX <=
                x + radius;
            sampleX++) {
          if (sampleX < 0 ||
              sampleX >= width) {
            keep = false;
            break;
          }

          if (source[
                  row + sampleX] <
              0.5) {
            keep = false;
            break;
          }
        }

        horizontal[
          row + x
        ] = keep
            ? 1.0
            : 0.0;
      }
    }

    // Vertical minimum.

    for (var y = 0;
        y < height;
        y++) {
      for (var x = 0;
          x < width;
          x++) {
        var keep = true;

        for (var sampleY =
                y - radius;
            sampleY <=
                y + radius;
            sampleY++) {
          if (sampleY < 0 ||
              sampleY >= height) {
            keep = false;
            break;
          }

          if (horizontal[
                  sampleY *
                          width +
                      x] <
              0.5) {
            keep = false;
            break;
          }
        }

        output[
          y * width + x
        ] = keep
            ? 1.0
            : 0.0;
      }
    }

    return output;
  }

  // ===========================================================================
  // COUNT
  // ===========================================================================

  int _countMaskPixels(
    Float32List mask,
  ) {
    var count = 0;

    for (final value in mask) {
      if (value >= 0.5) {
        count++;
      }
    }

    return count;
  }

  // ===========================================================================
  // MASK STRENGTH
  // ===========================================================================

  double _maskStrength(
    Uint8List rgba,
    int index,
  ) {
    final red =
        rgba[index] /
        255.0;

    final green =
        rgba[index + 1] /
        255.0;

    final blue =
        rgba[index + 2] /
        255.0;

    final alpha =
        rgba[index + 3] /
        255.0;

    final luminance =
        (red +
            green +
            blue) /
        3.0;

    return luminance *
        alpha;
  }

  // ===========================================================================
  // IMAGE UTILITIES
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

    canvas.drawRect(
      destinationRect,
      ui.Paint()
        ..color =
            const ui.Color(
          0x00000000,
        ),
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

  Future<Uint8List> _readRgba(
    ui.Image image,
  ) async {
    final byteData =
        await image.toByteData(
      format:
          ui.ImageByteFormat.rawRgba,
    );

    if (byteData == null) {
      throw const InpaintingPreprocessorException(
        'Could not read image pixel data.',
      );
    }

    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  void _validateRgbaBuffer(
    Uint8List buffer,
    String name,
  ) {
    const expected =
        modelSize *
        modelSize *
        4;

    if (buffer.length !=
        expected) {
      throw InpaintingPreprocessorException(
        'Unexpected $name buffer size: '
        '${buffer.length}. '
        'Expected $expected.',
      );
    }
  }

  String _formatRect(
    ui.Rect rect,
  ) {
    return 'x=${rect.left.toStringAsFixed(1)}, '
        'y=${rect.top.toStringAsFixed(1)}, '
        'w=${rect.width.toStringAsFixed(1)}, '
        'h=${rect.height.toStringAsFixed(1)}';
  }
}

// =============================================================================
// PREPARED INPUT
// =============================================================================

class PreparedInpaintingInput {
  const PreparedInpaintingInput({
    required this.tensor,
    required this.modelMask,
    required this.protectionMask,
    required this.contactReleaseMask,
    required this.cropRect,
    required this.originalWidth,
    required this.originalHeight,
    required this.modelWidth,
    required this.modelHeight,
    required this.selectedPixelCount,
    required this.protectedPixelCount,
    required this.contactReleasedPixelCount,
    required this.blockedPixelCount,
    required this.coreOverridePixelCount,
  });

  final Float32List tensor;

  /// Final mask sent to LaMa.
  final Float32List modelMask;

  /// Pixels that remain strictly protected.
  final Float32List protectionMask;

  /// NEW:
  ///
  /// Pixels originally belonging to Protect but intentionally released
  /// specifically at a Remove/Protect contact boundary.
  ///
  /// The postprocessor should force these pixels toward the GENERATED
  /// result instead of blending with the original subject colour.
  final Float32List contactReleaseMask;

  final ui.Rect cropRect;

  final int originalWidth;
  final int originalHeight;

  final int modelWidth;
  final int modelHeight;

  final int selectedPixelCount;
  final int protectedPixelCount;

  final int contactReleasedPixelCount;

  final int blockedPixelCount;
  final int coreOverridePixelCount;

  List<int> get tensorShape =>
      const [
        1,
        4,
        InpaintingPreprocessor.modelSize,
        InpaintingPreprocessor.modelSize,
      ];

  bool get hasProtection =>
      protectedPixelCount > 0;

  bool get hasContactRelease =>
      contactReleasedPixelCount >
      0;

  double get selectedFraction {
    final total =
        modelWidth *
        modelHeight;

    if (total <= 0) {
      return 0;
    }

    return selectedPixelCount /
        total;
  }

  double get protectedFraction {
    final total =
        modelWidth *
        modelHeight;

    if (total <= 0) {
      return 0;
    }

    return protectedPixelCount /
        total;
  }

  double get contactReleaseFraction {
    final total =
        modelWidth *
        modelHeight;

    if (total <= 0) {
      return 0;
    }

    return contactReleasedPixelCount /
        total;
  }
}

// =============================================================================
// ADAPTIVE PROTECTION RESULT
// =============================================================================

class _AdaptiveProtectionResult {
  const _AdaptiveProtectionResult({
    required this.mask,
    required this.releaseMask,
    required this.contactZonePixels,
    required this.releasedPixels,
  });

  final Float32List mask;

  /// Exact pixels removed from Protect by adaptive erosion.
  final Float32List releaseMask;

  final int contactZonePixels;
  final int releasedPixels;
}

// =============================================================================
// INTERNAL RESULT
// =============================================================================

class _TensorBuildResult {
  const _TensorBuildResult({
    required this.tensor,
    required this.modelMask,
    required this.protectionMask,
    required this.contactReleaseMask,
    required this.selectedPixels,
    required this.protectedPixels,
    required this.blockedPixels,
    required this.coreOverridePixels,
    required this.contactZonePixels,
    required this.releasedProtectionPixels,
  });

  final Float32List tensor;

  final Float32List modelMask;
  final Float32List protectionMask;

  final Float32List contactReleaseMask;

  final int selectedPixels;
  final int protectedPixels;

  final int blockedPixels;
  final int coreOverridePixels;

  final int contactZonePixels;
  final int releasedProtectionPixels;
}

// =============================================================================
// EXCEPTION
// =============================================================================

class InpaintingPreprocessorException
    implements Exception {
  const InpaintingPreprocessorException(
    this.message,
  );

  final String message;

  @override
  String toString() =>
      message;
}