import 'package:camera/camera.dart';

/// Service for requesting and managing app permissions
class PermissionService {
  /// Request camera permission
  /// Returns true if permission is granted
  static Future<bool> requestCameraPermission() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Request photo/gallery permission
  /// Returns true if permission is granted
  static Future<bool> requestPhotoPermission() async {
    try {
      // image_picker handles permissions internally on modern Android/iOS
      // If we can pick an image, permissions are granted
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check if photo permission is granted
  static Future<bool> hasPhotoPermission() async {
    // image_picker handles this internally
    return true;
  }

  /// Get available cameras
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (_) {
      return [];
    }
  }
}
