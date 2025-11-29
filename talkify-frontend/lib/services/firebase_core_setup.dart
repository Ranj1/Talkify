import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Firebase Core Setup Service
/// Handles Firebase initialization and configuration
class FirebaseCoreSetup {
  static bool _isInitialized = false;

  /// Initialize Firebase Core
  /// Call this method in main() before runApp()
  // static Future<void> initializeFirebase() async {
  //   try {
  //     // Check if Firebase is already initialized by checking apps
  //     final apps = Firebase.apps;
  //     if (apps.isNotEmpty) {
  //       print('✅ Firebase already initialized with ${apps.length} app(s)');
  //       _isInitialized = true;
  //       return;
  //     }
  //
  //     if (!_isInitialized) {
  //       // Initialize Firebase with configuration
  //       await Firebase.initializeApp(
  //         options: DefaultFirebaseOptions.currentPlatform,
  //       );
  //
  //       _isInitialized = true;
  //       print('✅ Firebase initialized successfully');
  //     } else {
  //       print('✅ Firebase already initialized (cached)');
  //     }
  //   } catch (e) {
  //     print('❌ Firebase initialization failed: $e');
  //     // Handle specific Firebase errors
  //     if (e.toString().contains('duplicate-app')) {
  //       print('⚠️ Firebase app already exists, continuing...');
  //       _isInitialized = true;
  //     } else {
  //       // For other errors, don't rethrow to prevent app crash
  //       print('⚠️ Continuing without Firebase initialization');
  //       _isInitialized = false;
  //     }
  //   }
  // }


  static Future<void> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized successfully');
        _isInitialized = true;
      } else {
        print('✅ Firebase already initialized with ${Firebase.apps.length} app(s)');
        _isInitialized = true;
      }
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      // Handle duplicate app error specifically
      if (e.toString().contains('duplicate-app')) {
        print('⚠️ Firebase app already exists, marking as initialized');
        _isInitialized = true;
      } else {
        print('⚠️ Continuing without Firebase initialization');
        _isInitialized = false;
      }
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;

  /// Wait for Firebase to be initialized
  /// Returns true if initialized, false if timeout
  static Future<bool> waitForInitialization({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isInitialized) return true;
    
    final stopwatch = Stopwatch()..start();
    while (!_isInitialized && stopwatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return _isInitialized;
  }

  /// Get Firebase app instance
  /// Returns null if not initialized
  static FirebaseApp? get firebaseApp {
    if (_isInitialized) {
      return Firebase.app();
    }
    return null;
  }

  /// Reset Firebase initialization (for testing)
  static void reset() {
    _isInitialized = false;
  }
}
