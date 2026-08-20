import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:neurolens/core/ai/onnx_inference_runner.dart';
import 'package:neurolens/features/people/data/face_preprocessor.dart';

class FaceEmbeddingService {
  FaceEmbeddingService({
    OnnxInferenceRunner? runner,
    FacePreprocessor? preprocessor,
  }) : _runner = runner ?? OnnxInferenceRunner(),
       _preprocessor =
           preprocessor ?? const FacePreprocessor();

  // ---------------------------------------------------------------------------
  // EdgeFace model configuration
  // ---------------------------------------------------------------------------

  static const String modelAsset =
      'assets/models/edgeface_xs_gamma_06.onnx';

  /// Verified from the actual ONNX model at runtime:
  ///
  /// Inputs:
  ///   [input]
  ///
  /// Outputs:
  ///   [embedding]
  static const String inputName = 'input';

  static const String outputName = 'embedding';

  static const int embeddingDimension = 512;

  final OnnxInferenceRunner _runner;
  final FacePreprocessor _preprocessor;

  // ---------------------------------------------------------------------------
  // Generate embedding
  // ---------------------------------------------------------------------------

  Future<FaceEmbeddingResult> generateEmbedding({
    required Uint8List faceImageBytes,
  }) async {
    if (faceImageBytes.isEmpty) {
      throw const FaceEmbeddingException(
        'Face image bytes are empty.',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      // -----------------------------------------------------------------------
      // 1. Preprocess face
      //
      // Face image
      //     ↓
      // Resize / normalize
      //     ↓
      // [1, 3, 112, 112]
      // -----------------------------------------------------------------------

      final inputTensor =
          await _preprocessor.preprocess(
        faceImageBytes,
      );

      // -----------------------------------------------------------------------
      // 2. EdgeFace ONNX inference
      // -----------------------------------------------------------------------

      final output =
          await _runner.runFloatModel(
        modelAsset: modelAsset,
        inputName: inputName,
        inputValues: inputTensor,
        inputShape: const [
          1,
          3,
          FacePreprocessor.modelSize,
          FacePreprocessor.modelSize,
        ],
        outputName: outputName,
        expectedOutputShape: const [
          1,
          embeddingDimension,
        ],
      );

      // -----------------------------------------------------------------------
      // 3. Validate embedding
      // -----------------------------------------------------------------------

      if (output.values.length !=
          embeddingDimension) {
        throw FaceEmbeddingException(
          'Unexpected EdgeFace embedding size. '
          'Expected $embeddingDimension values but '
          'received ${output.values.length}.',
        );
      }

      // -----------------------------------------------------------------------
      // 4. L2 normalize
      //
      // This allows cosine similarity to be used reliably
      // when comparing two faces.
      // -----------------------------------------------------------------------

      final normalized = _l2Normalize(
        output.values,
      );

      stopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          '===== EdgeFace embedding =====',
        );

        debugPrint(
          'Model: $modelAsset',
        );

        debugPrint(
          'Input name: $inputName',
        );

        debugPrint(
          'Output name: $outputName',
        );

        debugPrint(
          'Output shape: ${output.shape}',
        );

        debugPrint(
          'Embedding dimension: '
          '${normalized.length}',
        );

        debugPrint(
          'Inference: '
          '${output.inferenceTime.inMilliseconds} ms',
        );

        debugPrint(
          'Total: '
          '${stopwatch.elapsedMilliseconds} ms',
        );

        debugPrint(
          '==============================',
        );
      }

      return FaceEmbeddingResult(
        embedding: normalized,
        model: 'edgeface-xs-gamma-0.6',
        inferenceTime: output.inferenceTime,
      );
    } on FacePreprocessorException catch (error) {
      stopwatch.stop();

      throw FaceEmbeddingException(
        'Face preprocessing failed: '
        '${error.message}',
      );
    } on OnnxInferenceException catch (error) {
      stopwatch.stop();

      throw FaceEmbeddingException(
        'EdgeFace inference failed: '
        '${error.message}',
      );
    } on FaceEmbeddingException {
      stopwatch.stop();

      rethrow;
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          'Face embedding failed: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }

      throw FaceEmbeddingException(
        'Face embedding generation failed: '
        '$error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // L2 normalization
  // ---------------------------------------------------------------------------

  Float32List _l2Normalize(
    Float32List values,
  ) {
    if (values.isEmpty) {
      throw const FaceEmbeddingException(
        'EdgeFace returned an empty embedding.',
      );
    }

    var sumSquares = 0.0;

    for (final value in values) {
      if (!value.isFinite) {
        throw const FaceEmbeddingException(
          'EdgeFace returned a non-finite embedding value.',
        );
      }

      sumSquares += value * value;
    }

    final magnitude = math.sqrt(
      sumSquares,
    );

    if (!magnitude.isFinite ||
        magnitude <= 0) {
      throw const FaceEmbeddingException(
        'EdgeFace returned a zero-length embedding.',
      );
    }

    final normalized =
        Float32List(
      values.length,
    );

    for (
      var index = 0;
      index < values.length;
      index++
    ) {
      normalized[index] =
          values[index] / magnitude;
    }

    return normalized;
  }
}

// =============================================================================
// Result
// =============================================================================

class FaceEmbeddingResult {
  const FaceEmbeddingResult({
    required this.embedding,
    required this.model,
    required this.inferenceTime,
  });

  final Float32List embedding;

  final String model;

  final Duration inferenceTime;

  int get dimension =>
      embedding.length;

  List<double> toList() {
    return embedding
        .map(
          (value) => value.toDouble(),
        )
        .toList(
          growable: false,
        );
  }
}

// =============================================================================
// Exception
// =============================================================================

class FaceEmbeddingException
    implements Exception {
  const FaceEmbeddingException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}