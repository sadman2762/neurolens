import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ImageEditApiService {
  ImageEditApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const String _baseUrl =
      'https://neurolens-1lnq.onrender.com';

  final http.Client _client;

  Future<Uint8List> removeObject({
    required Uint8List imageBytes,
    required Uint8List maskBytes,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/image-edit/remove-object',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image.jpg',
        contentType: MediaType(
          'image',
          'jpeg',
        ),
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'mask',
        maskBytes,
        filename: 'mask.png',
        contentType: MediaType(
          'image',
          'png',
        ),
      ),
    );

    final streamedResponse = await _client
        .send(
          request,
        )
        .timeout(
          const Duration(
            minutes: 3,
          ),
        );

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      throw ImageEditException(
        'Server returned ${response.statusCode}.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(
        response.body,
      );
    } on FormatException {
      throw const ImageEditException(
        'Invalid response from NeuroLens API.',
      );
    }

    if (decoded
        is! Map<String, dynamic>) {
      throw const ImageEditException(
        'Invalid response from NeuroLens API.',
      );
    }

    final success =
        decoded['success'] == true;

    if (!success) {
      final message =
          decoded['message']
              ?.toString();

      throw ImageEditException(
        message?.isNotEmpty == true
            ? message!
            : 'AI object removal failed.',
      );
    }

    final base64Image =
        decoded['edited_image_base64']
            ?.toString();

    if (base64Image == null ||
        base64Image.isEmpty) {
      throw const ImageEditException(
        'The AI service returned no edited image.',
      );
    }

    try {
      return base64Decode(
        base64Image,
      );
    } on FormatException {
      throw const ImageEditException(
        'The edited image returned by the server is invalid.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ImageEditException
    implements Exception {
  const ImageEditException(
    this.message,
  );

  final String message;

  @override
  String toString() {
    return message;
  }
}