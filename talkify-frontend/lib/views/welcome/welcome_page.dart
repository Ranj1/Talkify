import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme.dart';
import '../../widgets/responsive_container.dart';


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightBackground,
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: isDesktop ? 800 : null,
            child: Column(
              children: [
                // Main content area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Welcome Message Section
                        _buildWelcomeSection(isTablet),
                        
                        // WhatsApp Lottie Animation
                        _buildLottieAnimation(isTablet),
                        
                        // Terms and Conditions
                        _buildTermsAndConditions(isTablet),
                      ],
                    ),
                  ),
                ),
                
                // Fixed button at bottom
                _buildGetStartedButton(context, isTablet),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the welcome message section
  Widget _buildWelcomeSection(bool isTablet) {
    return Column(
      children: [
        SizedBox(height: isTablet ? 140 : 100),
        
        // Welcome Title
        Text(
          'Welcome to Talkify',
          style: TextStyle(
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGradientStart,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: isTablet ? 20 : 16),
        
        // Welcome Description
        Text(
          'Make high-quality audio and video calls\nwith your friends and family',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: AppColors.darkGrey,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: isTablet ? 70 : 60),
      ],
    );
  }

  /// Builds the WhatsApp Lottie animation container
  Widget _buildLottieAnimation(bool isTablet) {
    return Container(
      width: isTablet ? 240 : 180,
      height: isTablet ? 240 : 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Lottie.asset(
        'assets/images/WhatsappCw.json',
        width: isTablet ? 220 : 120,
        height: isTablet ? 220 : 120,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
      ),
    );
  }

  /// Builds the terms and conditions section
  Widget _buildTermsAndConditions(bool isTablet) {
    return Column(
      children: [
        SizedBox(height: isTablet ? 80 : 60),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
          child: Text(
            'By continuing, you agree to our Terms of Service and Privacy Policy. '
            'We may use your phone number to send you verification codes and '
            'important updates about our service.',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        SizedBox(height: isTablet ? 25 : 10),
      ],
    );
  }

  /// Builds the Get Started button at the bottom
  Widget _buildGetStartedButton(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 18),
      child: ResponsiveButton(
        text: 'Get Started',
        icon: Icons.arrow_forward,
        textColor: Colors.white,
        iconColor: AppColors.primaryGradientEnd,
        isFullWidth: true,
        onPressed: () {
          Navigator.pushNamed(context, '/phone-input');
        },
      ),
    );
  }
}