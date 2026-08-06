import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:neurolens/features/memory/data/models/vision_metadata.dart';
import 'package:photo_manager/photo_manager.dart';

class VisionService {
  VisionService({
    required String baseUrl,
    FirebaseAuth? firebaseAuth,
    http.Client? client,
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/$'), ''),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _client = client ?? http.Client();

  final String _baseUrl;
  final FirebaseAuth _firebaseAuth;
  final http.Client _client;

  Future<VisionMetadata> analyzeAsset({
    required AssetEntity asset,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const VisionServiceException(
        'You must be signed in to use AI image analysis.',
      );
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw const VisionServiceException(
        'Could not create an authentication token.',
      );
    }

    final imageBytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1280, 1280),
      quality: 85,
    );

    if (imageBytes == null || imageBytes.isEmpty) {
      throw const VisionServiceException(
        'Could not load the selected image.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/vision/analyze'),
    );

    request.headers['Authorization'] = 'Bearer $idToken';
    request.headers['X-Request-ID'] = _createRequestId();

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: '${asset.id}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 90));

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VisionServiceException(
          _extractErrorMessage(
            response.body,
            response.statusCode,
          ),
        );
      }

      final decodedBody = jsonDecode(response.body);

      if (decodedBody is! Map<String, dynamic>) {
        throw const VisionServiceException(
          'The vision backend returned an invalid response.',
        );
      }

      return VisionMetadata.fromJson(decodedBody);
    } on VisionServiceException {
      rethrow;
    } on FormatException {
      throw const VisionServiceException(
        'The vision backend returned invalid JSON.',
      );
    } on Exception catch (error) {
      throw VisionServiceException(
        'Vision analysis failed: $error',
      );
    }
  }

  void dispose() {
    _client.close();
  }

  static String _createRequestId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random.secure().nextInt(1 << 32);

    return '$timestamp-$random';
  }

  static String _extractErrorMessage(
    String responseBody,
    int statusCode,
  ) {
    try {
      final decodedBody = jsonDecode(responseBody);

      if (decodedBody is Map<String, dynamic>) {
        final detail = decodedBody['detail'];

        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } on FormatException {
      // Use one of the fallback messages below.
    }

    return switch (statusCode) {
      400 => 'The AI request was invalid.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have enough AI credits.',
      409 => 'This AI request has already been submitted.',
      413 => 'The selected image is too large.',
      429 => 'Too many AI requests. Please try again shortly.',
      _ => 'Vision backend request failed with status $statusCode.',
    };
  }
}

class VisionServiceException implements Exception {
  const VisionServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}