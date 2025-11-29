import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../getx_controllers/call_controller.dart';

/// Call Notification Page
/// Shows incoming call notification with caller details and accept/reject buttons
class CallNotificationPage extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String callType;
  final String roomId;

  const CallNotificationPage({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callType,
    required this.roomId,
  });

  @override
  State<CallNotificationPage> createState() => _CallNotificationPageState();
}

class _CallNotificationPageState extends State<CallNotificationPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _playIncomingCallSound();
    _startVibration();
    _ensureCallController();
  }

  void _ensureCallController() {
    // Ensure CallController is available
    if (!Get.isRegistered<CallController>()) {
      Get.put(CallController());
    }
  }

  void _setupAnimations() {
    // Pulse animation for the caller avatar
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation for the buttons
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  void _playIncomingCallSound() {
    // Play system sound for incoming call
    HapticFeedback.mediumImpact();
    // You can add custom ringtone here if needed
  }

  void _startVibration() {
    // Start vibration pattern for incoming call
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGradientStart.withOpacity(0.9),
              AppColors.primaryGradientEnd.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacing
              SizedBox(height: isTablet ? 60 : 40),
              
              // Caller Information
              _buildCallerInfo(isTablet),
              
              // Call Type Indicator
              _buildCallTypeIndicator(isTablet),
              
              // Spacer
              const Spacer(),
              
              // Action Buttons
              _buildActionButtons(isTablet),
              
              // Bottom spacing
              SizedBox(height: isTablet ? 60 : 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallerInfo(bool isTablet) {
    return Column(
      children: [
        // Caller Avatar with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: isTablet ? 120 : 100,
                height: isTablet ? 120 : 100,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGradientStart.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: isTablet ? 60 : 50,
                  color: AppColors.white,
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: isTablet ? 30 : 20),
        
        // Caller Name
        Text(
          widget.callerName,
          style: TextStyle(
            fontSize: isTablet ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: isTablet ? 16 : 12),
        
        // Incoming Call Text
        Text(
          'Incoming ${widget.callType == 'video' ? 'Video' : 'Audio'} Call',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: AppColors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCallTypeIndicator(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 30,
        vertical: isTablet ? 20 : 16,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.callType == 'video' ? Icons.videocam : Icons.call,
            color: AppColors.white,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Text(
            widget.callType == 'video' ? 'Video Call' : 'Audio Call',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    print("ranjana");
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject Button
          _buildActionButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: _rejectCall,
            isTablet: isTablet,
          ),
          
          // Accept Button
          _buildActionButton(
            icon: widget.callType == 'video' ? Icons.videocam : Icons.call,
            color: Colors.green,
            onPressed: _acceptCall,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isTablet ? 80 : 70,
        height: isTablet ? 80 : 70,
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
          size: isTablet ? 35 : 30,
        ),
      ),
    );
  }

  void _acceptCall() {
    print('📞 Accepting call from ${widget.callerName}');
    
    // Stop animations
    _pulseController.stop();
    
    // Get or create CallController
    CallController callController;
    try {
      callController = Get.find<CallController>();
    } catch (e) {
      callController = Get.put(CallController());
    }
    
    // Accept the call using CallController method
    callController.acceptIncomingCall(widget.roomId);
  }

  void _rejectCall() {
    print('📞 Rejecting call from ${widget.callerName}');
    
    // Stop animations
    _pulseController.stop();
    
    // Get or create CallController
    CallController callController;
    try {
      callController = Get.find<CallController>();
    } catch (e) {
      callController = Get.put(CallController());
    }
    
    // Reject the call using CallController method
    callController.rejectIncomingCall(widget.roomId);
    
    // Navigate back
    Get.back();
  }
}
