import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:neurolens/core/ai/onnx_model_service.dart';

class LocalSegmentationService {
  LocalSegmentationService();

  static const String _encoderAsset =
      'assets/models/mobile_sam_image_encoder.onnx';

  static const String _decoderAsset =
      'assets/models/sam_mask_decoder_single.onnx';

  static const int _encoderImageSize = 1024;
  static const int _lowResMaskSize = 256;

  /// Extra protection applied specifically to Protect-mode masks.
  ///
  /// This is deliberately small because the inpainting
  /// preprocessor adds another strict protection safety margin.
  static const int _protectExpansionRadius = 1;

  OrtSession? _encoderSession;
  OrtSession? _decoderSession;

  _CachedImageEmbedding? _cachedEmbedding;
  SegmentationResult? _lastResult;

  bool get isInitialized =>
      _encoderSession != null &&
      _decoderSession != null;

  bool get hasCachedEmbedding =>
      _cachedEmbedding != null;

  SegmentationResult? get lastResult =>
      _lastResult;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    _encoderSession =
        await OnnxModelService.instance.getSession(
      _encoderAsset,
    );

    _decoderSession =
        await OnnxModelService.instance.getSession(
      _decoderAsset,
    );
  }

  Future<String> debugInitialize() async {
    await initialize();

    return isInitialized
        ? 'MobileSAM encoder and decoder loaded successfully.'
        : 'MobileSAM failed to initialize.';
  }

  Future<void> debugPrintModelInfo() async {
    await initialize();

    final encoder = _encoderSession;
    final decoder = _decoderSession;

    if (encoder == null ||
        decoder == null) {
      debugPrint(
        'MobileSAM sessions are not initialized.',
      );

      return;
    }

    debugPrint(
      '===== MobileSAM Encoder =====',
    );

    debugPrint(
      'Encoder inputs: ${encoder.inputNames}',
    );

    debugPrint(
      'Encoder outputs: ${encoder.outputNames}',
    );

    final encoderInputInfo =
        await encoder.getInputInfo();

    final encoderOutputInfo =
        await encoder.getOutputInfo();

    debugPrint(
      'Encoder input info: $encoderInputInfo',
    );

    debugPrint(
      'Encoder output info: $encoderOutputInfo',
    );

    debugPrint(
      '===== MobileSAM Decoder =====',
    );

    debugPrint(
      'Decoder inputs: ${decoder.inputNames}',
    );

    debugPrint(
      'Decoder outputs: ${decoder.outputNames}',
    );

    final decoderInputInfo =
        await decoder.getInputInfo();

    final decoderOutputInfo =
        await decoder.getOutputInfo();

    debugPrint(
      'Decoder input info: $decoderInputInfo',
    );

    debugPrint(
      'Decoder output info: $decoderOutputInfo',
    );
  }

  // ===========================================================================
  // IMAGE EMBEDDING
  // ===========================================================================

  Future<void> prepareImage(
    Uint8List imageBytes,
  ) async {
    await initialize();

    if (_cachedEmbedding != null) {
      debugPrint(
        'MobileSAM embedding already cached.',
      );

      return;
    }

    final encoder = _encoderSession;

    if (encoder == null) {
      throw StateError(
        'MobileSAM encoder is not initialized.',
      );
    }

    debugPrint(
      'Preparing MobileSAM encoder input...',
    );

    final prepared =
        await _prepareEncoderInput(
      imageBytes,
    );

    debugPrint(
      'Original image: '
      '${prepared.originalWidth}x'
      '${prepared.originalHeight}',
    );

    debugPrint(
      'Encoder image: '
      '${prepared.width}x'
      '${prepared.height}',
    );

    debugPrint(
      'Encoder RGB values: '
      '${prepared.rgb.length}',
    );

    OrtValue? inputTensor;
    Map<String, OrtValue>? outputs;

    try {
      inputTensor =
          await OrtValue.fromList(
        prepared.rgb,
        [
          prepared.height,
          prepared.width,
          3,
        ],
      );

      outputs =
          await encoder.run(
        {
          'input_image': inputTensor,
        },
      );

      final embeddings =
          outputs[
              'image_embeddings'];

      if (embeddings == null) {
        throw StateError(
          'MobileSAM encoder did not return '
          'image_embeddings.',
        );
      }

      debugPrint(
        'MobileSAM encoder inference successful.',
      );

      debugPrint(
        'Embedding shape: '
        '${embeddings.shape}',
      );

      final flattened =
          await embeddings
              .asFlattenedList();

      final embeddingValues =
          Float32List(
        flattened.length,
      );

      for (
        var index = 0;
        index < flattened.length;
        index++
      ) {
        embeddingValues[index] =
            (flattened[index] as num)
                .toDouble();
      }

      const expectedLength =
          1 * 256 * 64 * 64;

      if (embeddingValues.length !=
          expectedLength) {
        throw StateError(
          'Unexpected MobileSAM embedding size: '
          '${embeddingValues.length}.',
        );
      }

      _cachedEmbedding =
          _CachedImageEmbedding(
        values:
            embeddingValues,
        originalWidth:
            prepared.originalWidth,
        originalHeight:
            prepared.originalHeight,
        encoderWidth:
            prepared.width,
        encoderHeight:
            prepared.height,
      );

      debugPrint(
        'Embedding values: '
        '${embeddingValues.length}',
      );

      debugPrint(
        'MobileSAM embedding cached successfully.',
      );
    } finally {
      await inputTensor?.dispose();

      if (outputs != null) {
        for (final output
            in outputs.values) {
          await output.dispose();
        }
      }
    }
  }

  Future<void> debugRunEncoder(
    Uint8List imageBytes,
  ) {
    return prepareImage(
      imageBytes,
    );
  }

  Future<_PreparedEncoderInput>
      _prepareEncoderInput(
    Uint8List imageBytes,
  ) async {
    final originalCodec =
        await instantiateImageCodec(
      imageBytes,
    );

    final originalFrame =
        await originalCodec
            .getNextFrame();

    final originalImage =
        originalFrame.image;

    final originalWidth =
        originalImage.width;

    final originalHeight =
        originalImage.height;

    if (originalWidth <= 0 ||
        originalHeight <= 0) {
      originalImage.dispose();
      originalCodec.dispose();

      throw StateError(
        'The source image has invalid dimensions.',
      );
    }

    final longestEdge =
        math.max(
      originalWidth,
      originalHeight,
    );

    final scale =
        _encoderImageSize /
        longestEdge;

    final targetWidth =
        math.max(
      1,
      (originalWidth * scale)
          .round(),
    );

    final targetHeight =
        math.max(
      1,
      (originalHeight * scale)
          .round(),
    );

    originalImage.dispose();
    originalCodec.dispose();

    final resizedCodec =
        await instantiateImageCodec(
      imageBytes,
      targetWidth:
          targetWidth,
      targetHeight:
          targetHeight,
    );

    final resizedFrame =
        await resizedCodec
            .getNextFrame();

    final resizedImage =
        resizedFrame.image;

    try {
      final byteData =
          await resizedImage
              .toByteData(
        format:
            ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        throw StateError(
          'Could not read image pixel data.',
        );
      }

      final rgba =
          byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      final rgb =
          Float32List(
        targetWidth *
            targetHeight *
            3,
      );

      var rgbIndex = 0;

      for (
        var rgbaIndex = 0;
        rgbaIndex < rgba.length;
        rgbaIndex += 4
      ) {
        rgb[rgbIndex++] =
            rgba[rgbaIndex]
                .toDouble();

        rgb[rgbIndex++] =
            rgba[
              rgbaIndex + 1
            ].toDouble();

        rgb[rgbIndex++] =
            rgba[
              rgbaIndex + 2
            ].toDouble();
      }

      return _PreparedEncoderInput(
        rgb: rgb,
        width:
            targetWidth,
        height:
            targetHeight,
        originalWidth:
            originalWidth,
        originalHeight:
            originalHeight,
      );
    } finally {
      resizedImage.dispose();
      resizedCodec.dispose();
    }
  }

  // ===========================================================================
  // SIMPLE API
  // ===========================================================================

  Future<Uint8List?> segmentFromPoint({
    required Uint8List imageBytes,
    required Offset imagePoint,
    Offset? negativePoint,
  }) async {
    final result =
        await segmentDetailedFromPoint(
      imageBytes:
          imageBytes,
      imagePoint:
          imagePoint,
      negativePoint:
          negativePoint,
    );

    return result.maskBytes;
  }

  // ===========================================================================
  // NORMAL SMART SELECT
  // ===========================================================================

  Future<SegmentationResult>
      segmentDetailedFromPoint({
    required Uint8List imageBytes,
    required Offset imagePoint,
    Offset? negativePoint,
  }) {
    return _runPointSegmentation(
      imageBytes:
          imageBytes,
      imagePoint:
          imagePoint,
      negativePoint:
          negativePoint,
      protectMode:
          false,
    );
  }

  // ===========================================================================
  // MOBILE SAM PROTECT
  // ===========================================================================

  /// MobileSAM-based protected-subject segmentation.
  ///
  /// Protect mode performs extra post-processing:
  ///
  /// 1. MobileSAM positive-point segmentation
  /// 2. Keep connected object belonging to tapped point
  /// 3. Fill holes inside that subject
  /// 4. Slightly expand the protection mask
  ///
  /// This intentionally favours PRESERVATION over removal.
  Future<SegmentationResult>
      segmentProtectedSubject({
    required Uint8List imageBytes,
    required Offset imagePoint,
  }) {
    return _runPointSegmentation(
      imageBytes:
          imageBytes,
      imagePoint:
          imagePoint,
      protectMode:
          true,
    );
  }

  // ===========================================================================
  // SHARED MOBILE SAM DECODER
  // ===========================================================================

  Future<SegmentationResult>
      _runPointSegmentation({
    required Uint8List imageBytes,
    required Offset imagePoint,
    Offset? negativePoint,
    required bool protectMode,
  }) async {
    await prepareImage(
      imageBytes,
    );

    final cached =
        _cachedEmbedding;

    final decoder =
        _decoderSession;

    if (cached == null) {
      throw StateError(
        'MobileSAM image embedding is unavailable.',
      );
    }

    if (decoder == null) {
      throw StateError(
        'MobileSAM decoder is not initialized.',
      );
    }

    final scaledPositiveX =
        imagePoint.dx *
        cached.encoderWidth /
        cached.originalWidth;

    final scaledPositiveY =
        imagePoint.dy *
        cached.encoderHeight /
        cached.originalHeight;

    double secondX = 0;
    double secondY = 0;
    double secondLabel = -1;

    if (negativePoint != null) {
      secondX =
          negativePoint.dx *
          cached.encoderWidth /
          cached.originalWidth;

      secondY =
          negativePoint.dy *
          cached.encoderHeight /
          cached.originalHeight;

      // SAM:
      // 1 = foreground
      // 0 = background
      // -1 = padding
      secondLabel = 0;
    }

    debugPrint(
      protectMode
          ? 'Running MobileSAM PROTECT decoder...'
          : 'Running MobileSAM decoder...',
    );

    debugPrint(
      'Positive point: '
      '${imagePoint.dx.toStringAsFixed(1)}, '
      '${imagePoint.dy.toStringAsFixed(1)}',
    );

    debugPrint(
      'Scaled positive: '
      '${scaledPositiveX.toStringAsFixed(1)}, '
      '${scaledPositiveY.toStringAsFixed(1)}',
    );

    if (negativePoint != null) {
      debugPrint(
        'Negative point: '
        '${negativePoint.dx.toStringAsFixed(1)}, '
        '${negativePoint.dy.toStringAsFixed(1)}',
      );
    }

    OrtValue? embeddingTensor;
    OrtValue? pointCoordsTensor;
    OrtValue? pointLabelsTensor;
    OrtValue? maskInputTensor;
    OrtValue? hasMaskInputTensor;
    OrtValue? originalSizeTensor;

    Map<String, OrtValue>? outputs;

    try {
      embeddingTensor =
          await OrtValue.fromList(
        cached.values,
        const [
          1,
          256,
          64,
          64,
        ],
      );

      pointCoordsTensor =
          await OrtValue.fromList(
        Float32List.fromList(
          [
            scaledPositiveX,
            scaledPositiveY,
            secondX,
            secondY,
          ],
        ),
        const [
          1,
          2,
          2,
        ],
      );

      pointLabelsTensor =
          await OrtValue.fromList(
        Float32List.fromList(
          [
            1,
            secondLabel,
          ],
        ),
        const [
          1,
          2,
        ],
      );

      maskInputTensor =
          await OrtValue.fromList(
        Float32List(
          _lowResMaskSize *
              _lowResMaskSize,
        ),
        const [
          1,
          1,
          _lowResMaskSize,
          _lowResMaskSize,
        ],
      );

      hasMaskInputTensor =
          await OrtValue.fromList(
        Float32List.fromList(
          [
            0,
          ],
        ),
        const [
          1,
        ],
      );

      originalSizeTensor =
          await OrtValue.fromList(
        Float32List.fromList(
          [
            cached.originalHeight
                .toDouble(),
            cached.originalWidth
                .toDouble(),
          ],
        ),
        const [
          2,
        ],
      );

      outputs =
          await decoder.run(
        {
          'image_embeddings':
              embeddingTensor,
          'point_coords':
              pointCoordsTensor,
          'point_labels':
              pointLabelsTensor,
          'mask_input':
              maskInputTensor,
          'has_mask_input':
              hasMaskInputTensor,
          'orig_im_size':
              originalSizeTensor,
        },
      );

      final fullMask =
          outputs[
              'masks'];

      final lowResMask =
          outputs[
              'low_res_masks'];

      final iou =
          outputs[
              'iou_predictions'];

      if (lowResMask == null) {
        throw StateError(
          'MobileSAM decoder returned no '
          'low-resolution mask.',
        );
      }

      debugPrint(
        'MobileSAM decoder inference successful.',
      );

      debugPrint(
        'Full mask shape: '
        '${fullMask?.shape}',
      );

      debugPrint(
        'Low-res mask shape: '
        '${lowResMask.shape}',
      );

      final values =
          await lowResMask
              .asFlattenedList();

      double? confidence;

      if (iou != null) {
        final iouValues =
            await iou
                .asFlattenedList();

        debugPrint(
          'IoU prediction: '
          '$iouValues',
        );

        if (iouValues.isNotEmpty) {
          confidence =
              (iouValues.first as num)
                  .toDouble();
        }
      }

      final validMaskWidth =
          math.max(
        1,
        (
          cached.encoderWidth /
              _encoderImageSize *
              _lowResMaskSize
        ).round(),
      );

      final validMaskHeight =
          math.max(
        1,
        (
          cached.encoderHeight /
              _encoderImageSize *
              _lowResMaskSize
        ).round(),
      );

      var binaryMask =
          _createBinaryMask(
        values,
        sourceWidth:
            _lowResMaskSize,
        sourceHeight:
            _lowResMaskSize,
        outputWidth:
            validMaskWidth,
        outputHeight:
            validMaskHeight,
      );

      // =====================================================================
      // PROTECT-SPECIFIC REFINEMENT
      // =====================================================================

      if (protectMode) {
        final tapX =
            (
              imagePoint.dx /
                  cached.originalWidth *
                  validMaskWidth
            )
                .round()
                .clamp(
                  0,
                  validMaskWidth - 1,
                );

        final tapY =
            (
              imagePoint.dy /
                  cached.originalHeight *
                  validMaskHeight
            )
                .round()
                .clamp(
                  0,
                  validMaskHeight - 1,
                );

        debugPrint(
          'Protect mask tap: '
          '$tapX,$tapY',
        );

        // ---------------------------------------------------------------
        // 1. Keep the component that corresponds to the user's tap.
        //
        // If SAM accidentally includes an unrelated disconnected object,
        // it will not be protected.
        // ---------------------------------------------------------------

        binaryMask =
            _keepTappedConnectedComponent(
          binaryMask,
          width:
              validMaskWidth,
          height:
              validMaskHeight,
          tapX:
              tapX,
          tapY:
              tapY,
        );

        // ---------------------------------------------------------------
        // 2. Fill enclosed holes.
        //
        // For preservation we don't want small holes inside a shirt,
        // arm, face, etc. to remain editable by LaMa.
        // ---------------------------------------------------------------

        binaryMask =
            _fillMaskHoles(
          binaryMask,
          width:
              validMaskWidth,
          height:
              validMaskHeight,
        );

        // ---------------------------------------------------------------
        // 3. Add a tiny local safety border.
        //
        // Preprocessor will add another protectionSafetyRadius later.
        // ---------------------------------------------------------------

        binaryMask =
            _dilateBinaryMask(
          binaryMask,
          width:
              validMaskWidth,
          height:
              validMaskHeight,
          radius:
              _protectExpansionRadius,
        );

        debugPrint(
          'MobileSAM Protect refinement complete.',
        );
      }

      final selectedCount =
          _countSelectedPixels(
        binaryMask,
      );

      if (selectedCount == 0) {
        throw StateError(
          protectMode
              ? 'MobileSAM returned an empty protection mask.'
              : 'MobileSAM returned an empty object mask.',
        );
      }

      debugPrint(
        protectMode
            ? 'Final protected pixels: '
                '$selectedCount / '
                '${validMaskWidth * validMaskHeight}'
            : 'Selected mask pixels: '
                '$selectedCount / '
                '${validMaskWidth * validMaskHeight}',
      );

      final maskBytes =
          await _encodeBinaryMaskPng(
        binaryMask,
        width:
            validMaskWidth,
        height:
            validMaskHeight,
      );

      final outlineBytes =
          await _createOutlinePng(
        binaryMask,
        width:
            validMaskWidth,
        height:
            validMaskHeight,
      );

      final result =
          SegmentationResult(
        maskBytes:
            maskBytes,
        outlineBytes:
            outlineBytes,
        maskWidth:
            validMaskWidth,
        maskHeight:
            validMaskHeight,
        confidence:
            confidence,
        positivePoint:
            imagePoint,
        negativePoint:
            negativePoint,
        isProtection:
            protectMode,
      );

      _lastResult =
          result;

      return result;
    } finally {
      await embeddingTensor?.dispose();
      await pointCoordsTensor?.dispose();
      await pointLabelsTensor?.dispose();
      await maskInputTensor?.dispose();
      await hasMaskInputTensor?.dispose();
      await originalSizeTensor?.dispose();

      if (outputs != null) {
        for (final output
            in outputs.values) {
          await output.dispose();
        }
      }
    }
  }

  // ===========================================================================
  // BINARY MASK
  // ===========================================================================

  Uint8List _createBinaryMask(
    List<dynamic> values, {
    required int sourceWidth,
    required int sourceHeight,
    required int outputWidth,
    required int outputHeight,
  }) {
    final expectedLength =
        sourceWidth *
        sourceHeight;

    if (values.length !=
        expectedLength) {
      throw StateError(
        'Unexpected MobileSAM mask size: '
        '${values.length}. Expected '
        '$expectedLength.',
      );
    }

    if (outputWidth >
            sourceWidth ||
        outputHeight >
            sourceHeight) {
      throw StateError(
        'Invalid cropped mask dimensions.',
      );
    }

    final binary =
        Uint8List(
      outputWidth *
          outputHeight,
    );

    for (
      var y = 0;
      y < outputHeight;
      y++
    ) {
      for (
        var x = 0;
        x < outputWidth;
        x++
      ) {
        final sourceIndex =
            y *
                sourceWidth +
            x;

        final logit =
            (values[sourceIndex]
                    as num)
                .toDouble();

        if (logit > 0) {
          binary[
            y *
                    outputWidth +
                x
          ] = 1;
        }
      }
    }

    return binary;
  }

  // ===========================================================================
  // PROTECT: CONNECTED COMPONENT
  // ===========================================================================

  Uint8List _keepTappedConnectedComponent(
    Uint8List mask, {
    required int width,
    required int height,
    required int tapX,
    required int tapY,
  }) {
    if (mask.length !=
        width * height) {
      throw StateError(
        'Invalid mask dimensions.',
      );
    }

    int indexOf(
      int x,
      int y,
    ) {
      return y * width + x;
    }

    bool selected(
      int x,
      int y,
    ) {
      if (x < 0 ||
          y < 0 ||
          x >= width ||
          y >= height) {
        return false;
      }

      return mask[
            indexOf(
              x,
              y,
            )
          ] !=
          0;
    }

    // -----------------------------------------------------------------------
    // The exact tap can occasionally fall a few pixels outside SAM's mask
    // because the decoder mask is low-resolution.
    //
    // Search around it for the nearest selected pixel.
    // -----------------------------------------------------------------------

    math.Point<int>? start;

    if (selected(
      tapX,
      tapY,
    )) {
      start =
          math.Point<int>(
        tapX,
        tapY,
      );
    } else {
      const searchRadius = 12;

      var bestDistance =
          double.infinity;

      for (
        var y = math.max(
          0,
          tapY - searchRadius,
        );
        y <=
            math.min(
              height - 1,
              tapY + searchRadius,
            );
        y++
      ) {
        for (
          var x = math.max(
            0,
            tapX - searchRadius,
          );
          x <=
              math.min(
                width - 1,
                tapX + searchRadius,
              );
          x++
        ) {
          if (!selected(
            x,
            y,
          )) {
            continue;
          }

          final dx =
              x - tapX;

          final dy =
              y - tapY;

          final distance =
              dx * dx +
              dy * dy;

          if (distance <
              bestDistance) {
            bestDistance =
                distance.toDouble();

            start =
                math.Point<int>(
              x,
              y,
            );
          }
        }
      }
    }

    // If SAM gave a valid mask but tap lookup failed,
    // retain the original mask rather than returning nothing.
    if (start == null) {
      debugPrint(
        'Protect component lookup missed tap. '
        'Keeping raw MobileSAM mask.',
      );

      return Uint8List.fromList(
        mask,
      );
    }

    final output =
        Uint8List(
      mask.length,
    );

    final visited =
        Uint8List(
      mask.length,
    );

    final queue =
        Queue<math.Point<int>>();

    queue.add(
      start,
    );

    visited[
      indexOf(
        start.x,
        start.y,
      )
    ] = 1;

    const neighbours =
        <math.Point<int>>[
      math.Point<int>(
        -1,
        0,
      ),
      math.Point<int>(
        1,
        0,
      ),
      math.Point<int>(
        0,
        -1,
      ),
      math.Point<int>(
        0,
        1,
      ),
      math.Point<int>(
        -1,
        -1,
      ),
      math.Point<int>(
        1,
        -1,
      ),
      math.Point<int>(
        -1,
        1,
      ),
      math.Point<int>(
        1,
        1,
      ),
    ];

    while (queue.isNotEmpty) {
      final point =
          queue.removeFirst();

      final index =
          indexOf(
        point.x,
        point.y,
      );

      output[index] =
          1;

      for (final delta
          in neighbours) {
        final nextX =
            point.x +
            delta.x;

        final nextY =
            point.y +
            delta.y;

        if (nextX < 0 ||
            nextY < 0 ||
            nextX >= width ||
            nextY >= height) {
          continue;
        }

        final nextIndex =
            indexOf(
          nextX,
          nextY,
        );

        if (visited[nextIndex] !=
            0) {
          continue;
        }

        if (mask[nextIndex] ==
            0) {
          continue;
        }

        visited[nextIndex] =
            1;

        queue.add(
          math.Point<int>(
            nextX,
            nextY,
          ),
        );
      }
    }

    debugPrint(
      'Protect component: '
      '${_countSelectedPixels(output)} pixels',
    );

    return output;
  }

  // ===========================================================================
  // PROTECT: FILL HOLES
  // ===========================================================================

  Uint8List _fillMaskHoles(
    Uint8List mask, {
    required int width,
    required int height,
  }) {
    final outside =
        Uint8List(
      mask.length,
    );

    final queue =
        Queue<math.Point<int>>();

    int indexOf(
      int x,
      int y,
    ) {
      return y * width + x;
    }

    void addBackground(
      int x,
      int y,
    ) {
      final index =
          indexOf(
        x,
        y,
      );

      if (mask[index] != 0 ||
          outside[index] != 0) {
        return;
      }

      outside[index] =
          1;

      queue.add(
        math.Point<int>(
          x,
          y,
        ),
      );
    }

    // Seed image boundary.

    for (var x = 0;
        x < width;
        x++) {
      addBackground(
        x,
        0,
      );

      addBackground(
        x,
        height - 1,
      );
    }

    for (var y = 0;
        y < height;
        y++) {
      addBackground(
        0,
        y,
      );

      addBackground(
        width - 1,
        y,
      );
    }

    const directions =
        <math.Point<int>>[
      math.Point<int>(
        -1,
        0,
      ),
      math.Point<int>(
        1,
        0,
      ),
      math.Point<int>(
        0,
        -1,
      ),
      math.Point<int>(
        0,
        1,
      ),
    ];

    while (queue.isNotEmpty) {
      final point =
          queue.removeFirst();

      for (final delta
          in directions) {
        final x =
            point.x +
            delta.x;

        final y =
            point.y +
            delta.y;

        if (x < 0 ||
            y < 0 ||
            x >= width ||
            y >= height) {
          continue;
        }

        addBackground(
          x,
          y,
        );
      }
    }

    final result =
        Uint8List.fromList(
      mask,
    );

    var holesFilled = 0;

    for (
      var index = 0;
      index < result.length;
      index++
    ) {
      if (mask[index] == 0 &&
          outside[index] == 0) {
        result[index] = 1;
        holesFilled++;
      }
    }

    debugPrint(
      'Protect holes filled: '
      '$holesFilled pixels',
    );

    return result;
  }

  // ===========================================================================
  // PROTECT: SMALL DILATION
  // ===========================================================================

  Uint8List _dilateBinaryMask(
    Uint8List source, {
    required int width,
    required int height,
    required int radius,
  }) {
    if (radius <= 0) {
      return Uint8List.fromList(
        source,
      );
    }

    final horizontal =
        Uint8List(
      source.length,
    );

    final output =
        Uint8List(
      source.length,
    );

    // Horizontal maximum.

    for (
      var y = 0;
      y < height;
      y++
    ) {
      final row =
          y * width;

      for (
        var x = 0;
        x < width;
        x++
      ) {
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

        for (
          var sx = minX;
          sx <= maxX;
          sx++
        ) {
          if (source[
                  row +
                      sx] !=
              0) {
            horizontal[
              row + x
            ] = 1;

            break;
          }
        }
      }
    }

    // Vertical maximum.

    for (
      var y = 0;
      y < height;
      y++
    ) {
      for (
        var x = 0;
        x < width;
        x++
      ) {
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

        for (
          var sy = minY;
          sy <= maxY;
          sy++
        ) {
          if (horizontal[
                  sy *
                          width +
                      x] !=
              0) {
            output[
              y *
                      width +
                  x
            ] = 1;

            break;
          }
        }
      }
    }

    return output;
  }

  int _countSelectedPixels(
    Uint8List mask,
  ) {
    var count = 0;

    for (final value
        in mask) {
      if (value != 0) {
        count++;
      }
    }

    return count;
  }

  // ===========================================================================
  // MASK PNG
  // ===========================================================================

  Future<Uint8List>
      _encodeBinaryMaskPng(
    Uint8List binaryMask, {
    required int width,
    required int height,
  }) async {
    final rgba =
        Uint8List(
      width *
          height *
          4,
    );

    for (
      var index = 0;
      index <
          binaryMask.length;
      index++
    ) {
      if (binaryMask[index] ==
          0) {
        continue;
      }

      final rgbaIndex =
          index * 4;

      rgba[rgbaIndex] = 255;
      rgba[rgbaIndex + 1] = 255;
      rgba[rgbaIndex + 2] = 255;
      rgba[rgbaIndex + 3] = 255;
    }

    return _encodeRgbaPng(
      rgba,
      width:
          width,
      height:
          height,
    );
  }

  // ===========================================================================
  // OUTLINE
  // ===========================================================================

  Future<Uint8List> _createOutlinePng(
    Uint8List mask, {
    required int width,
    required int height,
  }) async {
    final rgba =
        Uint8List(
      width *
          height *
          4,
    );

    bool selected(
      int x,
      int y,
    ) {
      if (x < 0 ||
          y < 0 ||
          x >= width ||
          y >= height) {
        return false;
      }

      return mask[
            y * width + x
          ] !=
          0;
    }

    var boundaryPixels = 0;

    for (
      var y = 0;
      y < height;
      y++
    ) {
      for (
        var x = 0;
        x < width;
        x++
      ) {
        if (!selected(
          x,
          y,
        )) {
          continue;
        }

        final boundary =
            !selected(
              x - 1,
              y,
            ) ||
            !selected(
              x + 1,
              y,
            ) ||
            !selected(
              x,
              y - 1,
            ) ||
            !selected(
              x,
              y + 1,
            );

        if (!boundary) {
          continue;
        }

        final rgbaIndex =
            (
              y *
                      width +
                  x
            ) *
            4;

        rgba[rgbaIndex] = 255;
        rgba[rgbaIndex + 1] = 255;
        rgba[rgbaIndex + 2] = 255;
        rgba[rgbaIndex + 3] = 255;

        boundaryPixels++;
      }
    }

    debugPrint(
      'Selection boundary pixels: '
      '$boundaryPixels',
    );

    if (boundaryPixels == 0) {
      throw StateError(
        'Could not create selection outline.',
      );
    }

    return _encodeRgbaPng(
      rgba,
      width:
          width,
      height:
          height,
    );
  }

  // ===========================================================================
  // PNG ENCODER
  // ===========================================================================

  Future<Uint8List> _encodeRgbaPng(
    Uint8List rgba, {
    required int width,
    required int height,
  }) async {
    final buffer =
        await ImmutableBuffer.fromUint8List(
      rgba,
    );

    final descriptor =
        ImageDescriptor.raw(
      buffer,
      width:
          width,
      height:
          height,
      pixelFormat:
          PixelFormat.rgba8888,
    );

    Codec? codec;
    Image? image;

    try {
      codec =
          await descriptor
              .instantiateCodec();

      final frame =
          await codec
              .getNextFrame();

      image =
          frame.image;

      final byteData =
          await image.toByteData(
        format:
            ImageByteFormat.png,
      );

      if (byteData == null) {
        throw StateError(
          'Could not encode selection image.',
        );
      }

      return byteData.buffer
          .asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  // ===========================================================================
  // CACHE
  // ===========================================================================

  void clearImageCache() {
    _cachedEmbedding = null;
    _lastResult = null;

    debugPrint(
      'MobileSAM image embedding cache cleared.',
    );
  }
}

// =============================================================================
// SEGMENTATION RESULT
// =============================================================================

class SegmentationResult {
  const SegmentationResult({
    required this.maskBytes,
    required this.outlineBytes,
    required this.maskWidth,
    required this.maskHeight,
    this.confidence,
    this.positivePoint,
    this.negativePoint,
    this.isProtection = false,
  });

  final Uint8List maskBytes;

  final Uint8List outlineBytes;

  final int maskWidth;
  final int maskHeight;

  final double? confidence;

  final Offset? positivePoint;

  final Offset? negativePoint;

  /// True when generated through MobileSAM Protect mode.
  final bool isProtection;

  bool get usedNegativePrompt =>
      negativePoint != null;
}

// =============================================================================
// ENCODER INPUT
// =============================================================================

class _PreparedEncoderInput {
  const _PreparedEncoderInput({
    required this.rgb,
    required this.width,
    required this.height,
    required this.originalWidth,
    required this.originalHeight,
  });

  final Float32List rgb;

  final int width;
  final int height;

  final int originalWidth;
  final int originalHeight;
}

// =============================================================================
// CACHED EMBEDDING
// =============================================================================

class _CachedImageEmbedding {
  const _CachedImageEmbedding({
    required this.values,
    required this.originalWidth,
    required this.originalHeight,
    required this.encoderWidth,
    required this.encoderHeight,
  });

  final Float32List values;

  final int originalWidth;
  final int originalHeight;

  final int encoderWidth;
  final int encoderHeight;
}