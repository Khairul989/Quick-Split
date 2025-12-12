import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/core/services/data_migration_service.dart';

import '../../data/models/auth_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_profile_repository.dart';

/// Provider for AuthRepository instance
/// Manages authentication operations and state
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(firebase_auth.FirebaseAuth.instance);
});

/// Provider for UserProfileRepository instance
/// Manages user profile data access to both Firestore and Hive
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(
    FirebaseFirestore.instance,
    Hive.box('preferences'),
  );
});

/// Provider for DataMigrationService instance
/// Handles migration of local Hive profiles to Firestore
final dataMigrationServiceProvider = Provider<DataMigrationService>((ref) {
  final profileRepository = ref.watch(userProfileRepositoryProvider);
  return DataMigrationService(profileRepository);
});

/// Stream provider that watches authentication state changes
/// Emits AuthUser when user is authenticated, null when signed out
///
/// This provider:
/// - Listens to Firebase auth state changes in real-time
/// - Automatically converts FirebaseUser to AuthUser model
/// - Emits null when user signs out
/// - Maintains subscription until provider is disposed
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// authState.when(
///   data: (user) => user != null ? AuthenticatedUI() : UnauthenticatedUI(),
///   loading: () => LoadingUI(),
///   error: (err, stack) => ErrorUI(),
/// );
/// ```
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Synchronous provider for current user
/// Derives from authStateProvider but provides sync access
///
/// Returns the last emitted AuthUser or null
/// Use this when you need synchronous access without async handling
///
/// Warning: Will be null during async operations; use authStateProvider
/// for reliable state tracking
final currentUserProvider = Provider<AuthUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user).value;
});

/// Represents the state of async auth operations
/// Tracks loading and error states for authentication methods
class AuthOperationState {
  /// Current async value tracking operation state
  final AsyncValue<void> value;

  /// Whether an operation is currently in progress
  bool get isLoading => value.isLoading;

  /// Error from last failed operation, if any
  Object? get error => value
      .whenData((_) => null)
      .maybeWhen(error: (e, _) => e, orElse: () => null);

  const AuthOperationState({required this.value});

  /// Initial state with no operation
  static const initial = AuthOperationState(value: AsyncValue.data(null));
}

/// Notifier that manages auth operations (sign in, sign up, sign out)
/// Tracks loading and error states for async authentication operations
///
/// Riverpod 3.0 pattern using Notifier instead of StateNotifier
class AuthNotifier extends Notifier<AsyncValue<void>> {
  late final AuthRepository _authRepository;

  @override
  AsyncValue<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const AsyncValue.data(null);
  }

  /// Sign in with email and password
  ///
  /// Updates state to loading while processing
  /// Completes state to data(null) on success or error on failure
  /// Migrates local profile to Firestore on successful authentication
  ///
  /// Throws [AuthException] if sign in fails (error available in state)
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signInWithEmail(email, password);
      // Migrate local profile if exists
      final migrationService = ref.read(dataMigrationServiceProvider);
      await migrationService.migrateLocalProfileToFirestore(user.uid);
    });
  }

  /// Sign in with Google OAuth credential
  ///
  /// Called by UI layer after obtaining Google credential via GoogleSignIn
  /// Exchanges credential for Firebase authentication
  /// Migrates local profile to Firestore on successful authentication
  ///
  /// Parameters:
  ///   - googleCredential: Firebase AuthCredential from Google Sign-In
  ///
  /// Throws [AuthException] if sign in fails (error available in state)
  Future<void> signInWithGoogleCredential(
    firebase_auth.AuthCredential googleCredential,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signInWithGoogleCredential(
        googleCredential,
      );
      // Migrate local profile if exists
      final migrationService = ref.read(dataMigrationServiceProvider);
      await migrationService.migrateLocalProfileToFirestore(user.uid);
    });
  }

  /// Sign in with Apple OAuth
  ///
  /// Handles Apple Sign-In flow and Firebase credential exchange
  /// iOS/macOS only - platform exception thrown on Android
  /// Updates state to loading while processing
  /// Migrates local profile to Firestore on successful authentication
  ///
  /// Throws [AuthException] if sign in fails (error available in state)
  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signInWithApple();
      // Migrate local profile if exists
      final migrationService = ref.read(dataMigrationServiceProvider);
      await migrationService.migrateLocalProfileToFirestore(user.uid);
    });
  }

  /// Register new user with email and password
  ///
  /// Creates new Firebase account and updates display name
  /// Updates state to loading while processing
  /// Migrates local profile to Firestore on successful authentication
  ///
  /// Parameters:
  ///   - email: User email address (trimmed before use)
  ///   - password: User password (minimum 6 characters recommended)
  ///   - name: User display name
  ///
  /// Throws [AuthException] if registration fails (error available in state)
  /// Common errors:
  ///   - 'email-already-in-use': Account exists with this email
  ///   - 'weak-password': Password too short or weak
  ///   - 'invalid-email': Email format invalid
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );
      // Migrate local profile if exists
      final migrationService = ref.read(dataMigrationServiceProvider);
      await migrationService.migrateLocalProfileToFirestore(user.uid);
    });
  }

  /// Send password reset email
  ///
  /// Sends password reset link to provided email address
  /// Updates state to loading while processing
  ///
  /// Parameters:
  ///   - email: Email address to send reset link to
  ///
  /// Throws [AuthException] if email send fails (error available in state)
  /// Note: Completes successfully even if email not found (security)
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.sendPasswordResetEmail(email);
    });
  }

  /// Sign out current user
  ///
  /// Signs out from Firebase and all OAuth providers
  /// Updates state to loading while processing
  /// Completes silently even if errors occur (user likely already signed out)
  ///
  /// After sign out, authStateProvider will emit null
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
    });
  }

  /// Reset state to initial value
  ///
  /// Clears any loading or error state
  /// Useful after handling errors or between operations
  void resetState() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for AuthNotifier
///
/// Creates and manages AuthNotifier instance
/// Automatically disposes listeners and subscriptions
///
/// Usage:
/// ```dart
/// final authNotifier = ref.read(authProvider.notifier);
/// await authNotifier.signInWithEmail(email, password);
///
/// // Watch state changes
/// final state = ref.watch(authProvider);
/// state.when(
///   data: (_) => SuccessUI(),
///   loading: () => LoadingUI(),
///   error: (error, _) => ErrorUI(error),
/// );
/// ```
final authProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(
  () => AuthNotifier(),
);
