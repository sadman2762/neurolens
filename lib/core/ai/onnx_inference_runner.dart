import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:neurolens/core/ai/onnx_model_service.dart';

class OnnxInferenceRunner {
  OnnxInferenceRunner({
    OnnxModelService? modelService,
  }) : _modelService =
           modelService ??
           OnnxModelService.instance;

  final OnnxModelService _modelService;

  /// Runs a model with one Float32 input tensor and retrieves
  /// one Float32 output tensor.
  ///
  /// This is perfect for models such as LaMa:
  ///
  /// input:
  /// [1, 4, 512, 512]
  ///
  /// output:
  /// [1, 3, 512, 512]
  Future<OnnxFloatOutput> runFloatModel({
    required String modelAsset,
    required String inputName,
    required Float32List inputValues,
    required List<int> inputShape,
    required String outputName,
    List<int>? expectedOutputShape,
  }) async {
    _validateShape(
      valuesLength: inputValues.length,
      shape: inputShape,
      label: 'input',
    );

    final session =
        await _modelService.getSession(
      modelAsset,
    );

    if (!session.inputNames.contains(
      inputName,
    )) {
      throw OnnxInferenceException(
        'Model $modelAsset does not contain '
        'input "$inputName". '
        'Available inputs: ${session.inputNames}',
      );
    }

    if (!session.outputNames.contains(
      outputName,
    )) {
      throw OnnxInferenceException(
        'Model $modelAsset does not contain '
        'output "$outputName". '
        'Available outputs: ${session.outputNames}',
      );
    }

    OrtValue? inputTensor;
    Map<String, OrtValue>? outputs;

    final stopwatch =
        Stopwatch()
          ..start();

    try {
      inputTensor =
          await OrtValue.fromList(
        inputValues,
        inputShape,
      );

      outputs =
          await session.run(
        {
          inputName: inputTensor,
        },
      );

      final output =
          outputs[outputName];

      if (output == null) {
        throw OnnxInferenceException(
          'Model $modelAsset returned no '
          'output named "$outputName".',
        );
      }

      final outputShape =
          List<int>.from(
        output.shape,
      );

      if (expectedOutputShape != null) {
        _validateExpectedShape(
          actual:
              outputShape,
          expected:
              expectedOutputShape,
          modelAsset:
              modelAsset,
          outputName:
              outputName,
        );
      }

      final flattened =
          await output.asFlattenedList();

      final values =
          Float32List(
        flattened.length,
      );

      for (
        var index = 0;
        index < flattened.length;
        index++
      ) {
        final value =
            flattened[index];

        if (value is! num) {
          throw OnnxInferenceException(
            'Output "$outputName" from '
            '$modelAsset contains a '
            'non-numeric value.',
          );
        }

        values[index] =
            value.toDouble();
      }

      _validateShape(
        valuesLength:
            values.length,
        shape:
            outputShape,
        label:
            'output',
      );

      stopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          'ONNX inference complete.',
        );

        debugPrint(
          'Model: $modelAsset',
        );

        debugPrint(
          'Input: $inputName '
          '$inputShape',
        );

        debugPrint(
          'Output: $outputName '
          '$outputShape',
        );

        debugPrint(
          'Output values: '
          '${values.length}',
        );

        debugPrint(
          'Inference time: '
          '${stopwatch.elapsedMilliseconds} ms',
        );
      }

