import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import 'profile_screen.dart';
import '../../../models/user_profile.dart';
import '../auth/auth_screen.dart';

class EditScreen extends StatefulWidget {
  final ProfileData initialData;

  /// true — первый вход (профиль пустой), поля сразу разблокированы.
  /// false — повторный вход, поля заблокированы до нажатия «Изм.».
  final bool isNewProfile;

  const EditScreen({
    super.key,
    required this.initialData,
    this.isNewProfile = false,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _notesController;

  final GlobalKey _bloodTypeKey = GlobalKey();
  final GlobalKey _rhFactorKey = GlobalKey();

  String? _selectedBloodType;
  String? _selectedRhFactor;
  EmergencyContact? _emergencyContact;

  /// Режим редактирования:
  /// — при первом входе (isNewProfile == true) сразу true
  /// — при повторном входе изначально false
  late bool _isEditing;

  String? _lastNameError;
  String? _firstNameError;
  String? _middleNameError;
  String? _birthDateError;
  String? _heightError;
  String? _weightError;
  String? _contactError;
  String? _bloodTypeError;
  String? _rhFactorError;

  final List<String> _bloodTypes = ['0 (I)', 'А (II)', 'В (III)', 'АВ (IV)'];
  final List<String> _rhFactors = ['Rh+', 'Rh−'];
  final List<String> _roles = [
    'Мать', 'Отец', 'Партнер', 'Муж', 'Жена',
    'Сын', 'Дочь', 'Брат', 'Сестра',
    'Бабушка', 'Дедушка', 'Друг', 'Подруга', 'Коллега', 'Другое',
  ];

  @override
  void initState() {
    super.initState();
    // Поля сразу открыты только при первом создании профиля
    _isEditing = widget.isNewProfile;

    final d = widget.initialData;
    _lastNameController = TextEditingController(text: d.lastName);
    _firstNameController = TextEditingController(text: d.firstName);
    _middleNameController = TextEditingController(text: d.middleName);
    _birthDateController = TextEditingController(text: d.birthDate);
    _heightController = TextEditingController(text: d.height);
    _weightController = TextEditingController(text: d.weight);
    _medicationsController = TextEditingController(text: d.medications);
    _allergiesController = TextEditingController(text: d.allergies);
    _conditionsController = TextEditingController(text: d.conditions);
    _notesController = TextEditingController(text: d.notes);
    _selectedBloodType = d.bloodType.isNotEmpty ? d.bloodType : null;
    _selectedRhFactor = d.rhFactor.isNotEmpty ? d.rhFactor : null;
    if (d.contactName.isNotEmpty) {
      _emergencyContact = EmergencyContact(
        name: d.contactName,
        phone: d.contactPhone,
        relation: d.contactRole,
      );
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Возвращает максимальное число дней в месяце с учётом года.
  int _maxDayInMonth(int month, int year) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const days30 = [4, 6, 9, 11];
    return days30.contains(month) ? 30 : 31;
  }

  void _formatDate(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    // Ограничиваем день (первые 2 цифры): 01–31
    if (digits.length >= 2) {
      int day = int.tryParse(digits.substring(0, 2)) ?? 0;
      if (day < 1) day = 1;
      if (day > 31) day = 31;
      digits = day.toString().padLeft(2, '0') + digits.substring(2);
    }

    // Ограничиваем месяц (цифры 3–4): 01–12
    if (digits.length >= 4) {
      int month = int.tryParse(digits.substring(2, 4)) ?? 0;
      if (month < 1) month = 1;
      if (month > 12) month = 12;
      digits = digits.substring(0, 2) + month.toString().padLeft(2, '0') + digits.substring(4);
    }

    // Ограничиваем год (цифры 5–8): 1900–2026
    if (digits.length == 8) {
      int year = int.tryParse(digits.substring(4, 8)) ?? 1900;
      if (year < 1900) year = 1900;
      if (year > 2026) year = 2026;
      digits = digits.substring(0, 4) + year.toString().padLeft(4, '0');

      // Финальная проверка: день не превышает максимум для месяца/года
      int day = int.tryParse(digits.substring(0, 2)) ?? 1;
      int month = int.tryParse(digits.substring(2, 4)) ?? 1;
      final maxDay = _maxDayInMonth(month, year);
      if (day > maxDay) day = maxDay;
      digits = day.toString().padLeft(2, '0') + digits.substring(2);
    }

    // Форматируем с точками: ДД.ММ.ГГГГ
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) formatted += '.';
      formatted += digits[i];
    }

    _birthDateController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _formatHeight(String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _heightController.value = const TextEditingValue(
        text: '', selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }
    int h = int.tryParse(digits) ?? 0;
    if (h > 250) h = 250;
    if (h < 1) h = 1;
    final hStr = h.toString();
    final formatted = '$hStr см';
    _heightController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: hStr.length),
    );
  }

