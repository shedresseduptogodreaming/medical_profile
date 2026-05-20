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

  /// Формируем строку данных для QR-кода
  String get _qrData {
    final d = widget.profileData;
    final lines = <String>[
      if (d.lastName.isNotEmpty || d.firstName.isNotEmpty)
        '${d.lastName} ${d.firstName} ${d.middleName}'.trim(),
      if (d.birthDate.isNotEmpty) 'ДР: ${d.birthDate}',
      if (d.height.isNotEmpty) 'Рост: ${d.height}',
      if (d.weight.isNotEmpty) 'Вес: ${d.weight}',
      if (d.bloodType.isNotEmpty || d.rhFactor.isNotEmpty)
        'Кровь: ${d.bloodType} ${d.rhFactor}'.trim(),
      if (d.medications.isNotEmpty) 'Лекарства: ${d.medications}',
      if (d.allergies.isNotEmpty) 'Аллергии: ${d.allergies}',
      if (d.conditions.isNotEmpty) 'Заболевания: ${d.conditions}',
      if (d.notes.isNotEmpty) 'Заметки: ${d.notes}',
      if (d.contactName.isNotEmpty)
        'Контакт (${d.contactRole}): ${d.contactName} ${d.contactPhone}',
    ];
    return lines.isEmpty ? 'Профиль не заполнен' : lines.join('\n');
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

  Future<void> _onDownload() async {
    final bytes = await _captureQrImage();
    if (bytes == null) return;
    // Сохраняем в галерею через image_gallery_saver или просто во временную папку
    // TODO: подключить image_gallery_saver для сохранения в галерею
    // await ImageGallerySaver.saveImage(bytes, name: 'qr_profile');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Скачивание будет доступно после подключения image_gallery_saver')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка закрытия
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

            // QR-код в белой карточке
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: RepaintBoundary(
                key: _qrKey,
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

            const Spacer(),

            // Кнопки Поделиться / Скачать
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.ios_share_rounded,
                      label: 'Поделиться',
                      onTap: _onShare,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.download_rounded,
                      label: 'Скачать',
                      onTap: _onDownload,
                    ),
                  ),
                ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(height: 6),
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