import 'package:flutter/material.dart';
import '../core/theme.dart';

class UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final bool isTablet;

  const UserTile({
    super.key,
    required this.user,
    this.onAudioCall,
    this.onVideoCall,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final profileSize = isTablet ? 60.0 : 50.0;
    final buttonSize = isTablet ? 50.0 : 40.0;
    final fontSize = isTablet ? 18.0 : 16.0;
    final subtitleSize = isTablet ? 16.0 : 14.0;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture with Online Status
          Stack(
            children: [
              Container(
                width: profileSize,
                height: profileSize,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(profileSize / 2),
                ),
                child: user['avatar'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(profileSize / 2),
                        child: Image.network(
                          user['avatar'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: AppColors.white,
                              size: profileSize * 0.6,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: profileSize * 0.6,
                      ),
              ),
              if (user['isOnline'] == true)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: isTablet ? 20 : 16,
                    height: isTablet ? 20 : 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(width: isTablet ? 20 : 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['phone'] ?? 'Unknown User',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['lastSeen'] ?? 'Last seen recently',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: user['isOnline'] == true
                        ? AppColors.success 
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: isTablet ? 20 : 16),
          
          // Call Buttons
          Row(
            children: [
              // Audio Call Button
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.call,
                    color: AppColors.white,
                    size: buttonSize * 0.5,
                  ),
                  onPressed: onAudioCall,
                ),
              ),
              
              SizedBox(width: isTablet ? 12 : 8),
              
              // Video Call Button
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.videocam,
                    color: AppColors.white,
                    size: buttonSize * 0.5,
                  ),
                  onPressed: onVideoCall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
