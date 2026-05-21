import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static Future<void> writeProfile({
    required String lastName,
    required String firstName,
    required String birthDate,
    required String height,
    required String weight,
    required String bloodType,
    required String medications,
    required String allergies,
    required String conditions,
    required String notes,
    required String contactName,
    required String contactRole,
    required String contactPhone,
    required void Function(String message) onSuccess,
    required void Function(String error) onError,
  }) async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      onError('NFC недоступен на этом устройстве');
      return;
    }

    final payload = [
      lastName,
      firstName,
      birthDate,
      height,
      weight,
      bloodType,
      medications,
      allergies,
      conditions,
      notes,
      contactName,
      contactRole,
      contactPhone,
    ].join('|');

    NfcManager.instance.startSession(
      alertMessage: 'Приложите метку для записи',
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Метка не поддерживает NDEF',
            );
            onError('Метка не поддерживает NDEF');
            return;
          }

          if (!ndef.isWritable) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Метка защищена от записи',
            );
            onError('Метка защищена от записи');
            return;
          }

          final record = NdefRecord.createText(payload);
          final message = NdefMessage([record]);
          final size = message.byteLength;

          if (ndef.maxSize != null && size > ndef.maxSize!) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Данные не помещаются на метку',
            );
            onError('Данные слишком большие (${size} / ${ndef.maxSize} байт)');
            return;
          }

          // Очищаем метку перед записью новых данных
          try {
            await ndef.write(NdefMessage([]));
          } catch (_) {
            // Некоторые метки не принимают пустое сообщение — продолжаем
          }

          await ndef.write(message);
          await NfcManager.instance.stopSession(
            alertMessage: 'Данные успешно записаны ✓',
          );
          onSuccess('Данные записаны на метку');
        } catch (e) {
          await NfcManager.instance.stopSession(
            errorMessage: 'Ошибка записи',
          );
          onError('Ошибка записи: $e');
        }
      },
    );
  }

  static Future<void> readTag({
    required void Function(Map<String, String> data) onSuccess,
    required void Function(String error) onError,
  }) async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      onError('NFC недоступен на этом устройстве');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            await NfcManager.instance.stopSession();
            onError('Метка не поддерживает NDEF');
            return;
          }

          final message = await ndef.read();
          if (message.records.isEmpty) {
            await NfcManager.instance.stopSession();
            onError('Метка пустая');
            return;
          }

          final record = message.records.first;
          final rawPayload = record.payload;

          // Первый байт — статус байт
          // биты 0-5 — длина языкового кода
          final languageCodeLength = rawPayload[0] & 0x3F;

          // Пропускаем статус байт + языковой код, декодируем UTF-8
          final text = utf8.decode(
            rawPayload.sublist(1 + languageCodeLength),
            allowMalformed: true,
          );

          final parts = text.split('|');
          String getValue(int i) => parts.length > i ? parts[i] : '';

          final data = <String, String>{
            'lastName':     getValue(0),
            'firstName':    getValue(1),
            'birthDate':    getValue(2),
            'height':       getValue(3),
            'weight':       getValue(4),
            'bloodType':    getValue(5),
            'medications':  getValue(6),
            'allergies':    getValue(7),
            'conditions':   getValue(8),
            'notes':        getValue(9),
            'contactName':  getValue(10),
            'contactRole':  getValue(11),
            'contactPhone': getValue(12),
          };

          await NfcManager.instance.stopSession();
          onSuccess(data);
        } catch (e) {
          await NfcManager.instance.stopSession();
          onError('Ошибка считывания: $e');
        }
      },
    );
  }
}