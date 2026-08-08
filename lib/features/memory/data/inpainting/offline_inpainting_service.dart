import 'package:flutter/foundation.dart';
import 'package:neurolens/core/ai/onnx_inference_runner.dart';
import 'package:neurolens/features/memory/data/inpainting/inpainting_postprocessor.dart';
import 'package:neurolens/features/memory/data/inpainting/inpainting_preprocessor.dart';

class OfflineInpaintingService {
  OfflineInpaintingService({
    OnnxInferenceRunner? runner,
    InpaintingPreprocessor? preprocessor,
    InpaintingPostprocessor? postprocessor,
  })  : _runner = runner ?? OnnxInferenceRunner(),
        _preprocessor =
            preprocessor ?? const InpaintingPreprocessor(),
        _postprocessor =
            postprocessor ?? const InpaintingPostprocessor();

  static const String _modelAsset =
      'assets/models/lama.onnx';

  static const String _inputName =
      'input';

  static const String _outputName =
      'output';

  final OnnxInferenceRunner _runner;

  final InpaintingPreprocessor
      _preprocessor;

  final InpaintingPostprocessor
      _postprocessor;

  Future<Uint8List> inpaint({
    required Uint8List imageBytes,
    required Uint8List maskBytes,

    /// Optional strict protection mask.
    ///
    /// White pixels:
    /// must stay untouched.
    ///
    /// Transparent / black:
    /// may be reconstructed.
    Uint8List? protectionMaskBytes,
  }) async {
    if (imageBytes.isEmpty) {
      throw const OfflineInpaintingException(
        'The source image is empty.',
      );
    }

    if (maskBytes.isEmpty) {
      throw const OfflineInpaintingException(
        'The removal mask is empty.',
      );
    }

    final stopwatch =
        Stopwatch()..start();

    try {
      debugPrint(
        '===== Offline LaMa started =====',
      );

      debugPrint(
        'Protection: '
        '${protectionMaskBytes != null && protectionMaskBytes.isNotEmpty ? 'enabled' : 'disabled'}',
      );

      // =======================================================================
      // 1. PREPROCESS
      //
      // remove mask
      //      ↓
      // dilation
      //      ↓
      // subtract strict protection
      //      ↓
      // [1,4,512,512]
      // =======================================================================

      final prepared =
          await _preprocessor.prepare(
        imageBytes:
            imageBytes,
        maskBytes:
            maskBytes,
        protectionMaskBytes:
            protectionMaskBytes,
      );

      debugPrint(
        'LaMa selected fraction: '
        '${(prepared.selectedFraction * 100).toStringAsFixed(2)}%',
      );

      if (prepared.hasProtection) {
        debugPrint(
          'Protected fraction: '
          '${(prepared.protectedFraction * 100).toStringAsFixed(2)}%',
        );
      }

      // =======================================================================
      // 2. LAMA
      // =======================================================================

      final output =
          await _runner.runFloatModel(
        modelAsset:
            _modelAsset,
        inputName:
            _inputName,
        inputValues:
            prepared.tensor,
        inputShape: const [
          1,
          4,
          InpaintingPreprocessor
              .modelSize,
          InpaintingPreprocessor
              .modelSize,
        ],
        outputName:
            _outputName,
        expectedOutputShape:
            const [
          1,
          3,
          InpaintingPreprocessor
              .modelSize,
          InpaintingPreprocessor
              .modelSize,
        ],
      );

      debugPrint(
        'LaMa inference took '
        '${output.inferenceTime.inMilliseconds} ms.',
      );

      // =======================================================================
      // 3. HIGH-RES COMPOSITE
      //
      // The postprocessor receives prepared.modelMask.
      //
      // Because modelMask already has protected pixels removed,
      // the compositing stage cannot replace protected pixels either.
      // =======================================================================

      final result =
          await _postprocessor.process(
        originalImageBytes:
            imageBytes,
        preparedInput:
            prepared,
        modelOutput:
            output,
      );

      stopwatch.stop();

      debugPrint(
        'Offline LaMa inpainting completed '
        'in ${stopwatch.elapsedMilliseconds} ms.',
      );

      debugPrint(
        'Final result bytes: '
        '${result.length}',
      );

      debugPrint(
        '================================',
      );

      return result;
    } on InpaintingPreprocessorException catch (error) {
      stopwatch.stop();

      throw OfflineInpaintingException(
        error.message,
      );
    } on InpaintingPostprocessorException catch (error) {
      stopwatch.stop();

      throw OfflineInpaintingException(
        error.message,
      );
    } on OnnxInferenceException catch (error) {
      stopwatch.stop();

      throw OfflineInpaintingException(
        'LaMa inference failed: '
        '${error.message}',
      );
    } catch (error, stackTrace) {
      stopwatch.stop();

      debugPrint(
        'Offline inpainting failed: '
        '$error',
      );

      debugPrintStack(
        stackTrace:
            stackTrace,
      );

      throw OfflineInpaintingException(
        'Offline object removal failed: '
        '$error',
      );
    }
  }
}

class OfflineInpaintingException
    implements Exception {
  const OfflineInpaintingException(
    this.message,
  );

  final String message;

  @override
  String toString() =>
      message;
}