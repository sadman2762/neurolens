import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:neurolens/features/memory/data/models/vision_metadata.dart';
import 'package:photo_manager/photo_manager.dart';

class VisionService {
  VisionService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl.replaceAll(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<VisionMetadata> analyzeAsset({required AssetEntity asset}) async {
    final imageBytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1280, 1280),
      quality: 85,
    );

    if (imageBytes == null || imageBytes.isEmpty) {
      throw const VisionServiceException('Could not load the selected image.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/vision/analyze'),
    );

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
          .timeout(const Duration(seconds: 60));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VisionServiceException(
          _extractErrorMessage(response.body, response.statusCode),
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
      throw VisionServiceException('Vision analysis failed: $error');
    }
  }

  void dispose() {
    _client.close();
  }

  static String _extractErrorMessage(String responseBody, int statusCode) {
    try {
      final decodedBody = jsonDecode(responseBody);

      if (decodedBody is Map<String, dynamic>) {
        final detail = decodedBody['detail'];

        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } on FormatException {
      // Use the fallback message below.
    }

    return 'Vision backend request failed with status $statusCode.';
  }
}

class VisionServiceException implements Exception {
  const VisionServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
