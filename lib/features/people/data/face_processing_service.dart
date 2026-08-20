// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/people/data/face_alignment_service.dart';
import 'package:neurolens/features/people/data/face_detection_service.dart';
import 'package:neurolens/features/people/data/face_embedding_service.dart';
import 'package:neurolens/features/people/data/face_matching_service.dart';

class FaceProcessingService {
  FaceProcessingService({
    required MemoryRepositoryImpl memoryRepository,
    required FaceDetectionService faceDetectionService,
    required FaceEmbeddingService faceEmbeddingService,
    required FaceMatchingService faceMatchingService,
    FaceAlignmentService? faceAlignmentService,
  }) : _memoryRepository = memoryRepository,
       _faceDetectionService = faceDetectionService,
       _faceEmbeddingService = faceEmbeddingService,
       _faceMatchingService = faceMatchingService,
       _faceAlignmentService =
           faceAlignmentService ?? const FaceAlignmentService();

  final MemoryRepositoryImpl _memoryRepository;
  final FaceDetectionService _faceDetectionService;
  final FaceEmbeddingService _faceEmbeddingService;
  final FaceMatchingService _faceMatchingService;
  final FaceAlignmentService _faceAlignmentService;

  /// Used only when ML Kit cannot provide enough landmarks
  /// for proper 5-point face alignment.
  static const double _facePaddingFactor = 0.20;

  Future<FaceProcessingResult> processImage({
    required String memoryId,
    required String imagePath,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final alreadyProcessed =
          await _memoryRepository.hasProcessedFacesForMemory(
        memoryId,
      );

      if (alreadyProcessed) {
        if (kDebugMode) {
          debugPrint(
            'Faces already processed for memory: $memoryId',
          );
        }

        return const FaceProcessingResult(
          detectedFaces: 0,
          savedFaces: 0,
          matchedFaces: 0,
          newPeopleCreated: 0,
          skipped: true,
        );
      }

      // -----------------------------------------------------------------------
      // 1. Detect faces + landmarks
      // -----------------------------------------------------------------------

      final faces =
          await _faceDetectionService.detectFacesFromPath(
        imagePath,
      );

      if (faces.isEmpty) {
        stopwatch.stop();

        if (kDebugMode) {
          debugPrint(
            'No faces detected in memory: $memoryId',
          );
        }

        return const FaceProcessingResult(
          detectedFaces: 0,
          savedFaces: 0,
          matchedFaces: 0,
          newPeopleCreated: 0,
          skipped: false,
        );
      }

      // -----------------------------------------------------------------------
      // 2. Decode original image once
      // -----------------------------------------------------------------------

      final imageBytes = await _readImageBytes(
        imagePath,
      );

      final decodedImage = await _decodeImage(
        imageBytes,
      );

      var savedFaces = 0;
      var matchedFaces = 0;
      var newPeopleCreated = 0;

      try {
        // ---------------------------------------------------------------------
        // 3. Process every detected face
        // ---------------------------------------------------------------------

        for (
          var faceIndex = 0;
          faceIndex < faces.length;
          faceIndex++
        ) {
          final face = faces[faceIndex];

          try {
            // -----------------------------------------------------------------
            // Prepare face for EdgeFace
            //
            // Preferred:
            //
            // ML Kit landmarks
            //      ↓
            // 5-point alignment
            //      ↓
            // canonical 112x112 face
            //
            // Fallback:
            //
            // padded square bounding-box crop
            // -----------------------------------------------------------------

            final preparedFace =
                await _prepareFaceForEmbedding(
              image: decodedImage,
              face: face,
              faceIndex: faceIndex,
            );

            // -----------------------------------------------------------------
            // Generate EdgeFace embedding
            // -----------------------------------------------------------------

            final embeddingResult =
                await _faceEmbeddingService.generateEmbedding(
              faceImageBytes: preparedFace.bytes,
            );

            final embedding =
                embeddingResult.toList();

            // -----------------------------------------------------------------
            // Load existing embeddings
            // -----------------------------------------------------------------

            final existingFaces =
                await _memoryRepository.getAllFaceEmbeddings();

            final candidates = existingFaces
                .where(
                  (row) =>
                      row.personId != null &&
                      row.embeddingDimension ==
                          embeddingResult.dimension &&
                      row.model ==
                          embeddingResult.model,
                )
                .map(
                  (row) {
                    try {
                      return FaceMatchCandidate(
                        id: row.id,
                        personId: row.personId,
                        embedding:
                            _memoryRepository
                                .decodeFaceEmbeddingRow(
                          row,
                        ),
                      );
                    } catch (_) {
                      return null;
                    }
                  },
                )
                .whereType<FaceMatchCandidate>()
                .toList(
                  growable: false,
                );

            // -----------------------------------------------------------------
            // Find best existing person
            // -----------------------------------------------------------------

            final bestMatch =
                _faceMatchingService.findBestMatch(
              queryEmbedding: embedding,
              candidates: candidates,
            );

            String personId;
            double? similarity;

            if (bestMatch != null &&
                bestMatch.isMatch &&
                bestMatch.personId != null) {
              personId = bestMatch.personId!;
              similarity = bestMatch.similarity;

              matchedFaces++;
            } else {
              personId = _generatePersonId(
                memoryId: memoryId,
                faceIndex: faceIndex,
              );

              await _memoryRepository.savePerson(
                id: personId,
                clusterId: personId,
              );

              newPeopleCreated++;
            }

            // -----------------------------------------------------------------
            // Save face embedding
            // -----------------------------------------------------------------

            final faceId = _generateFaceId(
              memoryId: memoryId,
              faceIndex: faceIndex,
            );

            await _memoryRepository.saveFaceEmbedding(
              id: faceId,
              memoryId: memoryId,
              personId: personId,
              embedding: jsonEncode(
                embedding,
              ),
              model: embeddingResult.model,
              embeddingDimension:
                  embeddingResult.dimension,
              boundingLeft:
                  face.boundingBox.left,
              boundingTop:
                  face.boundingBox.top,
              boundingWidth:
                  face.boundingBox.width,
              boundingHeight:
                  face.boundingBox.height,
              detectionConfidence: null,
              faceCropPath: null,
              faceHash: null,
            );

            // -----------------------------------------------------------------
            // Link memory ↔ person
            // -----------------------------------------------------------------

            await _memoryRepository.linkMemoryToPerson(
              memoryId: memoryId,
              personId: personId,
              similarity: similarity,
            );

            savedFaces++;

            if (kDebugMode) {
              debugPrint(
                'Face saved.',
              );

              debugPrint(
                'Memory: $memoryId',
              );

              debugPrint(
                'Face: $faceId',
              );

              debugPrint(
                'Person: $personId',
              );

              debugPrint(
                'Preparation: '
                '${preparedFace.usedAlignment ? 'aligned' : 'fallback crop'}',
              );

              debugPrint(
                similarity == null
                    ? 'Match: new person'
                    : 'Similarity: '
                        '${similarity.toStringAsFixed(4)}',
              );
            }
          } catch (error, stackTrace) {
            if (kDebugMode) {
              debugPrint(
                'Failed processing face '
                '$faceIndex in memory '
                '$memoryId: $error',
              );

              debugPrintStack(
                stackTrace: stackTrace,
              );
            }
          }
        }
      } finally {
        decodedImage.dispose();
      }

      stopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          '===== Face processing complete =====',
        );

        debugPrint(
          'Memory: $memoryId',
        );

        debugPrint(
          'Detected: ${faces.length}',
        );

        debugPrint(
          'Saved: $savedFaces',
        );

        debugPrint(
          'Matched existing people: '
          '$matchedFaces',
        );

        debugPrint(
          'New people created: '
          '$newPeopleCreated',
        );

        debugPrint(
          'Time: '
          '${stopwatch.elapsedMilliseconds} ms',
        );

        debugPrint(
          '====================================',
        );
      }

