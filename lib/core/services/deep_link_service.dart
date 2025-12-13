import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';

typedef DeepLinkCallback = Future<void> Function(Uri uri);

/// Service for handling deep links in the app
/// Manages incoming links from various sources:
/// - Direct app deep links (quicksplit://invite/ABC123)
/// - HTTP/HTTPS links (https://quicksplit.app/invite/ABC123)
/// - App launch from links
class DeepLinkService {
  static final _logger = Logger();

  final AppLinks _appLinks = AppLinks();
  DeepLinkCallback? _callback;

  /// Generate a deep link for an invite code
  /// Uses custom scheme for app-only handling
  String generateInviteLink(String inviteCode) {
    return 'quicksplit://invite/$inviteCode';
  }

  /// Generate an HTTP deep link for sharing
  /// This would typically be configured via Firebase Dynamic Links or similar
  String generateHttpInviteLink(String inviteCode) {
    return 'https://quicksplit.app/invite/$inviteCode';
  }

  /// Initialize the deep link listener
  /// Must be called once in main() or during app initialization
  /// Handles both app launch via deep link and links while app is running
  Future<void> initialize(DeepLinkCallback callback) async {
    try {
      _callback = callback;

      // Handle app launch via deep link
      try {
        final initialLink = await _appLinks.getInitialAppLink();
        if (initialLink != null) {
          _logger.d('App launched with deep link: $initialLink');
          _handleDeepLink(initialLink);
        }
      } catch (e) {
        _logger.d('No initial deep link or error retrieving it: $e');
      }

      // Listen for deep links while app is running
      _appLinks.uriLinkStream.listen(
        (uri) {
          _logger.d('Received deep link while app running: $uri');
          _handleDeepLink(uri);
        },
        onError: (error) {
          _logger.e('Error listening to deep links: $error');
        },
      );

      _logger.d('Deep link service initialized');
    } catch (e) {
      _logger.e('Error initializing deep link service: $e');
      rethrow;
    }
  }

  /// Handle incoming deep link
  /// Extracts the invite code and calls the registered callback
  Future<void> _handleDeepLink(Uri uri) async {
    try {
      _logger.d('Handling deep link: $uri');

      // Handle quicksplit:// scheme
      if (uri.scheme == 'quicksplit') {
        if (uri.host == 'invite' && uri.pathSegments.isNotEmpty) {
          final code = uri.pathSegments.first;
          _logger.d('Extracted invite code from custom scheme: $code');
          if (_callback != null) {
            await _callback!(uri);
          }
        }
      }
      // Handle https:// scheme (from HTTP links)
      else if (uri.scheme == 'https' || uri.scheme == 'http') {
        // Handle https://quicksplit.app/invite/{code}
        if (uri.host.contains('quicksplit') && uri.pathSegments.length >= 2) {
          if (uri.pathSegments[0] == 'invite') {
            final code = uri.pathSegments[1];
            _logger.d('Extracted invite code from HTTP link: $code');
            if (_callback != null) {
              await _callback!(uri);
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error handling deep link: $e');
    }
  }

  /// Extract invite code from a URI
  /// Returns the code if found, otherwise null
  String? extractInviteCode(Uri uri) {
    try {
      // Handle quicksplit:// scheme
      if (uri.scheme == 'quicksplit') {
        if (uri.host == 'invite' && uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.first;
        }
      }
      // Handle https:// scheme
      else if (uri.scheme == 'https' || uri.scheme == 'http') {
        if (uri.host.contains('quicksplit') && uri.pathSegments.length >= 2) {
          if (uri.pathSegments[0] == 'invite') {
            return uri.pathSegments[1];
          }
        }
      }
    } catch (e) {
      _logger.e('Error extracting invite code: $e');
    }
    return null;
  }

  /// Check if a URI is an invite link
  bool isInviteLink(Uri uri) {
    return extractInviteCode(uri) != null;
  }

  /// Dispose resources
  void dispose() {
    _callback = null;
    _logger.d('Deep link service disposed');
  }
}
