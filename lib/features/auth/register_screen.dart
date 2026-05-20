import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Форматирование телефона
  void _formatPhone(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8')) digits = '7${digits.substring(1)}';
    if (!digits.startsWith('7')) digits = '7$digits';
    if (digits.length > 11) digits = digits.substring(0, 11);

    String formatted = '+7';
    if (digits.length > 1) formatted += ' (${digits.substring(1, digits.length > 4 ? 4 : digits.length)}';
    if (digits.length > 4) formatted += ') ${digits.substring(4, digits.length > 7 ? 7 : digits.length)}';
    if (digits.length > 7) formatted += ' ${digits.substring(7, digits.length > 9 ? 9 : digits.length)}';
    if (digits.length > 9) formatted += '-${digits.substring(9, digits.length > 11 ? 11 : digits.length)}';

    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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

  void _validate() {
    setState(() {
      // Email
      if (_emailController.text.isEmpty) {
        _emailError = 'Введите email';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Некорректный email';
      } else {
        _emailError = null;
      }

      // Телефон
      String digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 11) {
        _phoneError = 'Введите полный номер телефона';
      } else {
        _phoneError = null;
      }

      // Пароль
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Введите пароль';
      } else if (!_isValidPassword(_passwordController.text)) {
        _passwordError = 'Минимум 8 символов, заглавные и строчные буквы, цифры';
      } else {
        _passwordError = null;
      }

      // Подтверждение пароля
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = 'Подтвердите пароль';
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = 'Пароли не совпадают';
      } else {
        _confirmPasswordError = null;
      }
    });

    if (_emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _confirmPasswordError == null) {
      // Всё ок — переходим дальше
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // resizeToAvoidBottomInset: false убирает поднятие кнопки
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
              controller: _phoneController,
              hint: 'Телефон',
              keyboardType: TextInputType.phone,
              error: _phoneError,
              onChanged: _formatPhone,
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
                onPressed: _validate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text('Зарегистрироваться', style: AppTextStyles.buttonText),
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
            style: AppTextStyles.fieldHint.copyWith(fontSize: 20),
          ),
        ],
      ],
    );
  }
}