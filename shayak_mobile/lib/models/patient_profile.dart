import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

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
          medicalNotes: 'Hypertension controlled on Amlodipine 5mg. Mild short-term memory lapses noticed since 6 months. High adherence to memory training and active utensil usage.',
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
          medicalNotes: 'Autobiographical reminiscing (Memory Lane) highly effective. Attentional fluctuations in mornings. No history of stroke or focal neurological deficits.',
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
          medicalNotes: 'Postural tremors stabilized with adaptive utensil. Gait evaluation shows slight bradykinesia. Recommend daily balance and visual search drills.',
          registeredAt: DateTime.now(),
          linkCode: 'SAH-7631-TENZ',
        ),
      ];

  static List<PatientProfile> loadAllFromHive() {
    try {
      final box = Hive.box('user_preferences');
      final savedList = box.get('saved_profiles');
      if (savedList != null && savedList is List && savedList.isNotEmpty) {
        final loaded = savedList
            .map((e) => PatientProfile.fromMap(Map<dynamic, dynamic>.from(e)))
            .toList();
        
        // Auto-migrate missing medicalNotes or caregiver data from default demo profiles
        bool updated = false;
        for (final def in defaultDemoProfiles) {
          final idx = loaded.indexWhere((p) => p.id == def.id);
          if (idx != -1) {
            final p = loaded[idx];
            bool changed = false;
            if ((p.medicalNotes == null || p.medicalNotes!.isEmpty) && def.medicalNotes != null) {
              p.medicalNotes = def.medicalNotes;
              changed = true;
            }
            if ((p.caregiverName == null || p.caregiverName!.isEmpty) && def.caregiverName != null) {
              p.caregiverName = def.caregiverName;
              changed = true;
            }
            if ((p.caregiverPhone == null || p.caregiverPhone!.isEmpty) && def.caregiverPhone != null) {
              p.caregiverPhone = def.caregiverPhone;
              changed = true;
            }
            if ((p.caregiverRelation == null || p.caregiverRelation!.isEmpty) && def.caregiverRelation != null) {
              p.caregiverRelation = def.caregiverRelation;
              changed = true;
            }
            if (changed) {
              loaded[idx] = p;
              updated = true;
            }
          }
        }
        if (updated) {
          saveAllToHive(loaded);
        }
        return loaded;
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

    // Sync to backend
    try {
      http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': feedback.id,
          'patient_id': feedback.patientId,
          'doctor_name': feedback.doctorName,
          'hospital_or_clinic': feedback.hospitalOrClinic,
          'specialty': feedback.specialty,
          'clinical_impression': feedback.clinicalImpression,
          'feedback_notes': feedback.feedbackNotes,
          'prescribed_directives': feedback.prescribedDirectives,
          'recommended_difficulty': feedback.recommendedDifficulty,
          'submitted_at': feedback.submittedAt.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
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

/// ============================================================================
/// DOCTOR APPOINTMENT BOOKING MODEL
/// Caregivers can book clinical appointments directly, syncing immediately
/// to the Doctor Dashboard and Caregiver Calendar with real-time status.
/// ============================================================================
class DoctorAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final String clinicOrHospital;
  final String appointmentType; // 'In-Person Consultation', 'Telehealth Video Review', 'Cognitive Assessment'
  final DateTime scheduledDate;
  final String timeSlot; // e.g. '10:30 AM', '02:00 PM'
  final String caregiverName;
  final String caregiverPhone;
  final String reasonForVisit;
  final String status; // 'Confirmed', 'Pending Review', 'Completed', 'Rescheduled'
  final String? doctorFeedbackForCaregiver; // Feedback left by doctor specifically for caregiver on this appointment
  final DateTime bookedAt;

  DoctorAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.clinicOrHospital,
    required this.appointmentType,
    required this.scheduledDate,
    required this.timeSlot,
    required this.caregiverName,
    required this.caregiverPhone,
    required this.reasonForVisit,
    this.status = 'Confirmed',
    this.doctorFeedbackForCaregiver,
    required this.bookedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'doctorName': doctorName,
        'clinicOrHospital': clinicOrHospital,
        'appointmentType': appointmentType,
        'scheduledDate': scheduledDate.toIso8601String(),
        'timeSlot': timeSlot,
        'caregiverName': caregiverName,
        'caregiverPhone': caregiverPhone,
        'reasonForVisit': reasonForVisit,
        'status': status,
        'doctorFeedbackForCaregiver': doctorFeedbackForCaregiver,
        'bookedAt': bookedAt.toIso8601String(),
      };

  factory DoctorAppointment.fromMap(Map<dynamic, dynamic> map) {
    return DoctorAppointment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Patient',
      doctorName: map['doctorName'] ?? 'Dr. Debabrata Goswami, DM',
      clinicOrHospital: map['clinicOrHospital'] ?? 'Assam Medical College & Hospital',
      appointmentType: map['appointmentType'] ?? 'In-Person Consultation',
      scheduledDate: DateTime.tryParse(map['scheduledDate'] ?? '') ?? DateTime.now().add(const Duration(days: 2)),
      timeSlot: map['timeSlot'] ?? '10:30 AM',
      caregiverName: map['caregiverName'] ?? 'Caregiver',
      caregiverPhone: map['caregiverPhone'] ?? '+91 98450 12345',
      reasonForVisit: map['reasonForVisit'] ?? 'Routine Neuro-Geriatric Progress Evaluation',
      status: map['status'] ?? 'Confirmed',
      doctorFeedbackForCaregiver: map['doctorFeedbackForCaregiver'],
      bookedAt: DateTime.tryParse(map['bookedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // ── Hive Persistence for Appointments ──
  static final ValueNotifier<int> appointmentNotifier = ValueNotifier<int>(0);

  static List<DoctorAppointment> loadAllAppointments() {
    try {
      final box = Hive.box('user_preferences');
      final saved = box.get('doctor_appointments_list');
      if (saved != null && saved is List && saved.isNotEmpty) {
        return saved.map((e) => DoctorAppointment.fromMap(Map<dynamic, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    final seeded = defaultSeedAppointments;
    saveAllAppointments(seeded);
    return seeded;
  }

  static List<DoctorAppointment> getAppointmentsForPatient(String patientId) {
    final all = loadAllAppointments();
    return all.where((a) => a.patientId == patientId).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  static void saveAllAppointments(List<DoctorAppointment> list) {
    try {
      final box = Hive.box('user_preferences');
      final maps = list.map((e) => e.toMap()).toList();
      box.put('doctor_appointments_list', maps);
      appointmentNotifier.value++;
    } catch (_) {}
  }

  static void bookAppointment(DoctorAppointment appointment) {
    final all = loadAllAppointments();
    all.insert(0, appointment);
    saveAllAppointments(all);

    // Sync to backend
    try {
      http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': appointment.id,
          'patient_id': appointment.patientId,
          'patient_name': appointment.patientName,
          'doctor_name': appointment.doctorName,
          'clinic_or_hospital': appointment.clinicOrHospital,
          'appointment_type': appointment.appointmentType,
          'scheduled_date': appointment.scheduledDate.toIso8601String(),
          'time_slot': appointment.timeSlot,
          'caregiver_name': appointment.caregiverName,
          'caregiver_phone': appointment.caregiverPhone,
          'reason_for_visit': appointment.reasonForVisit,
          'status': appointment.status,
          'doctor_feedback_for_caregiver': appointment.doctorFeedbackForCaregiver,
          'booked_at': appointment.bookedAt.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static void updateStatus(String appointmentId, String newStatus) {
    final all = loadAllAppointments();
    final idx = all.indexWhere((a) => a.id == appointmentId);
    if (idx != -1) {
      final old = all[idx];
      all[idx] = DoctorAppointment(
        id: old.id,
        patientId: old.patientId,
        patientName: old.patientName,
        doctorName: old.doctorName,
        clinicOrHospital: old.clinicOrHospital,
        appointmentType: old.appointmentType,
        scheduledDate: old.scheduledDate,
        timeSlot: old.timeSlot,
        caregiverName: old.caregiverName,
        caregiverPhone: old.caregiverPhone,
        reasonForVisit: old.reasonForVisit,
        status: newStatus,
        doctorFeedbackForCaregiver: old.doctorFeedbackForCaregiver,
        bookedAt: old.bookedAt,
      );
      saveAllAppointments(all);

      // Sync status to backend
      try {
        http.patch(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/appointments/$appointmentId/status?new_status=$newStatus'),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }

  static void updateFeedback(String appointmentId, String feedbackNote) {
    final all = loadAllAppointments();
    final idx = all.indexWhere((a) => a.id == appointmentId);
    if (idx != -1) {
      final old = all[idx];
      all[idx] = DoctorAppointment(
        id: old.id,
        patientId: old.patientId,
        patientName: old.patientName,
        doctorName: old.doctorName,
        clinicOrHospital: old.clinicOrHospital,
        appointmentType: old.appointmentType,
        scheduledDate: old.scheduledDate,
        timeSlot: old.timeSlot,
        caregiverName: old.caregiverName,
        caregiverPhone: old.caregiverPhone,
        reasonForVisit: old.reasonForVisit,
        status: old.status,
        doctorFeedbackForCaregiver: feedbackNote,
        bookedAt: old.bookedAt,
      );
      saveAllAppointments(all);

      // Sync caregiver feedback to backend
      try {
        http.patch(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/appointments/$appointmentId/feedback'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'doctor_feedback_for_caregiver': feedbackNote,
            'status': old.status,
          }),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }

  static List<DoctorAppointment> get defaultSeedAppointments => [
        DoctorAppointment(
          id: 'apt-1',
          patientId: 'patient-ramesh',
          patientName: 'Ramesh Kumar',
          doctorName: 'Dr. Debabrata Goswami, DM',
          clinicOrHospital: 'Assam Medical College & Hospital',
          appointmentType: 'In-Person Neuro Consultation',
          scheduledDate: DateTime.now().add(const Duration(days: 3)),
          timeSlot: '11:00 AM',
          caregiverName: 'Anita Kumar',
          caregiverPhone: '+91 98450 12345',
          reasonForVisit: 'Bi-monthly cognitive progression review and ESP32 kinematic utensil stability check.',
          status: 'Confirmed',
          doctorFeedbackForCaregiver: 'Confirmed for 11:00 AM. Please bring the ESP32 utensil usage logs and ensure Ramesh had a light breakfast.',
          bookedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DoctorAppointment(
          id: 'apt-2',
          patientId: 'patient-monalisa',
          patientName: 'Monalisa Barua',
          doctorName: 'Dr. Priya Sengupta, MD',
          clinicOrHospital: 'Guwahati Neurological Institute',
          appointmentType: 'Telehealth Video Review',
          scheduledDate: DateTime.now().add(const Duration(days: 5)),
          timeSlot: '02:30 PM',
          caregiverName: 'Pranab Barua',
          caregiverPhone: '+91 94350 12345',
          reasonForVisit: 'Follow-up on morning routine orientation and Memory Lane recall progress.',
          status: 'Confirmed',
          bookedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
}


