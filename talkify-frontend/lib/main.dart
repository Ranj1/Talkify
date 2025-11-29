import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme.dart';
import 'services/firebase_core_setup.dart';
import 'services/webrtc_service.dart';
import 'views/welcome/welcome_page.dart';
import 'views/auth/phone_input_page.dart';
import 'views/auth/otp_verification_page.dart';
import 'views/users_list/users_list_page.dart';
import 'views/calling/call_page.dart';
import 'views/calling/call_notification_page.dart';
import 'getx_controllers/notification_controller.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase before running the app
  await FirebaseCoreSetup.initializeFirebase();

  // Initialize WebRTC service
  await WebRTCService.initialize();

  // Register controllers globally
  Get.put(NotificationController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Talkify - VoIP Calling App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage(name: '/welcome', page: () => const WelcomePage()),
        GetPage(name: '/phone-input', page: () => const PhoneInputPage()),
        GetPage(name: '/otp-verification', page: () => const OtpVerificationPage()),
        GetPage(name: '/users-list', page: () => const UsersListPage()),
        GetPage(name: '/calling', page: () => const CallPage()),
        GetPage(
          name: '/call-notification', 
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return CallNotificationPage(
              callerId: args?['callerId'] ?? '',
              callerName: args?['callerName'] ?? '',
              callType: args?['callType'] ?? 'audio',
              roomId: args?['roomId'] ?? '',
            );
          }
        ),
      ],
      unknownRoute: GetPage(name: '/not-found', page: () => const WelcomePage()),
    );
  }
}
