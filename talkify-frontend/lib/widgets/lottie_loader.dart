import 'package:flutter/material.dart';
import '../core/theme.dart';

class LottieLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final String? animationPath;
  final Color? backgroundColor;
  final String? message;

  const LottieLoader({
    super.key,
    this.width,
    this.height,
    this.animationPath,
    this.backgroundColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final defaultSize = isTablet ? 120.0 : 100.0;
    final iconSize = isTablet ? 40.0 : 30.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    return Container(
      width: width ?? defaultSize,
      height: height ?? defaultSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Lottie animation
            Container(
              width: iconSize * 2,
              height: iconSize * 2,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(iconSize),
              ),
              child: Icon(
                Icons.animation,
                color: AppColors.white,
                size: iconSize,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGrey,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Specific Lottie Loader Widgets for different use cases

class LoadingAnimation extends StatelessWidget {
  final String? message;

  const LoadingAnimation({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LottieLoader(
      width: 120,
      height: 120,
      backgroundColor: Colors.transparent,
      message: message ?? 'Loading...',
    );
  }
}

class ConnectingAnimation extends StatelessWidget {
  const ConnectingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return LottieLoader(
      width: 150,
      height: 150,
      backgroundColor: AppColors.darkBackground.withOpacity(0.8),
      message: 'Connecting...',
    );
  }
}

class RingingAnimation extends StatelessWidget {
  const RingingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return LottieLoader(
      width: 100,
      height: 100,
      backgroundColor: AppColors.darkBackground.withOpacity(0.8),
      message: 'Ringing...',
    );
  }
}

class SuccessAnimation extends StatelessWidget {
  const SuccessAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return LottieLoader(
      width: 80,
      height: 80,
      backgroundColor: AppColors.success.withOpacity(0.1),
      message: 'Success!',
    );
  }
}
