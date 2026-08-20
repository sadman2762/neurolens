import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

class FacePreprocessor {
  const FacePreprocessor();

  static const int modelSize = 112;

  /// Converts encoded image bytes into a normalized NCHW Float32 tensor:
  ///
  /// [1, 3, 112, 112]
  ///
  /// Normalization:
  ///
  /// pixel / 255
  ///      ↓
  /// (value - 0.5) / 0.5
  ///      ↓
  /// [-1, 1]
  Future<Float32List> preprocess(
    Uint8List faceImageBytes,
  ) async {
    if (faceImageBytes.isEmpty) {
      throw const FacePreprocessorException(
        'Face image bytes are empty.',
      );
    }

    final codec = await ui.instantiateImageCodec(
      faceImageBytes,
      targetWidth: modelSize,
      targetHeight: modelSize,
    );

    final frame = await codec.getNextFrame();

    final image = frame.image;

    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        throw const FacePreprocessorException(
          'Failed to decode face pixels.',
        );
      }

      final rgba = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      return _rgbaToTensor(
        rgba,
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
      codec.dispose();
    }
  }

  Float32List _rgbaToTensor(
    Uint8List rgba, {
    required int width,
    required int height,
  }) {
    if (width != modelSize ||
        height != modelSize) {
      throw FacePreprocessorException(
        'Unexpected resized face dimensions: '
        '${width}x$height. '
        'Expected ${modelSize}x$modelSize.',
      );
    }

    const pixels = modelSize * modelSize;

    final tensor = Float32List(
      3 * pixels,
    );

    final redOffset = 0;
    final greenOffset = pixels;
    final blueOffset = pixels * 2;

    var pixelIndex = 0;

    for (
      var rgbaIndex = 0;
      rgbaIndex < rgba.length;
      rgbaIndex += 4
    ) {
      final red = rgba[rgbaIndex];
      final green = rgba[rgbaIndex + 1];
      final blue = rgba[rgbaIndex + 2];

      tensor[redOffset + pixelIndex] =
          _normalize(red);

      tensor[greenOffset + pixelIndex] =
          _normalize(green);

      tensor[blueOffset + pixelIndex] =
          _normalize(blue);

      pixelIndex++;
    }

    if (pixelIndex != pixels) {
      throw FacePreprocessorException(
        'Unexpected number of face pixels. '
        'Expected $pixels but received '
        '$pixelIndex.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        'EdgeFace preprocessing complete.',
      );

      debugPrint(
        'Tensor shape: '
        '[1, 3, $modelSize, $modelSize]',
      );

      debugPrint(
        'Tensor values: ${tensor.length}',
      );
    }

    return tensor;
  }

  double _normalize(
    int channelValue,
  ) {
    final zeroToOne =
        channelValue / 255.0;

    return (zeroToOne - 0.5) / 0.5;
  }
}

class FacePreprocessorException
    implements Exception {
  const FacePreprocessorException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}