  void _formatWeight(String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _weightController.value = const TextEditingValue(
        text: '', selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }
    int w = int.tryParse(digits) ?? 0;
    if (w > 300) w = 300;
    if (w < 1) w = 1;
    final wStr = w.toString();
    final formatted = '$wStr кг';
    _weightController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: wStr.length),
    );
  }

  bool _validate() {
    bool isValid = true;

    _lastNameError = _lastNameController.text.trim().isEmpty
        ? 'Поле обязательно к заполнению' : null;
    if (_lastNameError != null) isValid = false;

    _firstNameError = _firstNameController.text.trim().isEmpty
        ? 'Поле обязательно к заполнению' : null;
    if (_firstNameError != null) isValid = false;

    _middleNameError = _middleNameController.text.trim().isEmpty
        ? 'Поле обязательно к заполнению' : null;
    if (_middleNameError != null) isValid = false;

    final dateDigits = _birthDateController.text.replaceAll(RegExp(r'\D'), '');
    if (dateDigits.length < 8) {
      _birthDateError = 'Введите полную дату рождения';
    } else {
      final day = int.tryParse(dateDigits.substring(0, 2)) ?? 0;
      final month = int.tryParse(dateDigits.substring(2, 4)) ?? 0;
      final year = int.tryParse(dateDigits.substring(4, 8)) ?? 0;
      if (month < 1 || month > 12) {
        _birthDateError = 'Неверный месяц (01–12)';
      } else if (year < 1900 || year > 2026) {
        _birthDateError = 'Неверный год (1900–2026)';
      } else if (day < 1 || day > _maxDayInMonth(month, year)) {
        _birthDateError = 'Неверный день для указанного месяца';
      } else {
        _birthDateError = null;
      }
    }
    if (_birthDateError != null) isValid = false;

    final heightDigits = _heightController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (heightDigits.isEmpty) {
      _heightError = 'Поле обязательно к заполнению';
    } else {
      final h = int.tryParse(heightDigits) ?? 0;
      _heightError = (h < 1 || h > 250) ? 'Рост: 1–250 см' : null;
    }
    if (_heightError != null) isValid = false;

    final weightDigits = _weightController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (weightDigits.isEmpty) {
      _weightError = 'Поле обязательно к заполнению';
    } else {
      final w = int.tryParse(weightDigits) ?? 0;
      _weightError = (w < 1 || w > 300) ? 'Вес: 1–300 кг' : null;
    }
    if (_weightError != null) isValid = false;

    _contactError = _emergencyContact == null
        ? 'Поле обязательно к заполнению' : null;
    if (_contactError != null) isValid = false;

    _bloodTypeError = _selectedBloodType == null
        ? 'Поле обязательно к заполнению' : null;
    if (_bloodTypeError != null) isValid = false;

    _rhFactorError = _selectedRhFactor == null
        ? 'Поле обязательно к заполнению' : null;
    if (_rhFactorError != null) isValid = false;

    return isValid;
  }

  /// Нажатие на кнопку «Изм.» / галочку
  void _onActionTap() {
    if (!_isEditing) {
      // Разблокируем поля
      setState(() => _isEditing = true);
    } else {
      // Пытаемся сохранить
      setState(() {
        final valid = _validate();
        if (valid) {
          final data = ProfileData(
            lastName: _lastNameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            middleName: _middleNameController.text.trim(),
            birthDate: _birthDateController.text.trim(),
            height: _heightController.text.trim(),
            weight: _weightController.text.trim(),
            bloodType: _selectedBloodType ?? '',
            rhFactor: _selectedRhFactor ?? '',
            medications: _medicationsController.text.trim(),
            allergies: _allergiesController.text.trim(),
            conditions: _conditionsController.text.trim(),
            notes: _notesController.text.trim(),
            contactName: _emergencyContact?.name ?? '',
            contactPhone: _emergencyContact?.phone ?? '',
            contactRole: _emergencyContact?.relation ?? '',
          );
          Navigator.pop(context, data);
        }
      });
    }
  }

  Future<void> _openDropdownMenu({
    required GlobalKey key,
    required List<String> items,
    required void Function(String) onSelected,
  }) async {
    if (!_isEditing) return;
    final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset globalOffset = box.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;
    final RelativeRect position = RelativeRect.fromLTRB(
      globalOffset.dx,
      globalOffset.dy + box.size.height,
      screenSize.width - globalOffset.dx - box.size.width,
      0,
    );
    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: AppColors.orange,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      items: items.map((item) => PopupMenuItem<String>(
        value: item,
        child: Text(item, style: AppTextStyles.fieldText.copyWith(color: AppColors.white)),
      )).toList(),
    );
    if (selected != null) onSelected(selected);
  }

  Future<void> _pickContact() async {
    if (!_isEditing) return;
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступа к контактам')),
      );
      return;
    }
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return;
    final full = await FlutterContacts.getContact(contact.id);
    if (full == null) return;
    final name = full.displayName;
    final phone = full.phones.isNotEmpty ? full.phones.first.number : '';
    if (!mounted) return;
    _showRoleBottomSheet(name: name, phone: phone);
  }

  void _showRoleBottomSheet({required String name, required String phone}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Кем приходится?',
                    style: AppTextStyles.fieldText.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(name, style: AppTextStyles.fieldHint),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _roles.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _emergencyContact = EmergencyContact(
                              name: name, phone: phone, relation: role,
                            );
                            _contactError = null;
                          });
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14,
                          ),
                          child: Text(role, style: AppTextStyles.fieldText),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: _onActionTap,
              child: Container(
                // Размер кнопки: высота 42, ширина 85
                width: 85,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: _isEditing
                    ? const Icon(Icons.check_rounded, color: AppColors.white, size: 24)
                    : const Text(
                        'Изм.',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
        children: [
          const SizedBox(height: 8),
          _buildTextField(
            controller: _lastNameController,
            hint: 'Фамилия',
            errorText: _lastNameError,
          ),
          _buildTextField(
            controller: _firstNameController,
            hint: 'Имя',
            errorText: _firstNameError,
          ),
          _buildTextField(
            controller: _middleNameController,
            hint: 'Отчество',
            errorText: _middleNameError,
          ),
          _buildTextField(
            controller: _birthDateController,
            hint: 'Дата рождения',
            keyboardType: TextInputType.number,
            onChanged: _isEditing ? _formatDate : null,
            errorText: _birthDateError,
          ),
          _buildTextField(
            controller: _heightController,
            hint: 'Рост',
            keyboardType: TextInputType.number,
            onChanged: _isEditing ? _formatHeight : null,
            errorText: _heightError,
          ),
          _buildTextField(
            controller: _weightController,
            hint: 'Вес',
            keyboardType: TextInputType.number,
            onChanged: _isEditing ? _formatWeight : null,
            errorText: _weightError,
          ),
          _buildContactField(),
          _buildBloodRow(),
          _buildTextField(
            controller: _medicationsController,
            hint: 'Лекарства',
          ),
          _buildTextField(
            controller: _allergiesController,
            hint: 'Аллергии',
          ),
          _buildTextField(
            controller: _conditionsController,
            hint: 'Заболевания',
          ),
          _buildTextField(
            controller: _notesController,
            hint: 'Заметки',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: OutlinedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Выйти из аккаунта?',
                      style: AppTextStyles.heading.copyWith(fontSize: 24),
                    ),
                    content: Text(
                      'Вы уверены, что хотите выйти?',
                      style: AppTextStyles.fieldHint,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Отмена',
                          style: AppTextStyles.fieldText.copyWith(color: AppColors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Выйти',
                          style: AppTextStyles.fieldText.copyWith(color: AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await Supabase.instance.client.auth.signOut();

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('yandex_uid');

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Выйти из аккаунта',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactField() {
    final borderColor = _contactError != null
        ? AppColors.orange
        : const Color(0xFFEEEEEE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isEditing ? _pickContact : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: _emergencyContact == null
                ? Text('Контакты', style: AppTextStyles.fieldHint)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _emergencyContact!.relation.toLowerCase(),
                        style: AppTextStyles.fieldHint.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(_emergencyContact!.name, style: AppTextStyles.fieldText),
                      const SizedBox(height: 4),
                      Text(_emergencyContact!.phone, style: AppTextStyles.fieldHint),
                    ],
                  ),
          ),
        ),
        if (_contactError != null) ...[
          const SizedBox(height: 4),
          Text(
            _contactError!,
            style: AppTextStyles.fieldHint.copyWith(
              color: AppColors.orange, fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildBloodRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSelectField(
            globalKey: _bloodTypeKey,
            hint: 'Группа крови',
            selectedValue: _selectedBloodType,
            errorText: _bloodTypeError,
            onTap: () => _openDropdownMenu(
              key: _bloodTypeKey,
              items: _bloodTypes,
              onSelected: (value) => setState(() {
                _selectedBloodType = value;
                _bloodTypeError = null;
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSelectField(
            globalKey: _rhFactorKey,
            hint: 'Резус фактор',
            selectedValue: _selectedRhFactor,
            errorText: _rhFactorError,
            onTap: () => _openDropdownMenu(
              key: _rhFactorKey,
              items: _rhFactors,
              onSelected: (value) => setState(() {
                _selectedRhFactor = value;
                _rhFactorError = null;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectField({
    required GlobalKey globalKey,
    required String hint,
    required String? selectedValue,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            key: globalKey,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: errorText != null
                      ? AppColors.orange
                      : const Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              selectedValue ?? hint,
              style: selectedValue != null
                  ? AppTextStyles.fieldText
                  : AppTextStyles.fieldHint,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.fieldHint.copyWith(
              color: AppColors.orange, fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          enabled: _isEditing,
          textAlign: TextAlign.left,
          style: AppTextStyles.fieldText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.fieldHint,
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.orange
                    : const Color(0xFFEEEEEE),
                width: 1,
              ),
            ),
            disabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.orange, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.fieldHint.copyWith(
              color: AppColors.orange, fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

