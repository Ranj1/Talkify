import 'package:flutter/material.dart';
import '../core/theme.dart';

class CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isVideoCall;
  final bool isEnabled;

  const CallButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isVideoCall = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final buttonSize = isTablet ? 100.0 : 80.0;
    final iconSize = isTablet ? 32.0 : 28.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: isEnabled 
            ? AppGradients.primaryGradient 
            : LinearGradient(
                colors: [AppColors.grey, AppColors.darkGrey],
              ),
        borderRadius: BorderRadius.circular(buttonSize / 4),
        boxShadow: [
          BoxShadow(
            color: isEnabled 
                ? AppColors.primaryGradientStart.withOpacity(0.3)
                : AppColors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonSize / 4),
          onTap: isEnabled ? onPressed : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.white,
                size: iconSize,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Audio Call Button Widget
class AudioCallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isEnabled;

  const AudioCallButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CallButton(
      icon: Icons.call,
      label: 'Audio',
      color: AppColors.success,
      onPressed: onPressed,
      isEnabled: isEnabled,
    );
  }
}

// Video Call Button Widget
class VideoCallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isEnabled;

  const VideoCallButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CallButton(
      icon: Icons.videocam,
      label: 'Video',
      color: AppColors.info,
      onPressed: onPressed,
      isVideoCall: true,
      isEnabled: isEnabled,
    );
  }
}
