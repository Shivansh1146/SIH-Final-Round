import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// All supported UI languages for SAHAYAK-AI (English, Hindi, and NER North-Eastern Region Languages)
enum AppLanguage {
  english,
  hindi,
  assamese,
  bengali,
  manipuri,
  bodo,
  nepali,
  mizo,
}

extension AppLanguageExt on AppLanguage {
  String get displayName {
    switch (this) {
      case AppLanguage.english:   return 'English';
      case AppLanguage.hindi:     return 'हिंदी (Hindi)';
      case AppLanguage.assamese:  return 'অসমীয়া (Assamese)';
      case AppLanguage.bengali:   return 'বাংলা (Bengali)';
      case AppLanguage.manipuri:  return 'মৈতৈলোন্ (Manipuri)';
      case AppLanguage.bodo:      return 'बड़ो (Bodo)';
      case AppLanguage.nepali:    return 'नेपाली (Nepali)';
      case AppLanguage.mizo:      return 'Mizo ṭawng (Mizo)';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.english:   return '🇬🇧';
      case AppLanguage.hindi:     return '🇮🇳';
      case AppLanguage.assamese:  return '🇮🇳';
      case AppLanguage.bengali:   return '🇮🇳';
      case AppLanguage.manipuri:  return '🇮🇳';
      case AppLanguage.bodo:      return '🇮🇳';
      case AppLanguage.nepali:    return '🇳🇵';
      case AppLanguage.mizo:      return '🇮🇳';
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

  AppLanguage get language => preferredLanguage;
  set language(AppLanguage val) => preferredLanguage = val;

  // Compatibility aliases
  static PatientProfile? load() => loadFromHive();
  void save() => saveToHive();

  // ── Hive helpers ────────────────────────────────────────────────────────────

  static final ValueNotifier<String?> activeProfileNotifier = ValueNotifier<String?>(null);

  static List<PatientProfile> get defaultDemoProfiles => [
        PatientProfile(
          id: 'patient-ramesh',
          fullName: 'Ramesh Kumar',
          age: 68,
          gender: Gender.male,
          city: 'Assam',
          diagnosis: 'Mild Cognitive Impairment',
          preferredLanguage: AppLanguage.english,
          caregiverName: 'Anita Kumar',
          caregiverPhone: '+919845012345',
          caregiverRelation: 'Daughter',
          registeredAt: DateTime.now(),
          linkCode: 'SAH-9042-RAME',
        ),
        PatientProfile(
          id: 'patient-monalisa',
          fullName: 'Monalisa Barua',
          age: 64,
          gender: Gender.female,
          city: 'Assam',
          diagnosis: 'Early Stage Dementia',
          preferredLanguage: AppLanguage.hindi,
          caregiverName: 'Pranab Barua',
          caregiverPhone: '+919435012345',
          caregiverRelation: 'Son',
          registeredAt: DateTime.now(),
          linkCode: 'SAH-8812-MONA',
        ),
        PatientProfile(
          id: 'patient-tenzin',
          fullName: 'Tenzin Dorjee',
          age: 72,
          gender: Gender.male,
          city: 'Arunachal Pradesh',
          diagnosis: 'Postural & Kinematic Stability Monitoring',
          preferredLanguage: AppLanguage.english,
          caregiverName: 'Pema Dorjee',
          caregiverPhone: '+919862012345',
          caregiverRelation: 'Spouse',
          registeredAt: DateTime.now(),
          linkCode: 'SAH-7631-TENZ',
        ),
      ];

  static List<PatientProfile> loadAllFromHive() {
    try {
      final box = Hive.box('user_preferences');
      final savedList = box.get('saved_profiles');
      if (savedList != null && savedList is List && savedList.isNotEmpty) {
        return savedList
            .map((e) => PatientProfile.fromMap(Map<dynamic, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    final defaults = defaultDemoProfiles;
    saveAllToHive(defaults);
    try {
      final box = Hive.box('user_preferences');
      if (box.get('active_patient_id') == null) {
        box.put('active_patient_id', defaults.first.id);
      }
    } catch (_) {}
    return defaults;
  }

  static void saveAllToHive(List<PatientProfile> profiles) {
    try {
      final box = Hive.box('user_preferences');
      final listMap = profiles.map((e) => e.toMap()).toList();
      box.put('saved_profiles', listMap);
    } catch (_) {}
  }

  static PatientProfile? loadFromHive() {
    try {
      final all = loadAllFromHive();
      if (all.isEmpty) return null;

      final box = Hive.box('user_preferences');
      final activeId = box.get('active_patient_id') as String?;
      if (activeId != null) {
        final match = all.firstWhere((p) => p.id == activeId, orElse: () => all.first);
        return match;
      }
      return all.first;
    } catch (_) {}
    return null;
  }

  static void setActiveProfile(String id) {
    try {
      final box = Hive.box('user_preferences');
      box.put('active_patient_id', id);
      activeProfileNotifier.value = id;
    } catch (_) {}
  }

  void saveToHive() {
    try {
      final all = loadAllFromHive();
      final existingIdx = all.indexWhere((p) => p.id == id);
      if (existingIdx != -1) {
        all[existingIdx] = this;
      } else {
        all.add(this);
      }
      saveAllToHive(all);
      setActiveProfile(id);
    } catch (_) {}
  }

  static void deleteProfileFromHive(String id) {
    try {
      final all = loadAllFromHive();
      all.removeWhere((p) => p.id == id);
      saveAllToHive(all);

      final box = Hive.box('user_preferences');
      final activeId = box.get('active_patient_id');
      if (activeId == id) {
        if (all.isNotEmpty) {
          setActiveProfile(all.first.id);
        } else {
          box.delete('active_patient_id');
          activeProfileNotifier.value = null;
        }
      } else {
        activeProfileNotifier.value = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (_) {}
  }

  static void clearFromHive() {
    try {
      final box = Hive.box('user_preferences');
      box.delete('saved_profiles');
      box.delete('active_patient_id');
      box.delete('patient_profile');
      activeProfileNotifier.value = null;
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

/// Clinical Doctor Feedback & Prescribed Care Directives
class DoctorFeedback {
  final String id;
  final String patientId;
  final String doctorName;
  final String hospitalOrClinic;
  final String specialty;
  final String clinicalImpression; // 'Stable & Responsive', 'Positive Cognitive Trajectory', 'Mild Attentional Fluctuations', 'Review Recommended'
  final String feedbackNotes;
  final List<String> prescribedDirectives;
  final String recommendedDifficulty; // 'Level 1 (Gentle)', 'Level 2 (Moderate)', etc.
  final DateTime submittedAt;

  DoctorFeedback({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.hospitalOrClinic,
    required this.specialty,
    required this.clinicalImpression,
    required this.feedbackNotes,
    required this.prescribedDirectives,
    required this.recommendedDifficulty,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'doctorName': doctorName,
        'hospitalOrClinic': hospitalOrClinic,
        'specialty': specialty,
        'clinicalImpression': clinicalImpression,
        'feedbackNotes': feedbackNotes,
        'prescribedDirectives': prescribedDirectives,
        'recommendedDifficulty': recommendedDifficulty,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory DoctorFeedback.fromMap(Map<dynamic, dynamic> map) {
    return DoctorFeedback(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorName: map['doctorName'] ?? 'Dr. A. Sharma, MD',
      hospitalOrClinic: map['hospitalOrClinic'] ?? 'AIIMS Guwahati / Clinical Neurosciences',
      specialty: map['specialty'] ?? 'Geriatric Neurologist',
      clinicalImpression: map['clinicalImpression'] ?? 'Stable & Responsive',
      feedbackNotes: map['feedbackNotes'] ?? '',
      prescribedDirectives: (map['prescribedDirectives'] as List?)?.map((e) => e.toString()).toList() ?? [],
      recommendedDifficulty: map['recommendedDifficulty'] ?? 'Level 2 (Moderate)',
      submittedAt: DateTime.tryParse(map['submittedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // ── Hive Persistence for Doctor Feedback ──
  static final ValueNotifier<int> feedbackNotifier = ValueNotifier<int>(0);

  static List<DoctorFeedback> loadAllFeedback() {
    try {
      final box = Hive.box('user_preferences');
      final saved = box.get('doctor_feedback_list');
      if (saved != null && saved is List && saved.isNotEmpty) {
        return saved.map((e) => DoctorFeedback.fromMap(Map<dynamic, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    final seeded = defaultSeedFeedback;
    saveAllFeedback(seeded);
    return seeded;
  }

  static List<DoctorFeedback> getFeedbackForPatient(String patientId) {
    final all = loadAllFeedback();
    return all.where((f) => f.patientId == patientId).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  static void saveAllFeedback(List<DoctorFeedback> list) {
    try {
      final box = Hive.box('user_preferences');
      final maps = list.map((e) => e.toMap()).toList();
      box.put('doctor_feedback_list', maps);
      feedbackNotifier.value++;
    } catch (_) {}
  }

  static void addFeedback(DoctorFeedback feedback) {
    final all = loadAllFeedback();
    all.insert(0, feedback);
    saveAllFeedback(all);
  }

  static List<DoctorFeedback> get defaultSeedFeedback => [
        DoctorFeedback(
          id: 'df-1',
          patientId: 'patient-ramesh',
          doctorName: 'Dr. Debabrata Goswami, DM',
          hospitalOrClinic: 'Assam Medical College & Hospital',
          specialty: 'Cognitive Neurology & Movement Disorders',
          clinicalImpression: 'Stable & Responsive to Routine',
          feedbackNotes: 'Patient exhibits consistent engagement with memory recall games (average accuracy above 78%). Kinematic tremor variance has remained well stabilized with the ESP32 active utensil. Recommend maintaining the current cognitive exercise cadence.',
          prescribedDirectives: [
            'Maintain daily 15-minute Memory Match and Memory Story sessions.',
            'Keep ESP32 utensil sensor calibrated before meal times.',
            'Continue Donepezil 5mg once daily after breakfast.',
            'Schedule follow-up review in 8 weeks.'
          ],
          recommendedDifficulty: 'Level 2 (Moderate)',
          submittedAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        ),
        DoctorFeedback(
          id: 'df-2',
          patientId: 'patient-monalisa',
          doctorName: 'Dr. Priya Sengupta, MD',
          hospitalOrClinic: 'Guwahati Neurological Institute',
          specialty: 'Geriatric Psychiatry',
          clinicalImpression: 'Mild Attentional Fluctuations',
          feedbackNotes: 'Mild procedural sequence hesitations observed in morning routines. Reminiscence therapy (Memory Lane) shows strong emotional grounding and positive autobiographical speech recall.',
          prescribedDirectives: [
            'Prioritize Memory Lane and Local Language Naming games in the morning hours.',
            'Ensure caregiver assistance during complex procedural sequences.',
            'Hydration check: at least 1.8 liters daily.'
          ],
          recommendedDifficulty: 'Level 1 (Gentle)',
          submittedAt: DateTime.now().subtract(const Duration(days: 4, hours: 2)),
        ),
      ];
}

