import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import 'edit_screen.dart';
import 'qr_screen.dart';

/// Модель данных профиля — передаётся между экранами
class ProfileData {
  final String lastName;
  final String firstName;
  final String middleName;
  final String birthDate;
  final String height;
  final String weight;
  final String bloodType;
  final String rhFactor;
  final String medications;
  final String allergies;
  final String conditions;
  final String notes;
  final String contactName;
  final String contactPhone;
  final String contactRole;

  const ProfileData({
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.birthDate = '',
    this.height = '',
    this.weight = '',
    this.bloodType = '',
    this.rhFactor = '',
    this.medications = '',
    this.allergies = '',
    this.conditions = '',
    this.notes = '',
    this.contactName = '',
    this.contactPhone = '',
    this.contactRole = '',
  });

  bool get isEmpty => lastName.isEmpty && firstName.isEmpty;

  String get displayName {
    final parts = [lastName, firstName].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Профиль\nне заполнен' : parts.join('\n');
  }

  String get shortInfo {
    final parts = <String>[];
    if (birthDate.isNotEmpty) parts.add(birthDate);
    if (height.isNotEmpty) parts.add(height);
    if (weight.isNotEmpty) parts.add(weight);
    return parts.join(' / ');
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileData _profileData = const ProfileData();

  // Фиксированные размеры и отступы
  static const double _cardWidth = 366;
  static const double _cardHeight = 173;
  static const double _cardSpacing = 31;
  static const double _cardPadding = 21;
  static const double _titleFontSize = 40;
  static const double _infoFontSize = 22;
  static const double _titleLineHeight = 46 / 40; // ≈ 1.15
  static const double _borderRadius = 20;
  static const double _letterSpacing = -2;

  Future<void> _openEdit() async {
    final result = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(
        builder: (_) => EditScreen(initialData: _profileData),
      ),
    );
    if (result != null) {
      setState(() => _profileData = result);
    }
  }

  Future<void> _openQr() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScreen(profileData: _profileData),
      ),
    );
  }

  Future<void> _openNfc() async {
    // TODO: подключить nfc_manager и записать данные профиля на метку
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('NFC: функция будет добавлена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: const AppLogo(),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 16),
          _buildProfileCard(),
          const SizedBox(height: _cardSpacing),
          _buildDarkCard(
            label: 'Генератор\nQR-кода',
            onTap: _openQr,
          ),
          const SizedBox(height: _cardSpacing),
          _buildDarkCard(
            label: 'Запись на NFC',
            onTap: _openNfc,
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  /// Оранжевый блок:
  /// — имя в левом верхнем углу (top/left: 21)
  /// — кнопка «Изм.» в правом верхнем углу (top/right: 21)
  /// — строка дата/рост/вес в левом нижнем углу (bottom/left: 21), fontSize 22
  Widget _buildProfileCard() {
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Stack(
          children: [
            // Имя — левый верхний угол
            Positioned(
              top: _cardPadding,
              left: _cardPadding,
              right: 90, // место под кнопку «Изм.»
              child: Text(
                _profileData.displayName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: _titleFontSize,
                  fontWeight: FontWeight.w500,
                  height: _titleLineHeight,
                  letterSpacing: _letterSpacing,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Кнопка «Изм.» — правый верхний угол
            Positioned(
              top: _cardPadding,
              right: _cardPadding,
              child: GestureDetector(
                onTap: _openEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'Изм.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: _letterSpacing,
                    ),
                  ),
                ),
              ),
            ),

            // Дата / рост / вес — левый нижний угол
            if (_profileData.shortInfo.isNotEmpty)
              Positioned(
                bottom: _cardPadding,
                left: _cardPadding,
                right: _cardPadding,
                child: Text(
                  _profileData.shortInfo,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: _infoFontSize,
                    fontWeight: FontWeight.w400,
                    letterSpacing: _letterSpacing,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Тёмный блок-кнопка — заголовок в левом верхнем углу
  Widget _buildDarkCard({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        height: _cardHeight,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                top: _cardPadding,
                left: _cardPadding,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: _titleFontSize,
                  fontWeight: FontWeight.w500,
                  height: _titleLineHeight,
                  letterSpacing: _letterSpacing,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}