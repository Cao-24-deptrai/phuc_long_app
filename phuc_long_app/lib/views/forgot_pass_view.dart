import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/vector_logo.dart';
import '../state/app_state.dart';
import '../services/email_service.dart';

enum ForgotPasswordStep { enterEmail, enterCode, resetPassword }

class ForgotPassView extends StatefulWidget {
  const ForgotPassView({super.key});

  @override
  State<ForgotPassView> createState() => _ForgotPassViewState();
}

class _ForgotPassViewState extends State<ForgotPassView> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;
  
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Dynamic 6-digit verification OTP code
  String _generatedOtpCode = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generate6DigitOtp() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    return code;
  }

  void _sendVerificationCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final exists = await AppState().checkIfUserExists(email);

    if (!exists) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không tìm thấy tài khoản đăng ký với email này.';
      });
      return;
    }

    // Generate fresh 6-digit OTP code
    _generatedOtpCode = _generate6DigitOtp();

    // Trigger automated email sending from mottaikhoanphu102@gmail.com
    await EmailService().sendOtpEmail(
      recipientEmail: email,
      otpCode: _generatedOtpCode,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _currentStep = ForgotPasswordStep.enterCode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gửi mã OTP xác nhận đến $email! Vui lòng kiểm tra hòm thư của bạn.',
          style: GoogleFonts.beVietnamPro(fontSize: 13),
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _verifyCode() async {
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (_codeController.text.trim() == _generatedOtpCode) {
      setState(() {
        _currentStep = ForgotPasswordStep.resetPassword;
      });
    } else {
      setState(() {
        _errorMessage = 'Mã OTP không hợp lệ. Vui lòng kiểm tra lại email hoặc bấm gửi lại mã.';
      });
    }
  }

  void _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _newPasswordController.text;

    // Update password in AppState and Firebase
    final success = await AppState().resetPassword(email, password);

    if (!success) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi khi đặt lại mật khẩu. Vui lòng thử lại.';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đổi Mật Khẩu Thành Công',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Mật khẩu cho tài khoản $email đã được cập nhật thành công! Vui lòng sử dụng mật khẩu mới để đăng nhập.',
          style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppTheme.textDark, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Go back to login screen
            },
            child: Text('Đăng Nhập Ngay', style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () {
            if (_currentStep == ForgotPasswordStep.enterCode) {
              setState(() {
                _currentStep = ForgotPasswordStep.enterEmail;
                _errorMessage = '';
              });
            } else if (_currentStep == ForgotPasswordStep.resetPassword) {
              setState(() {
                _currentStep = ForgotPasswordStep.enterCode;
                _errorMessage = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Quên Mật Khẩu',
          style: GoogleFonts.beVietnamPro(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const PhucLongLogo(size: 60),
                    const SizedBox(height: 36),
                    
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCurrentFormStep(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentFormStep() {
    switch (_currentStep) {
      case ForgotPasswordStep.enterEmail:
        return Container(
          key: const ValueKey('enterEmailForm'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Form(
            key: _emailFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Khôi Phục Mật Khẩu',
                  style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nhập email đã đăng ký. Hệ thống sẽ gửi mã OTP xác minh khôi phục mật khẩu cho bạn.',
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ Email',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Định dạng email không hợp lệ';
                    }
                    return null;
                  },
                ),
                
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Gửi Mã Xác Nhận', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      
      case ForgotPasswordStep.enterCode:
        return Container(
          key: const ValueKey('enterCodeForm'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Form(
            key: _codeFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Xác Thực Mã OTP',
                  style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mã OTP 6 chữ số đã được gửi tự động đến ${_emailController.text.trim()}.',
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Mã xác thực OTP (6 chữ số)',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã OTP';
                    }
                    if (value.trim().length < 6) {
                      return 'Mã OTP phải gồm 6 chữ số';
                    }
                    return null;
                  },
                ),
                
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Xác Thực Mã OTP', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      setState(() {
                        _errorMessage = '';
                        _generatedOtpCode = _generate6DigitOtp();
                      });

                      await EmailService().sendOtpEmail(
                        recipientEmail: _emailController.text.trim(),
                        otpCode: _generatedOtpCode,
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã gửi lại mã OTP mới đến ${_emailController.text.trim()}! Vui lòng kiểm tra hòm thư.',
                            style: GoogleFonts.beVietnamPro(),
                          ),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                    child: Text('Gửi lại mã OTP', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
        
      case ForgotPasswordStep.resetPassword:
        return Container(
          key: const ValueKey('resetPasswordForm'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Form(
            key: _resetFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Đặt Lại Mật Khẩu',
                  style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nhập mật khẩu mới cho tài khoản của bạn để hoàn tất quá trình đổi mật khẩu.',
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu mới phải dài ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                  ),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Lưu Mật Khẩu Mới', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
    }
  }
}
