import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Email Input, 2: OTP Entry, 3: New Password, 4: Success
  final _emailController = TextEditingController(text: 'ramesh@example.com');
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _handleSendOtp() async {
    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email or phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthApiService.instance.forgotPassword(identifier);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'OTP Sent successfully (Code: 123456)'),
          backgroundColor: AppTheme.primaryTerracotta,
        ),
      );
      setState(() => _currentStep = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Unable to send OTP'),
          backgroundColor: AppTheme.primaryTerracotta,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 4-digit OTP code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthApiService.instance.verifyOtp(_emailController.text.trim(), otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['verified'] == true || result['success'] == true) {
      setState(() => _currentStep = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Invalid OTP code. Use 1234 or 123456.'),
          backgroundColor: AppTheme.primaryTerracotta,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthApiService.instance.resetPassword(
      identifier: _emailController.text.trim(),
      otp: _enteredOtp.isEmpty ? '123456' : _enteredOtp,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _currentStep = 4);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to reset password'),
          backgroundColor: AppTheme.primaryTerracotta,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 4) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1EmailInput();
      case 2:
        return _buildStep2OtpInput();
      case 3:
        return _buildStep3NewPassword();
      case 4:
        return _buildStep4Success();
      default:
        return _buildStep1EmailInput();
    }
  }

  // --- STEP 1: Email / Phone Input ---
  Widget _buildStep1EmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 42,
              color: AppTheme.primaryTerracotta,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'No worries! Enter your registered email or phone number to receive a 4-digit reset code.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'Email or Phone Number',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppTheme.primaryTerracotta),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter your email or phone',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    'Send Reset Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: OTP Verification ---
  Widget _buildStep2OtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 42,
              color: AppTheme.primaryTerracotta,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Enter Verification Code',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'We sent a 4-digit code to ${_emailController.text}',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 58,
              height: 64,
              child: TextField(
                controller: _otpControllers[index],
                autofocus: index == 0,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 3) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    'Verify Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => AuthApiService.instance.resendOtp(_emailController.text.trim()),
            child: Text(
              "Didn't receive code? Resend",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTerracotta,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: Set New Password ---
  Widget _buildStep3NewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 42,
              color: AppTheme.primaryTerracotta,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Create New Password',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Your new password must be at least 6 characters.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'New Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPass,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTerracotta),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter new password',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Confirm New Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPass,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryTerracotta),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Confirm new password',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    'Reset Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // --- STEP 4: Success View ---
  Widget _buildStep4Success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: AppTheme.oliveLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 60,
            color: AppTheme.oliveGreen,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Password Reset!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been successfully updated. You can now sign in using your new credentials.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 44),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            ),
            child: Text(
              'Back to Login',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
