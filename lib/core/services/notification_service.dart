import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../core/router/router.dart';
import '../../features/auth/data/repositories/user_profile_repository.dart';

/// Enum for notification types sent by Firebase Cloud Functions
enum NotificationType {
  groupInvite('group_invite'),
  splitCreated('split_created'),
  inviteAccepted('invite_accepted'),
  unknown('unknown');

  final String value;
  const NotificationType(this.value);

  factory NotificationType.fromString(String? type) {
    return values.firstWhere(
      (e) => e.value == type,
      orElse: () => NotificationType.unknown,
    );
  }
}

/// Handles Firebase Cloud Messaging (FCM) setup and notification display
class NotificationService {
  static final _logger = Logger();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'quicksplit_channel';
  static const String _channelName = 'QuickSplit Notifications';

  final FirebaseMessaging _fcm;
  final UserProfileRepository _profileRepository;

  NotificationService(this._fcm, this._profileRepository);

  /// Initialize FCM, request permissions, and setup handlers
  /// Must be called after user authentication with userId
  Future<void> initialize({
    required String userId,
    required Function(Map<String, dynamic>) onNotificationTap,
  }) async {
    try {
      await _initializeLocalNotifications();
      await _requestPermissions();
      await _setupTokenManagement(userId);
      _setupMessageHandlers(onNotificationTap);
      _logger.i('NotificationService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications plugin (for foreground display)
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iOSSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _handleNotificationTap,
      );

      _logger.d('Local notifications plugin initialized');
    } catch (e) {
      _logger.w('Error initializing local notifications: $e');
    }
  }

  /// Request notification permissions from user (iOS requires this)
  Future<void> _requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('Notification permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _logger.i('Provisional notification permission granted');
      } else {
        _logger.w('Notification permission denied by user');
      }
    } catch (e) {
      _logger.w('Error requesting notification permissions: $e');
    }
  }

  /// Get current FCM token and setup token refresh listener
  Future<void> _setupTokenManagement(String userId) async {
    try {
      // Get initial token
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToProfile(userId, token);
      }

      // Listen for token refresh (happens when app reinstalled, device rebooted, etc.)
      _fcm.onTokenRefresh.listen(
        (newToken) async {
          _logger.d('FCM token refreshed: $newToken');
          await _saveTokenToProfile(userId, newToken);
        },
        onError: (error) {
          _logger.e('Error listening to token refresh: $error');
        },
      );
    } catch (e) {
      _logger.e('Error setting up token management: $e');
    }
  }

  /// Save FCM token to user profile in Firestore
  Future<void> _saveTokenToProfile(String userId, String token) async {
    try {
      await _profileRepository.addFcmToken(userId, token);
      _logger.d('FCM token saved to profile: $token');
    } catch (e) {
      _logger.w('Error saving FCM token to profile: $e');
    }
  }

  /// Setup message handlers for foreground and background messages
  void _setupMessageHandlers(Function(Map<String, dynamic>) onNotificationTap) {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        _logger.d('Foreground message received: ${message.messageId}');
        _handleForegroundMessage(message);
      },
      onError: (error) {
        _logger.e('Error handling foreground message: $error');
      },
    );

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _logger.d(
          'Notification tapped from background/terminated: ${message.messageId}',
        );
        _handleNotificationTapFromApp(message, onNotificationTap);
      },
      onError: (error) {
        _logger.e('Error handling notification tap: $error');
      },
    );
  }

  /// Handle foreground messages by displaying local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? 'QuickSplit';
      final body = message.notification?.body ?? '';
      final payload = message.data;

      await _showLocalNotification(title: title, body: body, payload: payload);

      _logger.d('Foreground notification displayed');
    } catch (e) {
      _logger.e('Error handling foreground message: $e');
    }
  }

  /// Display local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Notifications for QuickSplit app activities',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _localNotifications.show(
        payload.hashCode,
        title,
        body,
        details,
        payload: jsonEncode(payload),
      );
    } catch (e) {
      _logger.e('Error showing local notification: $e');
    }
  }

  /// Handle notification response (when notification is tapped)
  static Future<void> _handleNotificationTap(
    NotificationResponse response,
  ) async {
    try {
      if (response.payload != null) {
        final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
        _logger.d('Notification payload: $payload');
        // Navigation will be handled by the app's notification handler
        // This is called from both foreground and background
      }
    } catch (e) {
      _logger.e('Error parsing notification payload: $e');
    }
  }

  /// Handle notification tap when coming from background/terminated app
  /// Routes to appropriate screen based on notification type
  void _handleNotificationTapFromApp(
    RemoteMessage message,
    Function(Map<String, dynamic>) onNotificationTap,
  ) {
    try {
      final payload = message.data;
      _logger.d('Handling notification tap with payload: $payload');

      // Extract notification type and route accordingly
      final notificationType = NotificationType.fromString(
        payload['type'] as String?,
      );

      _logger.i('Routing notification: ${notificationType.value}');

      // Call the onNotificationTap callback for custom handling
      onNotificationTap(payload);

      // Note: Actual navigation happens in the app layer (main.dart)
      // where the GoRouter context is available
    } catch (e) {
      _logger.e('Error handling notification tap from app: $e');
    }
  }

  /// Navigate based on notification type and data
  /// Call this from the app layer (main.dart) where GoRouter context is available
  /// Example usage:
  /// ```dart
  /// NotificationService.navigateToNotification(context, payload);
  /// ```
  static Future<void> navigateToNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    try {
      final notificationType = NotificationType.fromString(
        payload['type'] as String?,
      );

      _logger.i('Navigating to: ${notificationType.value}');

      switch (notificationType) {
        case NotificationType.groupInvite:
          final groupId = payload['groupId'] as String?;
          if (groupId != null && context.mounted) {
            context.pushNamed(
              RouteNames.groupsList,
              queryParameters: {'scrollToGroup': groupId},
            );
          }
          break;

        case NotificationType.splitCreated:
          final splitSessionId = payload['splitSessionId'] as String?;
          if (splitSessionId != null && context.mounted) {
            context.pushNamed(
              RouteNames.historyDetail,
              pathParameters: {'id': splitSessionId},
            );
          }
          break;

        case NotificationType.inviteAccepted:
          final groupId = payload['groupId'] as String?;
          if (groupId != null && context.mounted) {
            context.pushNamed(
              RouteNames.groupsList,
              queryParameters: {'scrollToGroup': groupId},
            );
          }
          break;

        case NotificationType.unknown:
          _logger.w('Unknown notification type, navigating to home');
          if (context.mounted) {
            context.goNamed(RouteNames.home);
          }
          break;
      }
    } catch (e) {
      _logger.e('Error navigating to notification target: $e');
    }
  }

  /// Remove FCM token from user profile (for logout)
  Future<void> removeToken({required String userId}) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _profileRepository.removeFcmToken(userId, token);
        _logger.d('FCM token removed from profile');
      }
    } catch (e) {
      _logger.w('Error removing FCM token: $e');
    }
  }
}

/// Background message handler - must be a top-level function
/// Called when app is in background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Log the background message (Firebase automatically initializes in background)
  final logger = Logger();
  logger.d('Background message received: ${message.messageId}');

  // You can add background processing here if needed
  // For now, we just log it - the user will see the notification in notification center
}
