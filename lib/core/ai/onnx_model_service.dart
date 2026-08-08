import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class OnnxModelService {
  OnnxModelService._();

  static final OnnxModelService instance =
      OnnxModelService._();

  final OnnxRuntime _runtime =
      OnnxRuntime();

  final Map<String, OrtSession> _sessions =
      <String, OrtSession>{};

  final Map<String, Future<OrtSession>>
      _loadingSessions =
      <String, Future<OrtSession>>{};

  /// Returns an already loaded session when available.
  ///
  /// If the model has not been loaded yet, it is loaded
  /// from Flutter assets and then cached.
  Future<OrtSession> getSession(
    String assetPath,
  ) async {
    final existingSession =
        _sessions[assetPath];

    if (existingSession != null) {
      return existingSession;
    }

    ///
    /// Prevent the same model from being loaded twice
    /// if two callers request it simultaneously.
    ///
    final existingLoad =
        _loadingSessions[assetPath];

    if (existingLoad != null) {
      return existingLoad;
    }

    final loadFuture =
        _loadSession(
      assetPath,
    );

    _loadingSessions[assetPath] =
        loadFuture;

    try {
      final session =
          await loadFuture;

      _sessions[assetPath] =
          session;

      return session;
    } finally {
      _loadingSessions.remove(
        assetPath,
      );
    }
  }

  Future<OrtSession> _loadSession(
    String assetPath,
  ) async {
    if (kDebugMode) {
      debugPrint(
        'ONNX: loading model $assetPath',
      );
    }

    final stopwatch =
        Stopwatch()
          ..start();

    try {
      final session =
          await _runtime
              .createSessionFromAsset(
        assetPath,
      );

      stopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          'ONNX: loaded $assetPath '
          'in ${stopwatch.elapsedMilliseconds} ms',
        );

        debugPrint(
          'ONNX: inputs '
          '${session.inputNames}',
        );

        debugPrint(
          'ONNX: outputs '
          '${session.outputNames}',
        );
      }

      return session;
    } catch (error, stackTrace) {
      stopwatch.stop();

      debugPrint(
        'ONNX: failed to load '
        '$assetPath: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// Check whether a specific model is currently cached.
  bool isLoaded(
    String assetPath,
  ) {
    return _sessions.containsKey(
      assetPath,
    );
  }

  /// Number of ONNX models currently loaded.
  int get loadedModelCount =>
      _sessions.length;

  /// Paths of all models currently loaded.
  List<String> get loadedModels =>
      List<String>.unmodifiable(
        _sessions.keys,
      );

  /// Useful for debugging model input/output information.
  Future<void> printModelInfo(
    String assetPath,
  ) async {
    final session =
        await getSession(
      assetPath,
    );

    try {
      final inputInfo =
          await session.getInputInfo();

      final outputInfo =
          await session.getOutputInfo();

      debugPrint(
        '===== ONNX MODEL =====',
      );

      debugPrint(
        'Asset: $assetPath',
      );

      debugPrint(
        'Inputs: ${session.inputNames}',
      );

      debugPrint(
        'Input info: $inputInfo',
      );

      debugPrint(
        'Outputs: ${session.outputNames}',
      );

      debugPrint(
        'Output info: $outputInfo',
      );

      debugPrint(
        '======================',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Could not inspect ONNX model '
        '$assetPath: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// Removes a model session from this service's cache.
  ///
  /// We intentionally don't dispose the session here yet,
  /// because different versions of flutter_onnxruntime
  /// expose session lifecycle APIs differently.
  ///
  /// This removes our reference so a fresh session can
  /// be created when requested again.
  void removeSession(
    String assetPath,
  ) {
    _sessions.remove(
      assetPath,
    );

    _loadingSessions.remove(
      assetPath,
    );

    if (kDebugMode) {
      debugPrint(
        'ONNX: removed cached session '
        '$assetPath',
      );
    }
  }

  /// Removes all cached references.
  ///
  /// Normally you should NOT call this while an AI editor
  /// is open because models would need to be loaded again.
  void clearCache() {
    _sessions.clear();
    _loadingSessions.clear();

    if (kDebugMode) {
      debugPrint(
        'ONNX: model session cache cleared.',
      );
    }
  }
}