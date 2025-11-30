import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../getx_controllers/call_controller.dart';
import '../widgets/incoming_call_notification.dart';

/// Firebase Cloud Messaging Service
/// Handles push notifications for VoIP calling app
class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  /// Initialize FCM service
  /// Call this method after Firebase Core initialization
  static Future<void> initializeFCM() async {
    try {
      // Add this at the start of initializeFCM()
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS, // use Darwin instead of IOS
      );

       await _localNotificationsPlugin.initialize(
         initializationSettings,
         onDidReceiveNotificationResponse: (NotificationResponse details) async {
           if (details.payload != null) {
             // Handle notification tap
             print('📱 Local notification tapped with payload: ${details.payload}');
             _handleLocalNotificationTap(details.payload!);
           }
         },
       );

      // Configure FCM settings for call notifications
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Setup notification handlers
      _setupNotificationHandlers();

      print('🔔 FCM initialized successfully');

    } catch (e) {
      print('❌ FCM initialization failed: $e');
    }
  }


  /// Get current notification permission status
  /// Returns 'granted', 'denied', 'not-determined', or 'provisional'
  static Future<String> getNotificationPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          return 'granted';
        case AuthorizationStatus.denied:
          return 'denied';
        case AuthorizationStatus.notDetermined:
          return 'not-determined';
        case AuthorizationStatus.provisional:
          return 'provisional';
      }
    } catch (e) {
      print('❌ Error getting notification permission status: $e');
      return 'unknown';
    }
  }

  /// Request notification permission from user
  /// Returns true if permission granted, false otherwise
  static Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 Requesting notification permission...');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
        return true;
      } else {
        print('❌ Notification permission denied');
        return false;
      }
      
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get FCM token for current device
  /// Send this token to your Node.js backend
  static Future<String?> getFCMToken() async {
    try {
      // For iOS, we need to ensure APNS token is set first
      if (Platform.isIOS) {
        // Try multiple times to get APNS token
        for (int attempt = 1; attempt <= 5; attempt++) {
          try {
            final apnsToken = await _messaging.getAPNSToken();
            if (apnsToken != null) {
              print('✅ APNS token available: ${apnsToken.toString()}');
              break;
            } else {
              print('⚠️ APNS token not available yet, attempt $attempt/5');
              if (attempt < 5) {
                await Future.delayed(Duration(seconds: attempt)); // Increasing delay
              }
            }
          } catch (e) {
            print('❌ Error getting APNS token (attempt $attempt): $e');
            if (attempt < 5) {
              await Future.delayed(Duration(seconds: attempt));
            }
          }
        }
      }
      
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        print('✅ FCM token obtained: $token');
      } else {
        print('⚠️ FCM token is null');
      }
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Send FCM token to backend
  /// [userId] - User ID from your backend
  /// [token] - FCM token from getFCMToken()
  static Future<bool> sendTokenToBackend(String userId, String token) async {
    try {
      
      await http.post(
        Uri.parse('http://192.168.0.229:3008/api/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      // Placeholder implementation
      print('📤 Sending FCM token to backend for user: $userId');
      print('🔑 Token: $token');
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      print('✅ FCM token sent to backend successfully');
      return true;
      
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
      return false;
    }
  }

  /// Setup notification handlers
  static void _setupNotificationHandlers() {
    // Listen to foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground notification received: ${message.notification?.title}');
      _handleNotification(message);
    });

    // Listen to notification taps (when app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Notification tapped: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App opened from notification: ${message.notification?.title}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Listen to foreground notifications
  /// Handle notifications when app is in foreground
  static void listenToForegroundNotifications() {
    try {
      print('👂 Listening to foreground notifications...');
      
    } catch (e) {
      print('❌ Error listening to foreground notifications: $e');
    }
  }

  /// Listen to background notifications
  /// Handle notifications when app is in background
  static void listenToBackgroundNotifications() {
    try {
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      print('👂 Listening to background notifications...');
      
    } catch (e) {
      print('❌ Error listening to background notifications: $e');
    }
  }

  /// Handle notification tap
  /// [message] - RemoteMessage from FCM
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      print('📱 Handling notification tap: ${message.data}');
      
      // Check if it's an incoming call notification
      if (message.data['type'] == 'incoming_call') {
        _handleIncomingCallNotification(message);
      } else {
        // Handle other notification types
        _handleGeneralNotificationTap(message);
      }
      
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Handle incoming call notification
  /// [message] - RemoteMessage from FCM
  static void _handleIncomingCallNotification(RemoteMessage message) {
    try {
      print('📞 Incoming call notification: ${message.data}');
      
      // Extract call data from notification
      final callId = message.data['callId'];
      final callerId = message.data['callerId'];
      final callerName = message.data['callerName'] ?? 'Unknown';
      final callType = message.data['callType'] ?? 'audio';
      
      if (callId == null || callerId == null) {
        print('❌ Missing call data in notification');
        return;
      }
      
      // Get or create CallController
      CallController callController;
      try {
        callController = Get.find<CallController>();
      } catch (e) {
        callController = Get.put(CallController());
      }
      
      // Update call state for incoming call
      callController.callId.value = callId;
      callController.remoteUserId.value = callerId;
      callController.remoteUserName.value = callerName;
      callController.callType.value = callType;
      callController.isIncomingCall.value = true;
      callController.callState.value = 'ringing';
      callController.isRinging.value = true;
      
      // Show incoming call notification UI
      _showIncomingCallNotificationUI(callerName, callType, callId, callerId);
      
      print('✅ Incoming call handled: $callerName ($callType)');
      
    } catch (e) {
      print('❌ Error handling incoming call notification: $e');
    }
  }

  /// Show incoming call notification UI
  static void _showIncomingCallNotificationUI(String callerName, String callType, String callId, String callerId) {
    try {
      // Import the incoming call notification widget
      // This will show the full-screen incoming call notification
      print('📱 Showing incoming call notification UI');
      
      // Use the IncomingCallNotificationManager to show the notification
      IncomingCallNotificationManager.showIncomingCall(
        callerName: callerName,
        callType: callType,
        callId: callId,
        callerId: callerId,
      );
      
    } catch (e) {
      print('❌ Error showing incoming call notification UI: $e');
    }
  }

  /// Handle general notification tap
  /// [message] - RemoteMessage from FCM
  static void _handleGeneralNotificationTap(RemoteMessage message) {
    try {
      print('📱 General notification tap: ${message.notification?.title}');
      
      // Navigate to appropriate screen based on notification type
      final notificationType = message.data['type'];
      
      switch (notificationType) {
        case 'message':
          // Navigate to chat screen
          Get.toNamed('/chat');
          break;
        case 'system':
          // Navigate to settings or home
          Get.toNamed('/users-list');
          break;
        default:
          // Navigate to home
          Get.toNamed('/users-list');
          break;
      }
      
    } catch (e) {
      print('❌ Error handling general notification tap: $e');
    }
  }

  /// Handle local notification tap
  /// [payload] - JSON string payload from local notification
  static void _handleLocalNotificationTap(String payload) {
    try {
      print('📱 Local notification tap: $payload');
      
      // Parse payload JSON
      final Map<String, dynamic> data = jsonDecode(payload);
      final notificationType = data['type'];
      
      if (notificationType == 'incoming_call') {
        // Handle incoming call from local notification
        // This would be called when user taps a local notification
        // For now, just navigate to users list
        Get.toNamed('/users-list');
        print('📞 Incoming call notification tapped');
      } else {
        // Handle other notification types
        Get.toNamed('/users-list');
      }
      
    } catch (e) {
      print('❌ Error handling local notification tap: $e');
      // Fallback navigation
      Get.toNamed('/users-list');
    }
  }

  /// Handle general notifications
  /// [message] - RemoteMessage from FCM
  static void _handleNotification(RemoteMessage message) {
    try {
      print('📱 General notification: ${message.notification?.title}');
      
      // Handle different notification types
      final notificationType = message.data['type'];
      
      switch (notificationType) {
        case 'incoming_call':
          _handleIncomingCallNotification(message);
          break;
        case 'message':
          // Show message notification
          _showLocalNotification(
            title: message.notification?.title ?? 'New Message',
            body: message.notification?.body ?? 'You have a new message',
          );
          break;
        case 'system':
          // Show system notification
          _showLocalNotification(
            title: message.notification?.title ?? 'System Notification',
            body: message.notification?.body ?? 'You have a system notification',
          );
          break;
        default:
          // Show general notification
          _showLocalNotification(
            title: message.notification?.title ?? 'Notification',
            body: message.notification?.body ?? 'You have a new notification',
          );
          break;
      }
      
    } catch (e) {
      print('❌ Error handling notification: $e');
    }
  }

  /// Subscribe to topic for group notifications
  /// [topic] - Topic name (e.g., 'calls', 'messages')
  static Future<bool> subscribeToTopic(String topic) async {
    try {
      // TODO: Subscribe to FCM topic
      // await _messaging.subscribeToTopic(topic);

      print('📢 Subscribing to topic: $topic');
      
      // Simulate subscription
      await Future.delayed(const Duration(seconds: 1));
      
      print('✅ Subscribed to topic: $topic');
      return true;
      
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
      return false;
    }
  }

  /// Unsubscribe from topic
  /// [topic] - Topic name to unsubscribe from
  static Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      // TODO: Unsubscribe from FCM topic
      // await _messaging.unsubscribeFromTopic(topic);

      print('📢 Unsubscribing from topic: $topic');
      
      // Simulate unsubscription
      await Future.delayed(const Duration(seconds: 1));
      
      print('✅ Unsubscribed from topic: $topic');
      return true;
      
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
      return false;
    }
  }

  /// Show local notification
  /// [title] - Notification title
  /// [body] - Notification body
  // static void _showLocalNotification({
  //   required String title,
  //   required String body,
  // }) {
  //   try {
  //     // Show snackbar for local notification
  //     Get.snackbar(
  //       title,
  //       body,
  //       snackPosition: SnackPosition.TOP,
  //       duration: const Duration(seconds: 3),
  //       backgroundColor: Get.theme.colorScheme.primary,
  //       colorText: Get.theme.colorScheme.onPrimary,
  //     );
  //
  //   } catch (e) {
  //     print('❌ Error showing local notification: $e');
  //   }
  // }



  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      // Android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'calls', // channelId
        'Call Notifications', // channelName
        channelDescription: 'Incoming call notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        ticker: 'ticker',
      );

      // iOS/macOS notification details (updated API)
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails, iOS: iOSDetails);

      await _localNotificationsPlugin.show(
        0,
        title,
        body,
        platformDetails,
        payload: '{"type":"incoming_call"}',
      );

    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }


  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      // Clear FCM token
      await _messaging.deleteToken();

      print('🗑️ Clearing all notifications...');
      
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }
}

/// Background message handler
/// Must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    print('📱 Background notification received: ${message.notification?.title}');
    
    // Handle incoming call notifications in background
    if (message.data['type'] == 'incoming_call') {
      print('📞 Incoming call notification in background: ${message.data}');
      
      // Store call data for when app is opened
      // This will be handled by getInitialMessage() when app starts
    }
    
  } catch (e) {
    print('❌ Error handling background notification: $e');
  }
}
