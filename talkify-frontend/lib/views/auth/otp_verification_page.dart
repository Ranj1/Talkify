import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme.dart';
import '../../widgets/responsive_container.dart';
import '../../getx_controllers/otp_controller.dart';

class OtpVerificationPage extends StatelessWidget {
  const OtpVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return GetX<OtpController>(
      init: Get.isRegistered<OtpController>() ? Get.find<OtpController>() : Get.put(OtpController()),
      builder: (controller) {
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
                maxWidth: isDesktop ? 600 : null,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 32 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Logo Section
                      _buildAppLogo(isTablet),
                      
                      SizedBox(height: isTablet ? 60 : 40),
                      
                      // Title and Subtitle
                      _buildTitleSection(isTablet),
                      
                      SizedBox(height: isTablet ? 50 : 40),
                      
                      // OTP Input Section
                      _buildOtpInputSection(controller, isTablet),
                      
                      SizedBox(height: isTablet ? 40 : 30),
                      
                      // Verify Button
                      _buildVerifyButton(controller, isTablet),
                      
                      SizedBox(height: isTablet ? 20 : 15),
                      
                      // Resend Section
                      _buildResendSection(controller, isTablet),
                      
                      SizedBox(height: isTablet ? 30 : 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the app logo section
  Widget _buildAppLogo(bool isTablet) {
    return Container(
      width: isTablet ? 120 : 100,
      height: isTablet ? 120 : 100,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.security,
        size: isTablet ? 60 : 50,
        color: AppColors.white,
      ),
    );
  }

  /// Builds the title and subtitle section
  Widget _buildTitleSection(bool isTablet) {
    return Column(
      children: [
        Text(
          'Enter the OTP',
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGradientStart,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: isTablet ? 16 : 12),
        
        Text(
          'A verification code has been sent to your number',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: AppColors.darkGrey,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the OTP input section with 6 digit boxes
  Widget _buildOtpInputSection(OtpController controller, bool isTablet) {
    final defaultPinTheme = PinTheme(
      width: isTablet ? 55 : 45,
      height: isTablet ? 55 : 45,
      textStyle: TextStyle(
        fontSize: isTablet ? 24 : 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGradientStart,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: AppColors.primaryGradientStart,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: AppColors.success,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    return Column(
      children: [
        // OTP Input using Pinput
        Pinput(
          length: 6,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          submittedPinTheme: submittedPinTheme,
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
          showCursor: true,
          onChanged: (value) => controller.updateOtpCode(value),
          onCompleted: (value) => controller.updateOtpCode(value),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          keyboardType: TextInputType.number,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        
        SizedBox(height: isTablet ? 30 : 20),
      ],
    );
  }

  /// Builds the verify OTP button
  Widget _buildVerifyButton(OtpController controller, bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 56 : 48,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: controller.isLoading.value ? null : () => controller.verifyOtp(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (controller.isLoading.value) ...[
                  SizedBox(
                    width: isTablet ? 20 : 18,
                    height: isTablet ? 20 : 18,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                ] else ...[
                  Icon(
                    Icons.phone,
                    color: AppColors.white,
                    size: isTablet ? 20 : 18,
                  ),
                  SizedBox(width: isTablet ? 8 : 6),
                ],
                Text(
                  controller.isLoading.value ? 'Verifying...' : 'Verify OTP',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the resend section
  Widget _buildResendSection(OtpController controller, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Didn\'t receive the code? ',
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: AppColors.darkGrey,
          ),
        ),
        GestureDetector(
          onTap: controller.isResending.value ? null : () => controller.resendOtp(),
          child: Text(
            controller.isResending.value ? 'Sending...' : 'Resend',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: controller.isResending.value 
                  ? AppColors.grey 
                  : AppColors.primaryGradientStart,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
