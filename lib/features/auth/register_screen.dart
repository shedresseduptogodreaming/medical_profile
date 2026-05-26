import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  bool _runValidation() {
    bool isValid = true;

    if (_emailController.text.isEmpty) {
      _emailError = 'Введите email';
      isValid = false;
    } else if (!_isValidEmail(_emailController.text)) {
      _emailError = 'Некорректный email';
      isValid = false;
    } else {
      _emailError = null;
    }

    if (_passwordController.text.isEmpty) {
      _passwordError = 'Введите пароль';
      isValid = false;
    } else if (!_isValidPassword(_passwordController.text)) {
      _passwordError = 'Минимум 8 символов, заглавные и строчные буквы, цифры';
      isValid = false;
    } else {
      _passwordError = null;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _confirmPasswordError = 'Подтвердите пароль';
      isValid = false;
    } else if (_confirmPasswordController.text != _passwordController.text) {
      _confirmPasswordError = 'Пароли не совпадают';
      isValid = false;
    } else {
      _confirmPasswordError = null;
    }

    return isValid;
  }

  Future<void> _submit() async {
    setState(() {});
    final valid = _runValidation();
    setState(() {});

    if (!valid) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        // ✅ ИСПРАВЛЕНО: очищаем весь стек
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on Exception catch (e) {
      print('REGISTER ERROR: $e');
      setState(() {
        _emailError = e.toString().contains('email-already-in-use')
            ? 'Этот email уже зарегистрирован'
            : 'Ошибка регистрации. Попробуйте снова';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        titleSpacing: 0,
        title: const AppLogo(),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text('Регистрация', style: AppTextStyles.heading),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _emailController,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              error: _emailError,
              onChanged: (_) => setState(() => _emailError = null),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hint: 'Пароль',
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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Зарегистрироваться', style: AppTextStyles.buttonText),
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
    Widget? suffix,
    String? error,
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
          Text(
            error,
            style: AppTextStyles.fieldHint.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }
}