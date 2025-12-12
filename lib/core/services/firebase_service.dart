import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../../firebase_options.dart';

class FirebaseService {
  static final _logger = Logger();

  /// Initialize Firebase with platform-specific configuration and Firestore offline support
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence for iOS and Android
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Web and some platforms don't support offline persistence configuration
      _logger.w('Firestore offline persistence not available on this platform: $e');
    }
  }
}
