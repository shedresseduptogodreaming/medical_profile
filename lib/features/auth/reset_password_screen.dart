import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _submit() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      if (otp.isEmpty) {
        _otpError = 'Введите код из письма';
      } else if (otp.length != 6 || int.tryParse(otp) == null) {
        _otpError = 'Код должен содержать 6 цифр';
      } else {
        _otpError = null;
      }

      if (password.isEmpty) {
        _passwordError = 'Введите новый пароль';
      } else if (!_isValidPassword(password)) {
        _passwordError = 'Минимум 8 символов, заглавные и строчные буквы, цифры';
      } else {
        _passwordError = null;
      }

      if (confirm.isEmpty) {
        _confirmPasswordError = 'Подтвердите пароль';
      } else if (confirm != password) {
        _confirmPasswordError = 'Пароли не совпадают';
      } else {
        _confirmPasswordError = null;
      }
    });

    if (_otpError != null || _passwordError != null || _confirmPasswordError != null) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.verifyOtpAndResetPassword(
        email: widget.email,
        otp: otp,
        newPassword: password,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль успешно изменён')),
      );
    } catch (e) {
      setState(() {
        _otpError = 'Неверный или истёкший код';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Новый пароль', style: AppTextStyles.heading),
            const SizedBox(height: 12),
            Text(
              'Введите код из письма и придумайте новый пароль',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _otpController,
              hint: 'Код из письма',
              keyboardType: TextInputType.number,
              error: _otpError,
              onChanged: (_) => setState(() => _otpError = null),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hint: 'Новый пароль',
              obscure: !_passwordVisible,
              error: _passwordError,
              onChanged: (_) => setState(() => _passwordError = null),
              suffix: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              hint: 'Подтвердите пароль',
              obscure: !_confirmPasswordVisible,
              error: _confirmPasswordError,
              onChanged: (_) => setState(() => _confirmPasswordError = null),
              suffix: IconButton(
                icon: Icon(
                  _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : Text('Сменить пароль', style: AppTextStyles.buttonText),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? error,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTextStyles.fieldText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.fieldHint,
            suffixIcon: suffix,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? AppColors.orange : AppColors.grey,
                width: 1.5,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.orange, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error, style: AppTextStyles.fieldHint.copyWith(fontSize: 20)),
        ],
      ],
    );
  }
}