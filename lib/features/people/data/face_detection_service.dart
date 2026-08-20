import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class NeuroLensDetectedFace {
  const NeuroLensDetectedFace({
    required this.boundingBox,
    required this.headEulerAngleX,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.smilingProbability,
    required this.leftEye,
    required this.rightEye,
    required this.noseBase,
    required this.leftMouth,
    required this.rightMouth,
    required this.bottomMouth,
  });

  final Rect boundingBox;

  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;

  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smilingProbability;

  final Offset? leftEye;
  final Offset? rightEye;
  final Offset? noseBase;
  final Offset? leftMouth;
  final Offset? rightMouth;
  final Offset? bottomMouth;

  bool get hasAlignmentLandmarks =>
      leftEye != null &&
      rightEye != null &&
      noseBase != null;

  bool get hasFullAlignmentLandmarks =>
      leftEye != null &&
      rightEye != null &&
      noseBase != null &&
      leftMouth != null &&
      rightMouth != null;
}

class FaceDetectionService {
  FaceDetectionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: true,
            enableContours: false,
            enableTracking: false,
            performanceMode: FaceDetectorMode.accurate,
            minFaceSize: 0.1,
          ),
        );

  final FaceDetector _faceDetector;

  Future<List<NeuroLensDetectedFace>> detectFacesFromPath(
    String imagePath,
  ) async {
    final inputImage = InputImage.fromFilePath(
      imagePath,
    );

    final faces = await _faceDetector.processImage(
      inputImage,
    );

    return faces
        .map(
          (face) => NeuroLensDetectedFace(
            boundingBox: face.boundingBox,
            headEulerAngleX: face.headEulerAngleX,
            headEulerAngleY: face.headEulerAngleY,
            headEulerAngleZ: face.headEulerAngleZ,
            leftEyeOpenProbability:
                face.leftEyeOpenProbability,
            rightEyeOpenProbability:
                face.rightEyeOpenProbability,
            smilingProbability:
                face.smilingProbability,
            leftEye: _landmarkPosition(
              face,
              FaceLandmarkType.leftEye,
            ),
            rightEye: _landmarkPosition(
              face,
              FaceLandmarkType.rightEye,
            ),
            noseBase: _landmarkPosition(
              face,
              FaceLandmarkType.noseBase,
            ),
            leftMouth: _landmarkPosition(
              face,
              FaceLandmarkType.leftMouth,
            ),
            rightMouth: _landmarkPosition(
              face,
              FaceLandmarkType.rightMouth,
            ),
            bottomMouth: _landmarkPosition(
              face,
              FaceLandmarkType.bottomMouth,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  Offset? _landmarkPosition(
    Face face,
    FaceLandmarkType type,
  ) {
    final landmark = face.landmarks[type];

    if (landmark == null) {
      return null;
    }

    return Offset(
      landmark.position.x.toDouble(),
      landmark.position.y.toDouble(),
    );
  }

  Future<int> countFacesFromPath(
    String imagePath,
  ) async {
    final faces = await detectFacesFromPath(
      imagePath,
    );

    return faces.length;
  }

  Future<bool> containsFace(
    String imagePath,
  ) async {
    return (await countFacesFromPath(imagePath)) > 0;
  }

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}