import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AccountService {
  AccountService({
    required String baseUrl,
    FirebaseAuth? firebaseAuth,
    http.Client? client,
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/$'), ''),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _client = client ?? http.Client();

  final String _baseUrl;
  final FirebaseAuth _firebaseAuth;
  final http.Client _client;

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AccountServiceException(
        'You must be signed in to delete your account.',
      );
    }

    final idToken = await user.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      throw const AccountServiceException(
        'Could not authenticate the account-deletion request.',
      );
    }

    try {
      final response = await _client
          .delete(
            Uri.parse('$_baseUrl/api/v1/account'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AccountServiceException(
          _extractErrorMessage(response.body, response.statusCode),
        );
      }
      await _firebaseAuth.signOut();
    } on AccountServiceException {
      rethrow;
    } on Exception catch (error) {
      throw AccountServiceException('Could not delete your account: $error');
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

    return switch (statusCode) {
      401 => 'Your session has expired. Please sign in again.',
      404 => 'Your account could not be found.',
      500 => 'The server could not delete your account.',
      _ => 'Account deletion failed with status $statusCode.',
    };
  }
}

class AccountServiceException implements Exception {
  const AccountServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