      return OnnxFloatOutput(
        values: values,
        shape: outputShape,
        inferenceTime:
            stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (error
          is OnnxInferenceException) {
        rethrow;
      }

      debugPrint(
        'ONNX inference failed for '
        '$modelAsset: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      throw OnnxInferenceException(
        'ONNX inference failed for '
        '$modelAsset: $error',
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

  /// Generic multi-input Float32 inference.
  ///
  /// We do not need this for your current LaMa model,
  /// because LaMa uses one 4-channel tensor.
  ///
  /// But this will be useful later for models such as
  /// background removers or enhancement networks.
  Future<Map<String, OnnxFloatOutput>>
      runFloatModelMultipleInputs({
    required String modelAsset,
    required Map<String, OnnxFloatInput>
        inputs,
    required List<String> outputNames,
    Map<String, List<int>>?
        expectedOutputShapes,
  }) async {
    if (inputs.isEmpty) {
      throw const OnnxInferenceException(
        'At least one model input is required.',
      );
    }

    if (outputNames.isEmpty) {
      throw const OnnxInferenceException(
        'At least one output name is required.',
      );
    }

    final session =
        await _modelService.getSession(
      modelAsset,
    );

    final inputTensors =
        <String, OrtValue>{};

    Map<String, OrtValue>? outputs;

    final stopwatch =
        Stopwatch()
          ..start();

    try {
      for (final entry
          in inputs.entries) {
        final name =
            entry.key;

        final input =
            entry.value;

        if (!session.inputNames
            .contains(name)) {
          throw OnnxInferenceException(
            'Model $modelAsset does not '
            'contain input "$name". '
            'Available inputs: '
            '${session.inputNames}',
          );
        }

        _validateShape(
          valuesLength:
              input.values.length,
          shape:
              input.shape,
          label:
              'input "$name"',
        );

        inputTensors[name] =
            await OrtValue.fromList(
          input.values,
          input.shape,
        );
      }

      for (final outputName
          in outputNames) {
        if (!session.outputNames
            .contains(
          outputName,
        )) {
          throw OnnxInferenceException(
            'Model $modelAsset does not '
            'contain output '
            '"$outputName". '
            'Available outputs: '
            '${session.outputNames}',
          );
        }
      }

      outputs =
          await session.run(
        inputTensors,
      );

      final result =
          <String, OnnxFloatOutput>{};

      for (final outputName
          in outputNames) {
        final output =
            outputs[outputName];

        if (output == null) {
          throw OnnxInferenceException(
            'Model $modelAsset returned no '
            'output named "$outputName".',
          );
        }

        final outputShape =
            List<int>.from(
          output.shape,
        );

        final expectedShape =
            expectedOutputShapes?[
                outputName];

        if (expectedShape != null) {
          _validateExpectedShape(
            actual:
                outputShape,
            expected:
                expectedShape,
            modelAsset:
                modelAsset,
            outputName:
                outputName,
          );
        }

        final flattened =
            await output
                .asFlattenedList();

        final values =
            Float32List(
          flattened.length,
        );

        for (
          var index = 0;
          index < flattened.length;
          index++
        ) {
          final value =
              flattened[index];

          if (value is! num) {
            throw OnnxInferenceException(
              'Output "$outputName" '
              'contains a non-numeric '
              'value.',
            );
          }

          values[index] =
              value.toDouble();
        }

        _validateShape(
          valuesLength:
              values.length,
          shape:
              outputShape,
          label:
              'output "$outputName"',
        );

        result[outputName] =
            OnnxFloatOutput(
          values: values,
          shape:
              outputShape,
          inferenceTime:
              Duration.zero,
        );
      }

      stopwatch.stop();

      for (final key
          in result.keys.toList()) {
        final existing =
            result[key]!;

        result[key] =
            OnnxFloatOutput(
          values:
              existing.values,
          shape:
              existing.shape,
          inferenceTime:
              stopwatch.elapsed,
        );
      }

      if (kDebugMode) {
        debugPrint(
          'ONNX multi-input inference '
          'complete.',
        );

        debugPrint(
          'Model: $modelAsset',
        );

        debugPrint(
          'Inputs: ${inputs.keys}',
        );

        debugPrint(
          'Outputs: $outputNames',
        );

        debugPrint(
          'Inference time: '
          '${stopwatch.elapsedMilliseconds} ms',
        );
      }

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (error
          is OnnxInferenceException) {
        rethrow;
      }

      debugPrint(
        'ONNX inference failed for '
        '$modelAsset: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      throw OnnxInferenceException(
        'ONNX inference failed for '
        '$modelAsset: $error',
      );
    } finally {
      for (final tensor
          in inputTensors.values) {
        await tensor.dispose();
      }

      if (outputs != null) {
        for (final output
            in outputs.values) {
          await output.dispose();
        }
      }
    }
  }

  void _validateShape({
    required int valuesLength,
    required List<int> shape,
    required String label,
  }) {
    if (shape.isEmpty) {
      throw OnnxInferenceException(
        'The $label tensor shape '
        'cannot be empty.',
      );
    }

    var expectedLength = 1;

    for (final dimension
        in shape) {
      if (dimension <= 0) {
        throw OnnxInferenceException(
          'Invalid $label tensor '
          'dimension: $dimension.',
        );
      }

      expectedLength *=
          dimension;
    }

    if (expectedLength !=
        valuesLength) {
      throw OnnxInferenceException(
        'Invalid $label tensor size. '
        'Shape $shape requires '
        '$expectedLength values, '
        'but received '
        '$valuesLength.',
      );
    }
  }

  void _validateExpectedShape({
    required List<int> actual,
    required List<int> expected,
    required String modelAsset,
    required String outputName,
  }) {
    if (actual.length !=
        expected.length) {
      throw OnnxInferenceException(
        'Unexpected shape for '
        '"$outputName" from '
        '$modelAsset. '
        'Expected $expected but '
        'received $actual.',
      );
    }

    for (
      var index = 0;
      index < actual.length;
      index++
    ) {
      if (actual[index] !=
          expected[index]) {
        throw OnnxInferenceException(
          'Unexpected shape for '
          '"$outputName" from '
          '$modelAsset. '
          'Expected $expected but '
          'received $actual.',
        );
      }
    }
  }
}

// =============================================================================
// FLOAT INPUT
// =============================================================================

class OnnxFloatInput {
  const OnnxFloatInput({
    required this.values,
    required this.shape,
  });

  final Float32List values;

  final List<int> shape;
}

// =============================================================================
// FLOAT OUTPUT
// =============================================================================

class OnnxFloatOutput {
  const OnnxFloatOutput({
    required this.values,
    required this.shape,
    required this.inferenceTime,
  });

  final Float32List values;

  final List<int> shape;

  final Duration inferenceTime;

  int get valueCount =>
      values.length;
}

// =============================================================================
// EXCEPTION
// =============================================================================

class OnnxInferenceException
    implements Exception {
  const OnnxInferenceException(
    this.message,
  );

  final String message;

  @override
  String toString() =>
      message;
}