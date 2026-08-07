import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class LocalSegmentationService {
  LocalSegmentationService();

  static const String _encoderAsset =
      'assets/models/mobile_sam_image_encoder.onnx';

  static const String _decoderAsset =
      'assets/models/sam_mask_decoder_single.onnx';

  static const int _encoderImageSize = 1024;
  static const int _lowResMaskSize = 256;

  final OnnxRuntime _runtime = OnnxRuntime();

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

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    _encoderSession =
        await _runtime.createSessionFromAsset(
      _encoderAsset,
    );

    _decoderSession =
        await _runtime.createSessionFromAsset(
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

    if (encoder == null || decoder == null) {
      debugPrint(
        'MobileSAM sessions are not initialized.',
      );
      return;
    }

    debugPrint('===== MobileSAM Encoder =====');
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

    debugPrint('===== MobileSAM Decoder =====');
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

      outputs = await encoder.run({
        'input_image': inputTensor,
      });

      final embeddings =
          outputs['image_embeddings'];

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
        'Embedding shape: ${embeddings.shape}',
      );

      final flattened =
          await embeddings.asFlattenedList();

      final embeddingValues =
          Float32List(flattened.length);

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
        values: embeddingValues,
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
        await originalCodec.getNextFrame();

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

    final longestEdge = math.max(
      originalWidth,
      originalHeight,
    );

    final scale =
        _encoderImageSize / longestEdge;

    final targetWidth = math.max(
      1,
      (originalWidth * scale).round(),
    );

    final targetHeight = math.max(
      1,
      (originalHeight * scale).round(),
    );

    originalImage.dispose();
    originalCodec.dispose();

    final resizedCodec =
        await instantiateImageCodec(
      imageBytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    final resizedFrame =
        await resizedCodec.getNextFrame();

    final resizedImage =
        resizedFrame.image;

    try {
      final byteData =
          await resizedImage.toByteData(
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

      final rgb = Float32List(
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
            rgba[rgbaIndex].toDouble();

        rgb[rgbIndex++] =
            rgba[rgbaIndex + 1].toDouble();

        rgb[rgbIndex++] =
            rgba[rgbaIndex + 2].toDouble();
      }

      return _PreparedEncoderInput(
        rgb: rgb,
        width: targetWidth,
        height: targetHeight,
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

  Future<Uint8List?> segmentFromPoint({
    required Uint8List imageBytes,
    required Offset imagePoint,
  }) async {
    final result =
        await segmentDetailedFromPoint(
      imageBytes: imageBytes,
      imagePoint: imagePoint,
    );

    return result.maskBytes;
  }

  Future<SegmentationResult>
      segmentDetailedFromPoint({
    required Uint8List imageBytes,
    required Offset imagePoint,
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

    final scaledX =
        imagePoint.dx *
        cached.encoderWidth /
        cached.originalWidth;

    final scaledY =
        imagePoint.dy *
        cached.encoderHeight /
        cached.originalHeight;

    debugPrint(
      'Running MobileSAM decoder...',
    );

    debugPrint(
      'Original tap: '
      '${imagePoint.dx.toStringAsFixed(1)}, '
      '${imagePoint.dy.toStringAsFixed(1)}',
    );

    debugPrint(
      'Decoder tap: '
      '${scaledX.toStringAsFixed(1)}, '
      '${scaledY.toStringAsFixed(1)}',
    );

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
        Float32List.fromList([
          scaledX,
          scaledY,
          0,
          0,
        ]),
        const [
          1,
          2,
          2,
        ],
      );

      pointLabelsTensor =
          await OrtValue.fromList(
        Float32List.fromList([
          1,
          -1,
        ]),
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
        Float32List.fromList([
          0,
        ]),
        const [
          1,
        ],
      );

      originalSizeTensor =
          await OrtValue.fromList(
        Float32List.fromList([
          cached.originalHeight
              .toDouble(),
          cached.originalWidth
              .toDouble(),
        ]),
        const [
          2,
        ],
      );

      outputs = await decoder.run({
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
      });

      final fullMask =
          outputs['masks'];

      final lowResMask =
          outputs['low_res_masks'];

      final iou =
          outputs['iou_predictions'];

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
        'Full mask shape: ${fullMask?.shape}',
      );

      debugPrint(
        'Low-res mask shape: ${lowResMask.shape}',
      );

      final values =
          await lowResMask
              .asFlattenedList();

      debugPrint(
        'Low-res mask values: ${values.length}',
      );

      double? confidence;

      if (iou != null) {
        final iouValues =
            await iou
                .asFlattenedList();

        debugPrint(
          'IoU prediction: $iouValues',
        );

        if (iouValues.isNotEmpty) {
          confidence =
              (iouValues.first as num)
                  .toDouble();
        }
      }

      final validMaskWidth = math.max(
        1,
        (cached.encoderWidth /
                _encoderImageSize *
                _lowResMaskSize)
            .round(),
      );

      final validMaskHeight = math.max(
        1,
        (cached.encoderHeight /
                _encoderImageSize *
                _lowResMaskSize)
            .round(),
      );

      final binaryMask =
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

      debugPrint(
        'Selection outline PNG created: '
        '${outlineBytes.length} bytes',
      );

      final result =
          SegmentationResult(
        maskBytes: maskBytes,
        outlineBytes:
            outlineBytes,
        maskWidth:
            validMaskWidth,
        maskHeight:
            validMaskHeight,
        confidence:
            confidence,
      );

      _lastResult = result;

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

  Uint8List _createBinaryMask(
    List<dynamic> values, {
    required int sourceWidth,
    required int sourceHeight,
    required int outputWidth,
    required int outputHeight,
  }) {
    final expectedLength =
        sourceWidth * sourceHeight;

    if (values.length !=
        expectedLength) {
      throw StateError(
        'Unexpected MobileSAM mask size: '
        '${values.length}. Expected '
        '$expectedLength.',
      );
    }

    if (outputWidth > sourceWidth ||
        outputHeight > sourceHeight) {
      throw StateError(
        'Invalid cropped mask dimensions.',
      );
    }

    final binary =
        Uint8List(
      outputWidth * outputHeight,
    );

    var selectedPixels = 0;

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
            y * sourceWidth + x;

        final logit =
            (values[sourceIndex] as num)
                .toDouble();

        if (logit > 0) {
          binary[
              y * outputWidth + x] = 1;

          selectedPixels++;
        }
      }
    }

    debugPrint(
      'Cropped mask: '
      '${outputWidth}x$outputHeight',
    );

    debugPrint(
      'Selected mask pixels: '
      '$selectedPixels / '
      '${outputWidth * outputHeight}',
    );

    if (selectedPixels == 0) {
      throw StateError(
        'MobileSAM returned an empty object mask.',
      );
    }

    return binary;
  }

  Future<Uint8List>
      _encodeBinaryMaskPng(
    Uint8List binaryMask, {
    required int width,
    required int height,
  }) async {
    final rgba =
        Uint8List(
      width * height * 4,
    );

    for (
      var index = 0;
      index < binaryMask.length;
      index++
    ) {
      if (binaryMask[index] == 0) {
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
      width: width,
      height: height,
    );
  }

  Future<Uint8List> _createOutlinePng(
    Uint8List mask, {
    required int width,
    required int height,
  }) async {
    final rgba =
        Uint8List(
      width * height * 4,
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
              y * width + x] !=
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
            !selected(x - 1, y) ||
            !selected(x + 1, y) ||
            !selected(x, y - 1) ||
            !selected(x, y + 1);

        if (!boundary) {
          continue;
        }

        final rgbaIndex =
            (y * width + x) * 4;

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
      width: width,
      height: height,
    );
  }

  Future<Uint8List> _encodeRgbaPng(
    Uint8List rgba, {
    required int width,
    required int height,
  }) async {
    final buffer =
        await ImmutableBuffer
            .fromUint8List(
      rgba,
    );

    final descriptor =
        ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
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

      image = frame.image;

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

  void clearImageCache() {
    _cachedEmbedding = null;
    _lastResult = null;

    debugPrint(
      'MobileSAM image embedding cache cleared.',
    );
  }
}

class SegmentationResult {
  const SegmentationResult({
    required this.maskBytes,
    required this.outlineBytes,
    required this.maskWidth,
    required this.maskHeight,
    this.confidence,
  });

  /// Exact MobileSAM binary selection.
  ///
  /// Keep this for the backend object-removal request.
  final Uint8List maskBytes;

  /// Boundary generated directly from [maskBytes].
  ///
  /// Because it uses the exact same bitmap coordinate
  /// system, it will align identically with the object.
  final Uint8List outlineBytes;

  final int maskWidth;
  final int maskHeight;

  final double? confidence;
}

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