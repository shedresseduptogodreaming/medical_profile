// lib/models/user_profile.dart

import 'dart:convert';

class EmergencyContact {
  final String name;
  final String phone;
  final String relation; // мама, папа, врач и т.д.

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relation = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relation': relation,
      };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) =>
      EmergencyContact(
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        relation: map['relation'] ?? '',
      );

  @override
  String toString() => '$name ($relation): $phone';
}

class UserProfile {
  final String uid; // Firebase UID

  // Личные данные
  final String lastName;
  final String firstName;
  final String middleName;
  final DateTime? birthDate;
  final double? height; // см
  final double? weight; // кг

  // Медицинские данные
  final String bloodType;  // A, B, AB, O
  final String rhFactor;   // + или -
  final List<String> allergies;
  final List<String> medications;
  final List<String> conditions; // заболевания
  final String notes;

  // Экстренные контакты
  final List<EmergencyContact> emergencyContacts;

  const UserProfile({
    required this.uid,
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.birthDate,
    this.height,
    this.weight,
    this.bloodType = '',
    this.rhFactor = '',
    this.allergies = const [],
    this.medications = const [],
    this.conditions = const [],
    this.notes = '',
    this.emergencyContacts = const [],
  });

  // Полное имя
  String get fullName =>
      [lastName, firstName, middleName].where((s) => s.isNotEmpty).join(' ');

  // Группа крови с резусом: "A(II)+"
  String get bloodGroup =>
      bloodType.isNotEmpty ? '$bloodType$rhFactor' : '';

  // Возраст
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  // ─── Firestore ───────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'lastName': lastName,
        'firstName': firstName,
        'middleName': middleName,
        'birthDate': birthDate?.toIso8601String(),
        'height': height,
        'weight': weight,
        'bloodType': bloodType,
        'rhFactor': rhFactor,
        'allergies': allergies,
        'medications': medications,
        'conditions': conditions,
        'notes': notes,
        'emergencyContacts':
            emergencyContacts.map((c) => c.toMap()).toList(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] ?? '',
        lastName: map['lastName'] ?? '',
        firstName: map['firstName'] ?? '',
        middleName: map['middleName'] ?? '',
        birthDate: map['birthDate'] != null
            ? DateTime.tryParse(map['birthDate'])
            : null,
        height: (map['height'] as num?)?.toDouble(),
        weight: (map['weight'] as num?)?.toDouble(),
        bloodType: map['bloodType'] ?? '',
        rhFactor: map['rhFactor'] ?? '',
        allergies: List<String>.from(map['allergies'] ?? []),
        medications: List<String>.from(map['medications'] ?? []),
        conditions: List<String>.from(map['conditions'] ?? []),
        notes: map['notes'] ?? '',
        emergencyContacts: (map['emergencyContacts'] as List<dynamic>? ?? [])
            .map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  // ─── NFC (компактный текстовый формат) ───────────────────
  //
  // Формат для записи прямо в метку (≈ 300–400 байт):
  //   NAME:Иван Иванов
  //   DOB:2000-05-15
  //   BLOOD:A+
  //   ALLERGY:пенициллин,аспирин
  //   MEDS:метформин
  //   COND:диабет 2 типа
  //   CONTACT:Мама+79001234567
  //   NOTE:носит инсулин в сумке

  String toNfcString() {
    final buf = StringBuffer();

    if (fullName.isNotEmpty) buf.writeln('ФИО:$fullName');
    if (birthDate != null) {
      buf.writeln(
          ':${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}');
    }
    if (bloodGroup.isNotEmpty) buf.writeln('Группа крови:$bloodGroup');
    if (allergies.isNotEmpty) buf.writeln('Аллергии:${allergies.join(',')}');
    if (medications.isNotEmpty) buf.writeln('Препараты:${medications.join(',')}');
    if (conditions.isNotEmpty) buf.writeln('Заболевания:${conditions.join(',')}');
    for (final c in emergencyContacts) {
      buf.writeln('Контакт:${c.name}+${c.phone}');
    }
    if (notes.isNotEmpty) buf.writeln('Заметка:$notes');

    return buf.toString().trim();
  }

  factory UserProfile.fromNfcString(String raw) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    final map = <String, String>{};
    for (final line in lines) {
      final idx = line.indexOf(':');
      if (idx == -1) continue;
      map[line.substring(0, idx)] = line.substring(idx + 1);
    }

    final contacts = <EmergencyContact>[];
    for (final line in raw.split('\n')) {
      if (line.startsWith('CONTACT:')) {
        final val = line.substring(8).trim();
        final plus = val.lastIndexOf('+');
        if (plus != -1) {
          contacts.add(EmergencyContact(
            name: val.substring(0, plus),
            phone: val.substring(plus + 1),
          ));
        }
      }
    }

    return UserProfile(
      uid: '',
      firstName: map['NAME']?.split(' ').skip(1).take(1).join() ?? '',
      lastName: map['NAME']?.split(' ').take(1).join() ?? '',
      middleName: map['NAME']?.split(' ').skip(2).join(' ') ?? '',
      birthDate: map['DOB'] != null ? DateTime.tryParse(map['DOB']!) : null,
      bloodType: map['BLOOD']?.replaceAll(RegExp(r'[+-]'), '') ?? '',
      rhFactor: map['BLOOD']?.contains('+') == true ? '+' : '-',
      allergies: map['ALLERGY']?.split(',').map((s) => s.trim()).toList() ?? [],
      medications: map['MEDS']?.split(',').map((s) => s.trim()).toList() ?? [],
      conditions: map['COND']?.split(',').map((s) => s.trim()).toList() ?? [],
      notes: map['NOTE'] ?? '',
      emergencyContacts: contacts,
    );
  }

  // ─── copyWith ─────────────────────────────────────────────

  UserProfile copyWith({
    String? lastName,
    String? firstName,
    String? middleName,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? bloodType,
    String? rhFactor,
    List<String>? allergies,
    List<String>? medications,
    List<String>? conditions,
    String? notes,
    List<EmergencyContact>? emergencyContacts,
  }) =>
      UserProfile(
        uid: uid,
        lastName: lastName ?? this.lastName,
        firstName: firstName ?? this.firstName,
        middleName: middleName ?? this.middleName,
        birthDate: birthDate ?? this.birthDate,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        bloodType: bloodType ?? this.bloodType,
        rhFactor: rhFactor ?? this.rhFactor,
        allergies: allergies ?? this.allergies,
        medications: medications ?? this.medications,
        conditions: conditions ?? this.conditions,
        notes: notes ?? this.notes,
        emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      );
}