      return FaceProcessingResult(
        detectedFaces: faces.length,
        savedFaces: savedFaces,
        matchedFaces: matchedFaces,
        newPeopleCreated: newPeopleCreated,
        skipped: false,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          'Face processing failed for '
          '$memoryId: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }

      throw FaceProcessingException(
        'Unable to process faces: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Face preparation
  // ---------------------------------------------------------------------------

  Future<_PreparedFace> _prepareFaceForEmbedding({
    required ui.Image image,
    required NeuroLensDetectedFace face,
    required int faceIndex,
  }) async {
    if (face.hasFullAlignmentLandmarks) {
      try {
        final alignedBytes =
            await _faceAlignmentService.alignFace(
          image: image,
          face: face,
        );

        if (kDebugMode) {
          debugPrint(
            'Face $faceIndex: using 5-point alignment.',
          );
        }

        return _PreparedFace(
          bytes: alignedBytes,
          usedAlignment: true,
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'Face $faceIndex alignment failed: $error',
          );

          debugPrint(
            'Falling back to padded square crop.',
          );
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          'Face $faceIndex: alignment landmarks '
          'not available.',
        );

        debugPrint(
          'Falling back to padded square crop.',
        );
      }
    }

    final cropBytes = await _cropFace(
      image: image,
      face: face,
    );

    return _PreparedFace(
      bytes: cropBytes,
      usedAlignment: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Image loading
  // ---------------------------------------------------------------------------

  Future<Uint8List> _readImageBytes(
    String imagePath,
  ) async {
    final file = File(
      imagePath,
    );

    if (!await file.exists()) {
      throw FaceProcessingException(
        'Image file does not exist: $imagePath',
      );
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw const FaceProcessingException(
        'Image file is empty.',
      );
    }

    return bytes;
  }

  Future<ui.Image> _decodeImage(
    Uint8List bytes,
  ) async {
    if (bytes.isEmpty) {
      throw const FaceProcessingException(
        'Image is empty.',
      );
    }

    final codec = await ui.instantiateImageCodec(
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

  // ---------------------------------------------------------------------------
  // Fallback face cropping
  // ---------------------------------------------------------------------------

  Future<Uint8List> _cropFace({
    required ui.Image image,
    required NeuroLensDetectedFace face,
  }) async {
    final box = face.boundingBox;

    final paddingX =
        box.width * _facePaddingFactor;

    final paddingY =
        box.height * _facePaddingFactor;

    final left = math.max(
      0.0,
      box.left - paddingX,
    );

    final top = math.max(
      0.0,
      box.top - paddingY,
    );

    final right = math.min(
      image.width.toDouble(),
      box.right + paddingX,
    );

    final bottom = math.min(
      image.height.toDouble(),
      box.bottom + paddingY,
    );

    if (right <= left ||
        bottom <= top) {
      throw const FaceProcessingException(
        'Invalid detected face bounding box.',
      );
    }

    final sourceRect =
        ui.Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );

    final squareRect =
        _makeSquareRect(
      sourceRect,
      imageWidth:
          image.width.toDouble(),
      imageHeight:
          image.height.toDouble(),
    );

    if (squareRect.width <= 0 ||
        squareRect.height <= 0) {
      throw const FaceProcessingException(
        'Face crop has an invalid size.',
      );
    }

    final outputSize = math.max(
      1,
      squareRect.width.round(),
    );

    final recorder =
        ui.PictureRecorder();

    final canvas = ui.Canvas(
      recorder,
    );

    final destinationRect =
        ui.Rect.fromLTWH(
      0,
      0,
      outputSize.toDouble(),
      outputSize.toDouble(),
    );

    canvas.drawImageRect(
      image,
      squareRect,
      destinationRect,
      ui.Paint()
        ..filterQuality =
            ui.FilterQuality.high,
    );

    final picture =
        recorder.endRecording();

    final cropped =
        await picture.toImage(
      outputSize,
      outputSize,
    );

    picture.dispose();

    try {
      final data =
          await cropped.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (data == null) {
        throw const FaceProcessingException(
          'Failed to encode cropped face.',
        );
      }

      return data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    } finally {
      cropped.dispose();
    }
  }

  ui.Rect _makeSquareRect(
    ui.Rect rect, {
    required double imageWidth,
    required double imageHeight,
  }) {
    if (imageWidth <= 0 ||
        imageHeight <= 0) {
      throw const FaceProcessingException(
        'Image dimensions are invalid.',
      );
    }

    var size = math.max(
      rect.width,
      rect.height,
    );

    size = math.min(
      size,
      math.min(
        imageWidth,
        imageHeight,
      ),
    );

    final centerX =
        rect.center.dx;

    final centerY =
        rect.center.dy;

    var left =
        centerX - (size / 2);

    var top =
        centerY - (size / 2);

    left = left.clamp(
      0.0,
      math.max(
        0.0,
        imageWidth - size,
      ),
    );

    top = top.clamp(
      0.0,
      math.max(
        0.0,
        imageHeight - size,
      ),
    );

    return ui.Rect.fromLTWH(
      left,
      top,
      size,
      size,
    );
  }

  // ---------------------------------------------------------------------------
  // IDs
  // ---------------------------------------------------------------------------

  String _generateFaceId({
    required String memoryId,
    required int faceIndex,
  }) {
    final timestamp =
        DateTime.now()
            .microsecondsSinceEpoch;

    return 'face_${memoryId}_${faceIndex}_$timestamp';
  }

  String _generatePersonId({
    required String memoryId,
    required int faceIndex,
  }) {
    final timestamp =
        DateTime.now()
            .microsecondsSinceEpoch;

    return 'person_${memoryId}_${faceIndex}_$timestamp';
  }
}

class _PreparedFace {
  const _PreparedFace({
    required this.bytes,
    required this.usedAlignment,
  });

  final Uint8List bytes;
  final bool usedAlignment;
}

class FaceProcessingResult {
  const FaceProcessingResult({
    required this.detectedFaces,
    required this.savedFaces,
    required this.matchedFaces,
    required this.newPeopleCreated,
    required this.skipped,
  });

  final int detectedFaces;
  final int savedFaces;
  final int matchedFaces;
  final int newPeopleCreated;
  final bool skipped;

  bool get hasFaces =>
      detectedFaces > 0;
}

class FaceProcessingException
    implements Exception {
  const FaceProcessingException(
    this.message,
  );

  final String message;

  @override
  String toString() =>
      message;
}