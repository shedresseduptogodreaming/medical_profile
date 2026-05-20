import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';

class EmergencyScreen extends StatelessWidget {
  final Map<String, String> data;

  const EmergencyScreen({super.key, required this.data});

  String get _displayName {
    final parts = [
      data['lastName'] ?? '',
      data['firstName'] ?? '',
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Профиль\nне заполнен' : parts.join('\n');
  }

  String get _shortInfo {
    final parts = <String>[];
    if ((data['birthDate'] ?? '').isNotEmpty) parts.add(data['birthDate']!);
    if ((data['height'] ?? '').isNotEmpty) parts.add(data['height']!);
    if ((data['weight'] ?? '').isNotEmpty) parts.add(data['weight']!);
    return parts.join(' / ');
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось совершить звонок')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloodType = data['bloodType'] ?? '';
    final medications = data['medications'] ?? '';
    final allergies = data['allergies'] ?? '';
    final conditions = data['conditions'] ?? '';
    final notes = data['notes'] ?? '';
    final contactName = data['contactName'] ?? '';
    final contactRole = data['contactRole'] ?? '';
    final contactPhone = data['contactPhone'] ?? '';

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Оранжевая карточка
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      height: 46 / 40,
                      letterSpacing: -2,
                    ),
                  ),
                  if (_shortInfo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _shortInfo,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Строки с данными
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRow('Группа крови\nи резус фактор', bloodType),
                    _buildRow('Лекарства', medications),
                    _buildRow('Аллергии', allergies),
                    _buildRow('Заболевания', conditions),
                    _buildRow('Заметки', notes),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Блок контакта + кнопка звонка
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Слева имя контакта, справа роль
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          contactName.isNotEmpty ? contactName : '—',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          contactRole.isNotEmpty ? contactRole : '',
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Кнопка позвонить
                  GestureDetector(
                    onTap: contactPhone.isNotEmpty
                        ? () => _call(context, contactPhone)
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: contactPhone.isNotEmpty
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFAAAAAA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'Позвонить',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 24),
              Flexible(
                child: Text(
                  value.isNotEmpty ? value : '—',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}