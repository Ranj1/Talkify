import 'dart:io';
import 'package:get/get.dart';
import '../services/firebase_notification_service.dart';
import '../services/api_service.dart';
import '../services/firebase_core_setup.dart';

class NotificationController extends GetxController {
  // Reactive variables for state management
  final RxBool isNotificationPermissionGranted = false.obs;
  final RxString fcmToken = ''.obs;
  final RxBool isTokenSentToBackend = false.obs;
  final RxBool isLoadingNotifications = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Delay Firebase initialization to avoid conflicts
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeNotifications();
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Controller is ready
    // Start listening to notifications
    _startListeningToNotifications();
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }

  /// Initialize Firebase notifications
  void _initializeNotifications() async {
    try {
      // Wait for Firebase to be properly initialized
      print('⏳ Waiting for Firebase initialization...');
      final isFirebaseReady = await FirebaseCoreSetup.waitForInitialization();
      
      if (!isFirebaseReady) {
        print('❌ Firebase initialization timeout, skipping notification setup');
        return;
      }

      print('✅ Firebase is initialized, proceeding with notification setup');
      isLoadingNotifications.value = true;
      
      // Initialize FCM
      FirebaseNotificationService.initializeFCM();
      
      // Request permission
      requestNotificationPermission();
      
      // Get FCM token
      getFcmToken();
      
    } catch (e) {
      errorMessage.value = 'Failed to initialize notifications: $e';
      print('❌ Notification initialization error: $e');
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  /// Start listening to notifications
  void _startListeningToNotifications() {
    try {
      // Listen to foreground notifications
      FirebaseNotificationService.listenToForegroundNotifications();
      
      // Listen to background notifications
      FirebaseNotificationService.listenToBackgroundNotifications();
      
      print('👂 Started listening to notifications');
      
    } catch (e) {
      errorMessage.value = 'Failed to start listening to notifications: $e';
      print('❌ Error starting notification listeners: $e');
    }
  }

  /// Request notification permission from user
  void requestNotificationPermission() async {
    try {
      isLoadingNotifications.value = true;
      clearError();
      
      // Check current permission status first
      final currentStatus = await FirebaseNotificationService.getNotificationPermissionStatus();
      if (currentStatus == 'granted') {
        print('✅ Notification permission already granted');
        isNotificationPermissionGranted.value = true;
        getFcmToken();
        return;
      }
      
      final granted = await FirebaseNotificationService.requestNotificationPermission();
      isNotificationPermissionGranted.value = granted;
      
      if (granted) {
        _showSuccessSnackBar('Notification permission granted');
        // Wait a bit for permission to be processed, then get FCM token
        Future.delayed(const Duration(seconds: 1), () {
          getFcmToken();
        });
      } else {
        print('❌ Notification permission denied by user');
        _showErrorSnackBar('Notification permission denied');
      }
      
    } catch (e) {
      errorMessage.value = 'Error requesting notification permission: $e';
      print('❌ Error requesting notification permission: $e');
      _showErrorSnackBar('Failed to request notification permission');
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  /// Get FCM token for current device
  void getFcmToken() async {
    try {
      isLoadingNotifications.value = true;
      clearError();
      
      // Wait a bit for APNS token to be available on iOS
      if (Platform.isIOS) {
        await Future.delayed(const Duration(seconds: 3));
      }
      
      final token = await FirebaseNotificationService.getFCMToken();
      
      if (token != null && token.isNotEmpty) {
        fcmToken.value = token;
        print('✅ FCM token obtained: $token');
        
        // Send token to backend via API service
        await ApiService.sendFcmToken(token);
        
      } else {
        errorMessage.value = 'Failed to get FCM token - APNS token may not be ready';
        print('⚠️ FCM token not available, will retry later');
        // Don't show error snackbar immediately, retry later
        _retryGetFcmToken();
      }
      
    } catch (e) {
      errorMessage.value = 'Error getting FCM token: $e';
      print('❌ Error getting FCM token: $e');
      // Don't show error snackbar for APNS token issues
      if (!e.toString().contains('apns-token-not-set')) {
        _showErrorSnackBar('Failed to get FCM token');
      } else {
        // Retry later for APNS token issues
        _retryGetFcmToken();
      }
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  /// Retry getting FCM token after a delay
  void _retryGetFcmToken() {
    Future.delayed(const Duration(seconds: 5), () {
      if (fcmToken.value.isEmpty) {
        print('🔄 Retrying FCM token retrieval...');
        getFcmToken();
      }
    });
  }

  /// Send FCM token to backend
  /// [userId] - User ID from your backend
  void sendTokenToBackend(String userId) async {
    try {
      if (fcmToken.value.isEmpty) {
        _showErrorSnackBar('No FCM token available');
        return;
      }
      
      isLoadingNotifications.value = true;
      clearError();
      
      final success = await FirebaseNotificationService.sendTokenToBackend(
        userId,
        fcmToken.value,
      );
      
      if (success) {
        isTokenSentToBackend.value = true;
        _showSuccessSnackBar('FCM token sent to backend successfully');
      } else {
        _showErrorSnackBar('Failed to send FCM token to backend');
      }
      
    } catch (e) {
      errorMessage.value = 'Error sending FCM token to backend: $e';
      _showErrorSnackBar('Failed to send FCM token to backend');
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  /// Subscribe to topic for group notifications
  /// [topic] - Topic name (e.g., 'calls', 'messages')
  void subscribeToTopic(String topic) async {
    try {
      isLoadingNotifications.value = true;
      clearError();
      
      final success = await FirebaseNotificationService.subscribeToTopic(topic);
      
      if (success) {
        _showSuccessSnackBar('Subscribed to $topic notifications');
      } else {
        _showErrorSnackBar('Failed to subscribe to $topic notifications');
      }
      
    } catch (e) {
      errorMessage.value = 'Error subscribing to topic: $e';
      _showErrorSnackBar('Failed to subscribe to topic');
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  /// Unsubscribe from topic
  /// [topic] - Topic name to unsubscribe from
  void unsubscribeFromTopic(String topic) async {
    try {
      isLoadingNotifications.value = true;
      clearError();
      
      final success = await FirebaseNotificationService.unsubscribeFromTopic(topic);
      
      if (success) {
        _showSuccessSnackBar('Unsubscribed from $topic notifications');
      } else {
        _showErrorSnackBar('Failed to unsubscribe from $topic notifications');
      }
      
    } catch (e) {
      errorMessage.value = 'Error unsubscribing from topic: $e';
      _showErrorSnackBar('Failed to unsubscribe from topic');
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  /// Clear all notifications
  void clearAllNotifications() async {
    try {
      await FirebaseNotificationService.clearAllNotifications();
      _showSuccessSnackBar('All notifications cleared');
      
    } catch (e) {
      errorMessage.value = 'Error clearing notifications: $e';
      _showErrorSnackBar('Failed to clear notifications');
    }
  }

  /// Clear error messages
  void clearError() {
    errorMessage.value = '';
  }

  /// Reset controller state
  void resetController() {
    isNotificationPermissionGranted.value = false;
    fcmToken.value = '';
    isTokenSentToBackend.value = false;
    isLoadingNotifications.value = false;
    errorMessage.value = '';
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    try {
      // Check if GetX context is available
      if (Get.context != null && Get.isRegistered<GetMaterialController>()) {
        Get.snackbar(
          'Success',
          message,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      } else {
        print('✅ Success: $message');
      }
    } catch (e) {
      print('Snackbar error: $e');
      print('✅ Success: $message');
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    try {
      // Check if GetX context is available
      if (Get.context != null && Get.isRegistered<GetMaterialController>()) {
        Get.snackbar(
          'Error',
          message,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      } else {
        print('❌ Error: $message');
      }
    } catch (e) {
      print('Snackbar error: $e');
      print('❌ Error: $message');
    }
  }
}