import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../widgets/responsive_container.dart';
import '../../getx_controllers/otp_controller.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

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
                  
                  // Heading
                  _buildHeading(isTablet),
                  
                  SizedBox(height: isTablet ? 50 : 40),
                  
                  // Phone Number Input
                  _buildPhoneInputField(isTablet),
                  
                  SizedBox(height: isTablet ? 40 : 30),
                  
                  // Send Button
                  _buildSendButton(context, isTablet),
                  
                  SizedBox(height: isTablet ? 20 : 15),
                  
                  // Helper Text
                  _buildHelperText(isTablet),
                  
                  SizedBox(height: isTablet ? 30 : 20),
                ],
              ),
            ),
          ),
        ),
      ),
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
        Icons.phone,
        size: isTablet ? 60 : 50,
        color: AppColors.white,
      ),
    );
  }

  /// Builds the heading text
  Widget _buildHeading(bool isTablet) {
    return Text(
      'Enter your phone number',
      style: TextStyle(
        fontSize: isTablet ? 32 : 28,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGradientStart,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds the phone number input field with +91 prefix
  Widget _buildPhoneInputField(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _phoneController,
        focusNode: _phoneFocusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          labelText: 'Phone Number',
          hintText: '9876543210',
          labelStyle: TextStyle(
            color: AppColors.darkGrey,
            fontSize: isTablet ? 16 : 14,
          ),
          hintStyle: TextStyle(
            color: AppColors.grey,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixText: '+91 ',
          prefixStyle: TextStyle(
            color: AppColors.primaryGradientStart,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.phone,
            color: AppColors.primaryGradientStart,
            size: isTablet ? 24 : 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 20 : 16,
          ),
        ),
        style: TextStyle(
          fontSize: isTablet ? 18 : 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  /// Builds the send verification code button
  Widget _buildSendButton(BuildContext context, bool isTablet) {
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
          onTap: _isLoading ? null : _handleSendOtp,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
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
                    Icons.send,
                    color: AppColors.white,
                    size: isTablet ? 20 : 18,
                  ),
                  SizedBox(width: isTablet ? 8 : 6),
                ],
                Text(
                  _isLoading ? 'Sending...' : 'Send Verification Code',
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

  /// Builds the helper text below the button
  Widget _buildHelperText(bool isTablet) {
    return Text(
      'We\'ll send an OTP to verify your number.',
      style: TextStyle(
        fontSize: isTablet ? 14 : 12,
        color: AppColors.darkGrey,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Handles the send OTP functionality
  void _handleSendOtp() {
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('Please enter your phone number');
      return;
    }
    
    if (phoneNumber.length != 10) {
      _showErrorSnackBar('Please enter a valid 10-digit phone number');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Initialize OtpController if not already initialized
    OtpController otpController;
    try {
      otpController = Get.find<OtpController>();
    } catch (e) {
      // Controller not found, create a new one
      otpController = Get.put(OtpController());
    }
    
    final fullPhoneNumber = '+91$phoneNumber';
    otpController.sendOtp(fullPhoneNumber);
    
    // Navigate to OTP verification page
    Navigator.pushNamed(context, '/otp-verification');
    
    setState(() {
      _isLoading = false;
    });
  }

  /// Shows error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

}
