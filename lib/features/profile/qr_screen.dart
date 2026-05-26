import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme.dart';
import 'profile_screen.dart';

class QrScreen extends StatefulWidget {
  final ProfileData profileData;

  const QrScreen({super.key, required this.profileData});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final GlobalKey _qrKey = GlobalKey();

  // ============================================================
// ПАТЧ v2 для lib/features/profile/qr_screen.dart
// Заменить метод _qrData целиком (внутри класса _QrScreenState)
// ============================================================

  String get _qrData {
    final d = widget.profileData;

    // Пустой профиль
    if (d.lastName.isEmpty && d.firstName.isEmpty) {
      return 'Профиль не заполнен';
    }

    // --- Имя (без отчества) ---
    final fn = '${d.lastName} ${d.firstName}'.trim();
    final n  = '${d.lastName};${d.firstName};;;';

    // --- Дата рождения: DD.MM.YYYY → YYYY-MM-DD ---
    // Формат с дефисами работает корректно и на iOS и на Android
    String bday = '';
    if (d.birthDate.isNotEmpty) {
      final parts = d.birthDate.split('.');
      if (parts.length == 3) {
        bday = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      } else {
        bday = d.birthDate;
      }
    }

    // --- Телефон: убираем пробелы, скобки, дефисы ---
    final rawPhone = d.contactPhone.replaceAll(RegExp(r'[\s\(\)\-]'), '');

    // --- NOTE: медданные + имя контакта ---
    // iOS показывает NOTE только после нажатия "Добавить контакт" — это ограничение Apple
    // Android показывает NOTE сразу в превью
    final noteLines = <String>[];
    if (d.bloodType.isNotEmpty || d.rhFactor.isNotEmpty) {
      noteLines.add('Группа крови: ${d.bloodType} ${d.rhFactor}'.trim());
    }
    if (d.allergies.isNotEmpty)   noteLines.add('Аллергии: ${d.allergies}');
    if (d.medications.isNotEmpty) noteLines.add('Лекарства: ${d.medications}');
    if (d.conditions.isNotEmpty)  noteLines.add('Болезни: ${d.conditions}');
    if (d.height.isNotEmpty)      noteLines.add('Рост: ${d.height}');
    if (d.weight.isNotEmpty)      noteLines.add('Вес: ${d.weight}');
    if (d.notes.isNotEmpty)       noteLines.add('Заметки: ${d.notes}');
    if (d.contactName.isNotEmpty) {
      final label = d.contactRole.isNotEmpty ? d.contactRole : 'Контакт';
      noteLines.add('$label: ${d.contactName}');
    }

    // Переносы строк внутри NOTE экранируются как \n (литерально)
    final note = noteLines.join('\\n');

    // --- Телефон экстренного контакта с подписью роли ---
    // type=ROLE — Android показывает подпись рядом с номером
    String contactTel = '';
    if (rawPhone.isNotEmpty) {
      if (d.contactRole.isNotEmpty) {
        contactTel = 'TEL;type=${d.contactRole}:$rawPhone';
      } else {
        contactTel = 'TEL;type=CELL:$rawPhone';
      }
    }

    // --- Сборка vCard 3.0 ---
    // \r\n — стандартный разделитель строк в vCard
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:$fn',
      'N:$n',
      if (bday.isNotEmpty)       'BDAY:$bday',
      if (contactTel.isNotEmpty) contactTel,
      if (note.isNotEmpty)       'NOTE:$note',
      'END:VCARD',
    ];

    return lines.join('\r\n');
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _onShare() async {
    final bytes = await _captureQrImage();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr_profile.png');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Мой медицинский профиль',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка закрыть
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // QR-код
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: RepaintBoundary(
                key: _qrKey,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: double.infinity,
                      backgroundColor: AppColors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Кнопки Поделиться и Скачать
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _buildActionButton(
                icon: Icons.ios_share_rounded,
                label: 'Поделиться',
                onTap: _onShare,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}