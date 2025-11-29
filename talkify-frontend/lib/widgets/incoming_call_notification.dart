import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme.dart';
import '../getx_controllers/call_controller.dart';

/// Incoming Call Notification Widget
/// Shows a full-screen incoming call notification with accept/reject buttons
class IncomingCallNotification extends StatelessWidget {
  final String callerName;
  final String callType;
  final String callId;
  final String callerId;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const IncomingCallNotification({
    super.key,
    required this.callerName,
    required this.callType,
    required this.callId,
    required this.callerId,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryGradientStart.withOpacity(0.8),
                AppColors.primaryGradientEnd.withOpacity(0.6),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            children: [
              // Status bar spacer
              const SizedBox(height: 20),
              
              // Caller info section
              Expanded(
                flex: 3,
                child: _buildCallerInfo(),
              ),
              
              // Call type indicator
              _buildCallTypeIndicator(),
              
              // Action buttons
              Expanded(
                flex: 2,
                child: _buildActionButtons(),
              ),
              
              // Bottom spacing
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Build caller information section
  Widget _buildCallerInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Caller avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryGradientStart,
                AppColors.primaryGradientEnd,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGradientStart.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.person,
            size: 60,
            color: AppColors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Caller name
        Text(
          callerName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Call status
        Text(
          'Incoming ${callType == 'video' ? 'Video' : 'Voice'} Call',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Build call type indicator
  Widget _buildCallTypeIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            callType == 'video' ? Icons.videocam : Icons.call,
            color: AppColors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            callType == 'video' ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject button
          _buildActionButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () {
              if (onReject != null) {
                onReject!();
              } else {
                _handleReject();
              }
            },
          ),
          
          // Accept button
          _buildActionButton(
            icon: callType == 'video' ? Icons.videocam : Icons.call,
            color: Colors.green,
            onPressed: () {
              if (onAccept != null) {
                onAccept!();
              } else {
                _handleAccept();
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build individual action button
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 30,
        ),
      ),
    );
  }

  /// Handle accept call
  void _handleAccept() {
    try {
      final callController = Get.find<CallController>();
      callController.acceptIncomingCall(callId);
      
      // Navigate to call screen
      Get.toNamed('/calling', arguments: {
        'user': {
          'uid': callerId,
          'name': callerName,
          'callType': callType,
        },
        'callType': callType,
        'isIncoming': true,
      });
    } catch (e) {
      print('❌ Error accepting call: $e');
      Get.snackbar(
        'Error',
        'Failed to accept call',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: AppColors.white,
      );
    }
  }

  /// Handle reject call
  void _handleReject() {
    try {
      final callController = Get.find<CallController>();
      callController.rejectIncomingCall(callId);
      
      // Close the notification
      Get.back();
    } catch (e) {
      print('❌ Error rejecting call: $e');
      Get.snackbar(
        'Error',
        'Failed to reject call',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: AppColors.white,
      );
    }
  }
}

/// Incoming Call Notification Manager
/// Manages the display and lifecycle of incoming call notifications
class IncomingCallNotificationManager {

  static bool _isShowing = false;

  /// Show incoming call notification
  static void showIncomingCall({
    required String callerName,
    required String callType,
    required String callId,
    required String callerId,
  }) {
    if (_isShowing) {
      print('⚠️ Incoming call notification already showing');
      return;
    }

    _isShowing = true;

    Get.dialog(
      IncomingCallNotification(
        callerName: callerName,
        callType: callType,
        callId: callId,
        callerId: callerId,
        onAccept: () {
          _isShowing = false;
        },
        onReject: () {
          _isShowing = false;
        },
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
    );
  }

  /// Hide incoming call notification
  static void hideIncomingCall() {
    if (_isShowing) {
      Get.back();
      _isShowing = false;
    }
  }

  /// Check if notification is showing
  static bool get isShowing => _isShowing;
}
