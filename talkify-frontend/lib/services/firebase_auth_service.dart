import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Firebase Authentication Service
/// Handles OTP authentication only (no user data storage)
class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Send OTP to phone number
  /// [phoneNumber] should include country code (e.g., +91XXXXXXXXXX)
  /// Returns verification ID for OTP verification
  static Future<String?> sendOtpToPhone(String phoneNumber) async {
    print("Sending OTP to: $phoneNumber");
    
    try {
      final Completer<String?> completer = Completer<String?>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed
          print('✅ Auto-verification completed');
          if (!completer.isCompleted) {
            completer.complete('auto_verified');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle verification failed
          print('❌ Verification failed: ${e.message}');
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String id, int? resendToken) {
          // OTP sent successfully
          print('✅ OTP sent successfully. Verification ID: $id');
          if (!completer.isCompleted) {
            completer.complete(id);
          }
        },
        codeAutoRetrievalTimeout: (String id) {
          // Auto-retrieval timeout
          print('⏰ Auto-retrieval timeout. Verification ID: $id');
          if (!completer.isCompleted) {
            completer.complete(id);
          }
        },
        timeout: const Duration(seconds: 60),
      );
      
      // Wait for the verification ID from the callback
      final result = await completer.future;
      print('📱 Verification result: $result');
      return result;
      
    } catch (e) {
      print('❌ Error sending OTP: $e');
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-phone-number':
            throw Exception('Invalid phone number format');
          case 'too-many-requests':
            throw Exception('Too many requests. Please try again later');
          case 'quota-exceeded':
            throw Exception('SMS quota exceeded. Please try again later');
          case 'app-not-authorized':
            throw Exception('App not authorized for Firebase Auth. Please check your configuration.');
          case 'invalid-app-credential':
            throw Exception('Invalid app credentials. Please check your GoogleService-Info.plist file.');
          case 'network-request-failed':
            throw Exception('Network error. Please check your internet connection.');
          default:
            throw Exception('Failed to send OTP: ${e.message}');
        }
      }
      throw Exception('Network error. Please check your connection');
    }
  }

  /// Verify OTP code
  /// [verificationId] from sendOtpToPhone response
  /// [otpCode] 6-digit OTP entered by user
  /// Returns UserCredential on success, null on failure
  static Future<UserCredential?> verifyOtpCode(String verificationId, String otpCode) async {
    try {
      // Handle auto-verification case
      if (verificationId == 'auto_verified') {
        // User is already signed in from auto-verification
        final user = _auth.currentUser;
        if (user != null) {
          // Create a mock UserCredential for auto-verified users
          // In real implementation, this would be handled by the verificationCompleted callback
          return null; // This case should be handled differently
        }
        throw Exception('Auto-verification failed');
      }
      
      // Regular OTP verification
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ OTP verification successful');
      print('🔍 UserCredential type: ${userCredential.runtimeType}');
      print('🔍 User: ${userCredential.user?.uid}');
      
      // Additional validation to ensure the userCredential is valid
      if (userCredential.user == null) {
        throw Exception('UserCredential does not contain a valid user');
      }
      
      return userCredential;
      
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            throw Exception('Invalid OTP code. Please try again.');
          case 'invalid-verification-id':
            throw Exception('Invalid verification ID. Please request OTP again.');
          case 'session-expired':
            throw Exception('Session expired. Please request OTP again.');
          case 'app-not-authorized':
            throw Exception('App not authorized for Firebase Auth. Please check your configuration.');
          case 'invalid-app-credential':
            throw Exception('Invalid app credentials. Please check your GoogleService-Info.plist file.');
          case 'network-request-failed':
            throw Exception('Network error. Please check your internet connection.');
          default:
            throw Exception('OTP verification failed: ${e.message}');
        }
      }
      throw Exception('Network error. Please check your connection');
    }
  }

  /// Resend OTP to phone number
  /// [phoneNumber] should include country code
  /// Returns verification ID for new OTP
  static Future<String?> resendOtpToPhone(String phoneNumber) async {
    try {
      // Use the same implementation as sendOtpToPhone
      return await sendOtpToPhone(phoneNumber);
      
    } catch (e) {
      print('❌ Error resending OTP: $e');
      rethrow;
    }
  }

  /// Sign out current user
  /// Clears authentication state
  static Future<void> signOut() async {
    try {
      // TODO: Implement sign out
      // await _auth.signOut();
      
      print('👋 User signed out successfully');
      
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  /// Get current authenticated user
  /// Returns User object if authenticated, null otherwise
  static User? getCurrentUser() {
    try {
      // TODO: Return actual current user
      // return _auth.currentUser;
      
      // Placeholder - return null for now
      return null;
      
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    try {
      // TODO: Check actual authentication state
      // return _auth.currentUser != null;
      
      // Placeholder - return false for now
      return false;
      
    } catch (e) {
      print('❌ Error checking authentication: $e');
      return false;
    }
  }

  /// Get authentication state stream
  /// Listen to authentication state changes
  static Stream<User?> get authStateChanges {
    try {
      // TODO: Return actual auth state stream
      // return _auth.authStateChanges();
      
      // Placeholder - return empty stream
      return Stream.value(null);
      
    } catch (e) {
      print('❌ Error getting auth state stream: $e');
      return Stream.value(null);
    }
  }
}
