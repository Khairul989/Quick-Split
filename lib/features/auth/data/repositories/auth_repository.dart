import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logger/logger.dart';
import '../models/auth_user.dart';

/// Exception class for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthRepository {
  static final _logger = Logger();

  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthRepository(this._firebaseAuth);

  /// Listen to authentication state changes
  /// Emits AuthUser when authenticated, null when signed out
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null
        ? AuthUser.fromFirebaseUser(firebaseUser)
        : null;
    });
  }

  /// Get current authenticated user synchronously
  /// Returns null if no user is signed in
  AuthUser? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null
      ? AuthUser.fromFirebaseUser(firebaseUser)
      : null;
  }

  /// Sign in with email and password
  /// Throws [AuthException] with user-friendly message on failure
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Sign in failed - no user returned');
      }

      return AuthUser.fromFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }

  /// Sign in with Google OAuth using Firebase credential
  /// The UI/provider layer is responsible for obtaining the Google credential
  /// Throws [AuthException] with user-friendly message on failure
  Future<AuthUser> signInWithGoogleCredential(
    firebase_auth.AuthCredential googleCredential,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(googleCredential);

      if (userCredential.user == null) {
        throw AuthException('Google Sign-In failed - no user returned');
      }

      return AuthUser.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  /// Sign in with Apple OAuth (iOS/macOS only)
  /// Throws [AuthException] with user-friendly message on failure
  Future<AuthUser> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        throw AuthException('Apple Sign-In failed - no user returned');
      }

      // Update display name if provided by Apple and Firebase name is empty
      if (userCredential.user!.displayName == null &&
          (appleCredential.givenName != null || appleCredential.familyName != null)) {
        final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await userCredential.user!.updateDisplayName(displayName);
          await userCredential.user!.reload();
        }
      }

      return AuthUser.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Apple Sign-In failed: $e');
    }
  }

  /// Register a new user with email and password
  /// Throws [AuthException] with user-friendly message on failure
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Registration failed - no user returned');
      }

      // Update display name
      await credential.user!.updateDisplayName(name);
      await credential.user!.reload();

      final updatedUser = _firebaseAuth.currentUser;
      if (updatedUser == null) {
        throw AuthException('Failed to retrieve user after registration');
      }

      return AuthUser.fromFirebaseUser(updatedUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  /// Send password reset email to the given email address
  /// Throws [AuthException] with user-friendly message on failure
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Failed to send reset email: $e');
    }
  }

  /// Update user profile information
  /// Throws [AuthException] with user-friendly message on failure
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  /// Sign out current user from Firebase
  /// UI/provider layer is responsible for signing out from Google/Apple separately
  /// Completes silently even if errors occur
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      _logger.w('Error during Firebase sign out: $e');
      // Silently fail - user is likely already signed out
    }
  }

  /// Convert Firebase Auth exceptions to user-friendly AuthExceptions
  AuthException _handleAuthException(firebase_auth.FirebaseAuthException e) {
    final userMessage = switch (e.code) {
      'user-not-found' => 'No account found with this email',
      'wrong-password' => 'Incorrect password',
      'email-already-in-use' => 'An account already exists with this email',
      'weak-password' => 'Password is too weak. Use at least 6 characters',
      'invalid-email' => 'Invalid email address',
      'user-disabled' => 'This account has been disabled',
      'too-many-requests' => 'Too many failed attempts. Please try again later',
      'operation-not-allowed' => 'This sign-in method is not enabled',
      'network-request-failed' => 'Network error. Please check your internet connection',
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method',
      'invalid-credential' => 'Invalid credentials. Please try again',
      'invalid-verification-code' => 'Invalid verification code',
      'session-expired' => 'Your session expired. Please sign in again',
      _ => e.message ?? 'Authentication failed. Please try again'
    };

    return AuthException(userMessage, code: e.code);
  }
}
