import 'package:hive_flutter/hive_flutter.dart';

/// All supported UI languages for SAHAYAK-AI
enum AppLanguage {
  english,
  hindi,
  bengali,
  tamil,
  telugu,
  marathi,
  gujarati,
  kannada,
  malayalam,
  punjabi,
}

extension AppLanguageExt on AppLanguage {
  String get displayName {
    switch (this) {
      case AppLanguage.english:   return 'English';
      case AppLanguage.hindi:     return 'हिंदी (Hindi)';
      case AppLanguage.bengali:   return 'বাংলা (Bengali)';
      case AppLanguage.tamil:     return 'தமிழ் (Tamil)';
      case AppLanguage.telugu:    return 'తెలుగు (Telugu)';
      case AppLanguage.marathi:   return 'मराठी (Marathi)';
      case AppLanguage.gujarati:  return 'ગુજરાતી (Gujarati)';
      case AppLanguage.kannada:   return 'ಕನ್ನಡ (Kannada)';
      case AppLanguage.malayalam: return 'മലയാളം (Malayalam)';
      case AppLanguage.punjabi:   return 'ਪੰਜਾਬੀ (Punjabi)';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.english:   return '🇬🇧';
      case AppLanguage.hindi:     return '🇮🇳';
      case AppLanguage.bengali:   return '🇧🇩';
      case AppLanguage.tamil:     return '🇮🇳';
      case AppLanguage.telugu:    return '🇮🇳';
      case AppLanguage.marathi:   return '🇮🇳';
      case AppLanguage.gujarati:  return '🇮🇳';
      case AppLanguage.kannada:   return '🇮🇳';
      case AppLanguage.malayalam: return '🇮🇳';
      case AppLanguage.punjabi:   return '🇮🇳';
    }
  }
}

enum Gender { male, female, other, preferNotToSay }

extension GenderExt on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:           return 'Male';
      case Gender.female:         return 'Female';
      case Gender.other:          return 'Other';
      case Gender.preferNotToSay: return 'Prefer not to say';
    }
  }

  String get emoji {
    switch (this) {
      case Gender.male:           return '👨';
      case Gender.female:         return '👩';
      case Gender.other:          return '🧑';
      case Gender.preferNotToSay: return '🤐';
    }
  }
}

class PatientProfile {
  // Personal details
  final String id;
  String fullName;
  int age;
  Gender gender;
  String? city;
  String? diagnosis; // e.g., "Mild Cognitive Impairment"

  // Language
  AppLanguage preferredLanguage;

  // Caregiver info
  String? caregiverName;
  String? caregiverPhone;
  String? caregiverRelation;

  // Medical notes
  String? medicalNotes;

  // Meta
  final DateTime registeredAt;
  String linkCode;

  PatientProfile({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    this.city,
    this.diagnosis,
    required this.preferredLanguage,
    this.caregiverName,
    this.caregiverPhone,
    this.caregiverRelation,
    this.medicalNotes,
    required this.registeredAt,
    required this.linkCode,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'age': age,
        'gender': gender.name,
        'city': city,
        'diagnosis': diagnosis,
        'preferredLanguage': preferredLanguage.name,
        'caregiverName': caregiverName,
        'caregiverPhone': caregiverPhone,
        'caregiverRelation': caregiverRelation,
        'medicalNotes': medicalNotes,
        'registeredAt': registeredAt.toIso8601String(),
        'linkCode': linkCode,
      };

  factory PatientProfile.fromMap(Map<dynamic, dynamic> map) {
    return PatientProfile(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? 'Patient',
      age: map['age'] ?? 65,
      gender: Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.preferNotToSay,
      ),
      city: map['city'],
      diagnosis: map['diagnosis'],
      preferredLanguage: AppLanguage.values.firstWhere(
        (e) => e.name == map['preferredLanguage'],
        orElse: () => AppLanguage.english,
      ),
      caregiverName: map['caregiverName'],
      caregiverPhone: map['caregiverPhone'],
      caregiverRelation: map['caregiverRelation'],
      medicalNotes: map['medicalNotes'],
      registeredAt: DateTime.tryParse(map['registeredAt'] ?? '') ?? DateTime.now(),
      linkCode: map['linkCode'] ?? 'SAH-0000-XXXX',
    );
  }

  // ── Hive helpers ────────────────────────────────────────────────────────────

  static PatientProfile? loadFromHive() {
    try {
      final box = Hive.box('user_preferences');
      final saved = box.get('patient_profile');
      if (saved != null) {
        return PatientProfile.fromMap(Map<dynamic, dynamic>.from(saved));
      }
    } catch (_) {}
    return null;
  }

  void saveToHive() {
    try {
      final box = Hive.box('user_preferences');
      box.put('patient_profile', toMap());
    } catch (_) {}
  }

  static void clearFromHive() {
    try {
      final box = Hive.box('user_preferences');
      box.delete('patient_profile');
    } catch (_) {}
  }

  // ── Unique link code generator ───────────────────────────────────────────────
  static String generateLinkCode() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final part1 = (ts % 9000 + 1000).toString();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rand = ts % (chars.length * chars.length);
    final part2 =
        '${chars[rand ~/ chars.length % chars.length]}${chars[rand % chars.length]}${chars[(rand + 7) % chars.length]}${chars[(rand + 13) % chars.length]}';
    return 'SAH-$part1-$part2';
  }
}
