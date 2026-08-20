import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:neurolens/features/people/data/face_detection_service.dart';

class FaceAlignmentService {
  const FaceAlignmentService();

  static const int outputSize = 112;

  /// Canonical 5-point face landmarks for a 112x112 aligned face.
  static const List<ui.Offset> _referencePoints = [
    ui.Offset(38.2946, 51.6963),
    ui.Offset(73.5318, 51.5014),
    ui.Offset(56.0252, 71.7366),
    ui.Offset(41.5493, 92.3655),
    ui.Offset(70.7299, 92.2041),
  ];

  Future<Uint8List> alignFace({
    required ui.Image image,
    required NeuroLensDetectedFace face,
  }) async {
    if (!face.hasFullAlignmentLandmarks) {
      throw const FaceAlignmentException(
        'Full face landmarks are not available.',
      );
    }

    final sourcePoints = <ui.Offset>[
      face.leftEye!,
      face.rightEye!,
      face.noseBase!,
      face.leftMouth!,
      face.rightMouth!,
    ];

    final transform = _estimateSimilarityTransform(
      sourcePoints: sourcePoints,
      targetPoints: _referencePoints,
    );

    final recorder = ui.PictureRecorder();

    final canvas = ui.Canvas(
      recorder,
    );

    final paint = ui.Paint()
      ..filterQuality = ui.FilterQuality.high
      ..isAntiAlias = true;

    final matrix = Float64List.fromList([
      transform.a,
      transform.b,
      0.0,
      0.0,

      -transform.b,
      transform.a,
      0.0,
      0.0,

      0.0,
      0.0,
      1.0,
      0.0,

      transform.tx,
      transform.ty,
      0.0,
      1.0,
    ]);

    canvas.transform(matrix);

    canvas.drawImage(
      image,
      ui.Offset.zero,
      paint,
    );

    final picture = recorder.endRecording();

    final alignedImage = await picture.toImage(
      outputSize,
      outputSize,
    );

    picture.dispose();

    try {
      final byteData = await alignedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw const FaceAlignmentException(
          'Failed to encode aligned face.',
        );
      }

      final result = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      if (kDebugMode) {
        debugPrint(
          '===== Face alignment =====',
        );

        debugPrint(
          'Output: ${outputSize}x$outputSize',
        );

        debugPrint(
          'Left eye: ${face.leftEye}',
        );

        debugPrint(
          'Right eye: ${face.rightEye}',
        );

        debugPrint(
          'Nose: ${face.noseBase}',
        );

        debugPrint(
          'Left mouth: ${face.leftMouth}',
        );

        debugPrint(
          'Right mouth: ${face.rightMouth}',
        );

        debugPrint(
          'Scale/rotation A: '
          '${transform.a.toStringAsFixed(5)}',
        );

        debugPrint(
          'Scale/rotation B: '
          '${transform.b.toStringAsFixed(5)}',
        );

        debugPrint(
          'Translation: '
          '(${transform.tx.toStringAsFixed(2)}, '
          '${transform.ty.toStringAsFixed(2)})',
        );

        debugPrint(
          '==========================',
        );
      }

      return result;
    } finally {
      alignedImage.dispose();
    }
  }

  _SimilarityTransform _estimateSimilarityTransform({
    required List<ui.Offset> sourcePoints,
    required List<ui.Offset> targetPoints,
  }) {
    if (sourcePoints.length != targetPoints.length) {
      throw const FaceAlignmentException(
        'Source and target landmark counts do not match.',
      );
    }

    if (sourcePoints.length < 2) {
      throw const FaceAlignmentException(
        'At least two landmarks are required.',
      );
    }

    final sourceCenter = _calculateCenter(
      sourcePoints,
    );

    final targetCenter = _calculateCenter(
      targetPoints,
    );

    var sourceVariance = 0.0;
    var dot = 0.0;
    var cross = 0.0;

    for (
      var index = 0;
      index < sourcePoints.length;
      index++
    ) {
      final sourceX =
          sourcePoints[index].dx -
          sourceCenter.dx;

      final sourceY =
          sourcePoints[index].dy -
          sourceCenter.dy;

      final targetX =
          targetPoints[index].dx -
          targetCenter.dx;

      final targetY =
          targetPoints[index].dy -
          targetCenter.dy;

      sourceVariance +=
          sourceX * sourceX +
          sourceY * sourceY;

      dot +=
          sourceX * targetX +
          sourceY * targetY;

      cross +=
          sourceX * targetY -
          sourceY * targetX;
    }

    if (sourceVariance <= 0.0) {
      throw const FaceAlignmentException(
        'Face landmarks have invalid geometry.',
      );
    }

    final magnitude = math.sqrt(
      dot * dot + cross * cross,
    );

    final scale =
        magnitude / sourceVariance;

    if (!scale.isFinite || scale <= 0.0) {
      throw const FaceAlignmentException(
        'Unable to calculate face alignment scale.',
      );
    }

    final angle = math.atan2(
      cross,
      dot,
    );

    final cosine = math.cos(angle);
    final sine = math.sin(angle);

    final a = scale * cosine;
    final b = scale * sine;

    final tx =
        targetCenter.dx -
        (
          a * sourceCenter.dx -
          b * sourceCenter.dy
        );

    final ty =
        targetCenter.dy -
        (
          b * sourceCenter.dx +
          a * sourceCenter.dy
        );

    if (!a.isFinite ||
        !b.isFinite ||
        !tx.isFinite ||
        !ty.isFinite) {
      throw const FaceAlignmentException(
        'Face alignment produced an invalid transform.',
      );
    }

    return _SimilarityTransform(
      a: a,
      b: b,
      tx: tx,
      ty: ty,
    );
  }

  ui.Offset _calculateCenter(
    List<ui.Offset> points,
  ) {
    var x = 0.0;
    var y = 0.0;

    for (final point in points) {
      x += point.dx;
      y += point.dy;
    }

    return ui.Offset(
      x / points.length,
      y / points.length,
    );
  }
}

class _SimilarityTransform {
  const _SimilarityTransform({
    required this.a,
    required this.b,
    required this.tx,
    required this.ty,
  });

  final double a;
  final double b;
  final double tx;
  final double ty;
}

class FaceAlignmentException
    implements Exception {
  const FaceAlignmentException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}