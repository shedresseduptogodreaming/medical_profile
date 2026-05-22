import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/nfc_service.dart';
import '../../../core/auth_service.dart';
import '../../../models/user_profile.dart';
import 'edit_screen.dart';
import 'qr_screen.dart';
import '../emergency/emergency_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return birthDate.isNotEmpty ? birthDate : '';
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileData _profileData = const ProfileData();
  bool _isLoading = true;

  static const double _profileCardHeight = 173;
  static const double _buttonCardHeight = 130;
  static const double _cardSpacing = 16;
  static const double _cardPadding = 21;
  static const double _titleFontSize = 40;
  static const double _buttonFontSize = 30;
  static const double _infoFontSize = 22;
  static const double _titleLineHeight = 46 / 40;
  static const double _buttonLineHeight = 36 / 30;
  static const double _borderRadius = 20;
  static const double _letterSpacing = -1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    String? uid = AuthService.currentUser?.id;
    
    // Если не Supabase пользователь — проверяем яндекс uid
    if (uid == null) {
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString('yandex_uid');
    }
    
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
  
    final profile = await AuthService.getProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        _profileData = ProfileData(
          lastName: profile.lastName,
          firstName: profile.firstName,
          middleName: profile.middleName,
          birthDate: profile.birthDate != null
              ? '${profile.birthDate!.day.toString().padLeft(2, '0')}.${profile.birthDate!.month.toString().padLeft(2, '0')}.${profile.birthDate!.year}'
              : '',
          height: profile.height != null
              ? '${profile.height!.toStringAsFixed(0)} см'
              : '',
          weight: profile.weight != null
              ? '${profile.weight!.toStringAsFixed(0)} кг'
              : '',
          bloodType: profile.bloodType,
          rhFactor: profile.rhFactor,
          medications: profile.medications.join(', '),
          allergies: profile.allergies.join(', '),
          conditions: profile.conditions.join(', '),
          notes: profile.notes,
          contactName: profile.emergencyContacts.isNotEmpty
              ? profile.emergencyContacts.first.name : '',
          contactPhone: profile.emergencyContacts.isNotEmpty
              ? profile.emergencyContacts.first.phone : '',
          contactRole: profile.emergencyContacts.isNotEmpty
              ? profile.emergencyContacts.first.relation : '',
        );
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile(ProfileData data) async {
    final uid = AuthService.currentUser?.id;
    if (uid == null) return;

    final profile = UserProfile(
      uid: uid,
      lastName: data.lastName,
      firstName: data.firstName,
      middleName: data.middleName,
      birthDate: data.birthDate.isNotEmpty
          ? DateTime.tryParse(
              data.birthDate.split('.').reversed.join('-'))
          : null,
      height: double.tryParse(data.height.replaceAll(RegExp(r'[^0-9]'), '')),
      weight: double.tryParse(data.weight.replaceAll(RegExp(r'[^0-9]'), '')),
      bloodType: data.bloodType,
      rhFactor: data.rhFactor,
      medications: data.medications.isNotEmpty
          ? data.medications.split(',').map((e) => e.trim()).toList()
          : [],
      allergies: data.allergies.isNotEmpty
          ? data.allergies.split(',').map((e) => e.trim()).toList()
          : [],
      conditions: data.conditions.isNotEmpty
          ? data.conditions.split(',').map((e) => e.trim()).toList()
          : [],
      notes: data.notes,
      emergencyContacts: data.contactName.isNotEmpty
          ? [
              EmergencyContact(
                name: data.contactName,
                phone: data.contactPhone,
                relation: data.contactRole,
              )
            ]
          : [],
    );

    await AuthService.saveProfile(profile);
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(
        builder: (_) => EditScreen(
          initialData: _profileData,
          isNewProfile: _profileData.isEmpty,
        ),
      ),
    );
    if (result != null) {
      setState(() => _profileData = result);
      await _saveProfile(result);
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

  Future<void> _openNfcWrite() async {
    if (_profileData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала заполните профиль')),
      );
      return;
    }

    await NfcService.writeProfile(
      lastName: _profileData.lastName,
      firstName: _profileData.firstName,
      birthDate: _profileData.birthDate,
      height: _profileData.height,
      weight: _profileData.weight,
      bloodType: _profileData.bloodType.isNotEmpty
          ? '${_profileData.bloodType} ${_profileData.rhFactor}'
          : '',
      medications: _profileData.medications,
      allergies: _profileData.allergies,
      conditions: _profileData.conditions,
      notes: _profileData.notes,
      contactName: _profileData.contactName,
      contactRole: _profileData.contactRole,
      contactPhone: _profileData.contactPhone,
      onSuccess: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      },
    );
  }

  Future<void> _openNfcRead() async {
    await NfcService.readTag(
      onSuccess: (data) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyScreen(data: data),
          ),
        );
      },
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      },
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildProfileCard(),
                  const SizedBox(height: _cardSpacing),
                  _buildDarkCard(
                    label: 'Записать\nметку',
                    onTap: _openNfcWrite,
                  ),
                  const SizedBox(height: _cardSpacing),
                  _buildDarkCard(
                    label: 'Считать\nметку',
                    onTap: _openNfcRead,
                  ),
                  const SizedBox(height: _cardSpacing),
                  _buildDarkCard(
                    label: 'Создать\nQR-код',
                    onTap: _openQr,
                    color: const Color(0xFFD1D1D6),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      height: _profileCardHeight,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Stack(
        children: [
          Positioned(
            top: _cardPadding,
            left: _cardPadding,
            right: 90,
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
    );
  }

  Widget _buildDarkCard({
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF1C1C1E),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _buttonCardHeight,
        decoration: BoxDecoration(
          color: color,
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
                fontSize: _buttonFontSize,
                fontWeight: FontWeight.w500,
                height: _buttonLineHeight,
                letterSpacing: _letterSpacing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}