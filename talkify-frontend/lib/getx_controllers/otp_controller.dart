import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/api_service.dart';
import '../services/firebase_notification_service.dart';
import '../services/socket_service.dart';
import 'call_controller.dart';

class OtpController extends GetxController {
  // Reactive variables for state management
  final TextEditingController otpController = TextEditingController();
  final RxString otp = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString verificationId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize controller
    // Set up any initial state
  }

  @override
  void onReady() {
    super.onReady();
    // Controller is ready
    // Perform any setup that requires the widget tree to be ready
  }

  @override
  void onClose() {
    // Clean up resources
    otpController.dispose();
    super.onClose();
  }

  // Update OTP code and trigger UI update
  void updateOtpCode(String value) {
    otp.value = value;
  }

  // Send OTP to phone number
  void sendOtp(String phone) async {
    if (phone.isEmpty || phone.length < 10) {
      _showErrorSnackBar('Please enter a valid phone number');
      return;
    }

    phoneNumber.value = phone;
    isLoading.value = true;
    clearError();

    try {
      // Call Firebase Auth Service
      final verificationId = await FirebaseAuthService.sendOtpToPhone(phone);
      
      if (verificationId != null) {
        this.verificationId.value = verificationId;
        _showSuccessSnackBar('OTP sent successfully!');
      } else {
        _showErrorSnackBar('Failed to send OTP. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending OTP: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP code
  void verifyOtp() async {
    if (otp.value.length != 6) {
      _showErrorSnackBar('Please enter a valid 6-digit OTP');
      return;
    }

    if (verificationId.value.isEmpty) {
      _showErrorSnackBar('No verification ID found. Please request OTP again.');
      return;
    }

    isLoading.value = true;
    clearError();

    try {
      // Call Firebase Auth Service
      print('🔍 Calling FirebaseAuthService.verifyOtpCode...');
      final userCredential = await FirebaseAuthService.verifyOtpCode(
        verificationId.value,
        otp.value,
      );
      
      print('🔍 UserCredential received: $userCredential');
      print('🔍 UserCredential type: ${userCredential.runtimeType}');
      
      if (userCredential != null) {
        _showSuccessSnackBar('OTP verified successfully!');
        
        // Login to backend with Firebase UID, FCM token, and phone number
        print('🔍 Calling _loginToBackend...');
        await _loginToBackend(userCredential);
        
      } else {
        _showErrorSnackBar('Invalid OTP. Please try again.');
      }
    } catch (e) {
      print('❌ Error in verifyOtp: $e');
      print('❌ Error type: ${e.runtimeType}');
      _showErrorSnackBar('Error verifying OTP: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Login to backend after Firebase verification
  Future<void> _loginToBackend(dynamic userCredential) async {
    try {
      print('🔐 Logging in to backend...');
      print('🔍 userCredential type: ${userCredential.runtimeType}');
      print('🔍 userCredential: $userCredential');
      
      // Get Firebase ID token and UID
      print('🔍 Getting Firebase user data...');
      String? idToken;
      String? uid;
      
      try {
        // Try to get user from userCredential first
        final user = userCredential.user;
        if (user != null) {
          idToken = await user.getIdToken();
          uid = user.uid;
          print('🔑 Firebase ID token: $idToken');
          print('🔑 Firebase UID: $uid');
        } else {
          // Fallback: get current user from Firebase Auth
          print('🔍 userCredential.user is null, trying current user...');
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            idToken = await currentUser.getIdToken();
            uid = currentUser.uid;
            print('🔑 Firebase ID token (current user): $idToken');
            print('🔑 Firebase UID (current user): $uid');
          } else {
            throw Exception('No authenticated user found');
          }
        }
      } catch (e) {
        print('❌ Error getting Firebase user data: $e');
        throw Exception('Failed to get Firebase user data: $e');
      }
      
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Firebase ID token not available');
      }
      
      if (uid == null || uid.isEmpty) {
        throw Exception('Firebase UID not found');
      }
      
      // Get FCM token
      final fcmToken = await FirebaseNotificationService.getFCMToken();
      if (fcmToken == null) {
        throw Exception('FCM token not available');
      }
      

      
      // Login to backend
      await ApiService.loginUser(
        idToken: idToken, // 🔥 This is the important one
        uid: uid,         // just for backend reference
        fcmToken: fcmToken,
        phoneNumber: phoneNumber.value,
        name: 'User',
      );
      
      print('✅ Backend login successful');
      
      // Initialize Socket.IO connection
      await SocketService.initializeSocket();
      await SocketService.connect();
      
      // Wait a moment for socket to be fully connected
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Initialize CallController to set up Socket.IO event listeners
      if (!Get.isRegistered<CallController>()) {
        Get.put(CallController());
      }
      
      // Navigate to Users List Page
      try {
        Get.offAllNamed('/users-list');
      } catch (e) {
        print('Navigation error: $e');
        Get.toNamed('/users-list');
      }
      
    } catch (e) {
      print('❌ Backend login failed: $e');
      _showErrorSnackBar('Login failed: $e');
    }
  }

  // Resend OTP
  void resendOtp() async {
    if (phoneNumber.value.isEmpty) {
      _showErrorSnackBar('No phone number found. Please enter phone number again.');
      return;
    }

    isResending.value = true;
    clearError();

    try {
      // Call Firebase Auth Service
      final verificationId = await FirebaseAuthService.resendOtpToPhone(phoneNumber.value);
      
      if (verificationId != null) {
        this.verificationId.value = verificationId;
        _showSuccessSnackBar('New OTP sent successfully!');
      } else {
        _showErrorSnackBar('Failed to resend OTP. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error resending OTP: $e');
    } finally {
      isResending.value = false;
    }
  }

  // Clear error messages
  void clearError() {
    errorMessage.value = '';
  }

  // Reset controller state
  void resetController() {
    otp.value = '';
    otpController.clear();
    isLoading.value = false;
    isResending.value = false;
    errorMessage.value = '';
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    try {
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Snackbar error: $e');
    }
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    try {
      Get.snackbar(
        'Success',
        message,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Snackbar error: $e');
    }
  }
}
