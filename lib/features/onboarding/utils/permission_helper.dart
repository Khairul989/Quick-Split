import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission {
  camera,
  contacts,
}

/// Helper class for managing app permissions
class PermissionHelper {
  /// Check current status of a permission
  static Future<PermissionStatus> checkPermission(AppPermission permission) async {
    switch (permission) {
      case AppPermission.camera:
        return await Permission.camera.status;
      case AppPermission.contacts:
        return await Permission.contacts.status;
    }
  }

  /// Request a permission
  static Future<PermissionStatus> requestPermission(AppPermission permission) async {
    switch (permission) {
      case AppPermission.camera:
        return await Permission.camera.request();
      case AppPermission.contacts:
        return await Permission.contacts.request();
    }
  }

  /// Open app settings for user to manually grant permissions
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Get rationale text for permission
  static String getPermissionRationale(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return "Camera access is needed to scan receipts using OCR technology.";
      case AppPermission.contacts:
        return "Contacts access allows you to quickly add friends to groups.";
    }
  }

  /// Get permission title
  static String getPermissionTitle(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return "Camera Access";
      case AppPermission.contacts:
        return "Contacts Access";
    }
  }

  /// Get permission icon
  static IconData getPermissionIcon(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return Icons.camera_alt;
      case AppPermission.contacts:
        return Icons.contacts;
    }
  }

  /// Check if permission status is granted
  static bool isGranted(PermissionStatus status) {
    return status.isGranted;
  }

  /// Check if permission status is denied
  static bool isDenied(PermissionStatus status) {
    return status.isDenied;
  }

  /// Check if permission status is permanently denied (needs manual settings)
  static bool isPermanentlyDenied(PermissionStatus status) {
    return status.isPermanentlyDenied;
  }
}
