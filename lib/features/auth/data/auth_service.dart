import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.sendEmailVerification();
        await user.reload();
      }

      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not create your account. Please try again.',
      );
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not sign in. Please try again.',
      );
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthServiceException(
        'You must be signed in to verify your email.',
      );
    }

    if (user.emailVerified) {
      return;
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not send the verification email.',
      );
    }
  }

  Future<bool> reloadAndCheckEmailVerification() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      await user.reload();

      return _firebaseAuth.currentUser?.emailVerified ?? false;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not refresh your verification status.',
      );
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not send the password reset email.',
      );
    }
  }

  Future<void> reauthenticate({
    required String password,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      throw const AuthServiceException(
        'You must be signed in to continue.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(
        credential,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not verify your identity.',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthServiceException(
        'You must be signed in to change your password.',
      );
    }

    try {
      await reauthenticate(
        password: currentPassword,
      );

      await user.updatePassword(
        newPassword,
      );
    } on AuthServiceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not change your password. Please try again.',
      );
    }
  }

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthServiceException(
        'You must be signed in to delete your account.',
      );
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw const AuthServiceException(
        'Could not delete your account. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      throw const AuthServiceException(
        'Could not sign out. Please try again.',
      );
    }
  }

  static String _messageForCode(String code) {
    return switch (code) {
      'invalid-email' =>
        'Enter a valid email address.',

      'user-disabled' =>
        'This account has been disabled.',

      'user-not-found' =>
        'No account exists with this email address.',

      'wrong-password' =>
        'The password is incorrect.',

      'invalid-credential' =>
        'The email or password is incorrect.',

      'email-already-in-use' =>
        'An account already exists with this email address.',

      'weak-password' =>
        'Use a stronger password with at least 6 characters.',

      'operation-not-allowed' =>
        'Email and password authentication is not enabled.',

      'too-many-requests' =>
        'Too many attempts. Please wait and try again.',

      'network-request-failed' =>
        'Check your internet connection and try again.',

      'missing-email' =>
        'Enter your email address.',

      'requires-recent-login' =>
        'For security, please enter your password again before continuing.',

      _ =>
        'Authentication failed. Please try again.',
    };
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}