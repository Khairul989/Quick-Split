import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/permission_helper.dart';

/// State class for tracking permissions
class PermissionsState {
  final PermissionStatus cameraStatus;
  final PermissionStatus contactsStatus;
  final bool isLoading;
  final String? error;

  const PermissionsState({
    required this.cameraStatus,
    required this.contactsStatus,
    this.isLoading = false,
    this.error,
  });

  /// Create a copy with updated fields
  PermissionsState copyWith({
    PermissionStatus? cameraStatus,
    PermissionStatus? contactsStatus,
    bool? isLoading,
    String? error,
  }) {
    return PermissionsState(
      cameraStatus: cameraStatus ?? this.cameraStatus,
      contactsStatus: contactsStatus ?? this.contactsStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if both permissions are granted
  bool get allPermissionsGranted =>
      PermissionHelper.isGranted(cameraStatus) &&
      PermissionHelper.isGranted(contactsStatus);

  /// Check if camera permission is granted
  bool get cameraGranted => PermissionHelper.isGranted(cameraStatus);

  /// Check if contacts permission is granted
  bool get contactsGranted => PermissionHelper.isGranted(contactsStatus);
}

/// Notifier for managing permissions state
class PermissionsNotifier extends Notifier<PermissionsState> {
  @override
  PermissionsState build() {
    _initializePermissions();
    return const PermissionsState(
      cameraStatus: PermissionStatus.denied,
      contactsStatus: PermissionStatus.denied,
    );
  }

  /// Initialize and check current permission statuses
  Future<void> _initializePermissions() async {
    try {
      final cameraStatus = await PermissionHelper.checkPermission(AppPermission.camera);
      final contactsStatus = await PermissionHelper.checkPermission(AppPermission.contacts);

      state = state.copyWith(
        cameraStatus: cameraStatus,
        contactsStatus: contactsStatus,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to check permissions: $e',
      );
    }
  }

  /// Request camera permission
  Future<void> requestCameraPermission() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final status = await PermissionHelper.requestPermission(AppPermission.camera);
      state = state.copyWith(
        cameraStatus: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request camera permission: $e',
      );
    }
  }

  /// Request contacts permission
  Future<void> requestContactsPermission() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final status = await PermissionHelper.requestPermission(AppPermission.contacts);
      state = state.copyWith(
        contactsStatus: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request contacts permission: $e',
      );
    }
  }

  /// Open app settings to manually grant permissions
  Future<void> openSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await PermissionHelper.openAppSettings();

      // Wait a moment for user to return from settings
      await Future.delayed(const Duration(milliseconds: 500));

      // Recheck permissions when user returns from settings
      await _initializePermissions();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open app settings: $e',
      );
    }
  }

  /// Refresh permission statuses
  Future<void> refreshPermissions() async {
    await _initializePermissions();
  }
}

/// Provider for permissions state management
final permissionsProvider = NotifierProvider<PermissionsNotifier, PermissionsState>(
  PermissionsNotifier.new,
);
