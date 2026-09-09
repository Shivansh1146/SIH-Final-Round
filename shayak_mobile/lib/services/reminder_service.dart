import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_item.dart';
import '../models/patient_profile.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'audio_narration_service.dart';
import 'localization_service.dart';
import 'notification_service.dart';

class ReminderService extends ChangeNotifier {
  static final ReminderService instance = ReminderService._internal();
  ReminderService._internal();

  Timer? _ticker;
  List<ReminderItem> _reminders = [];
  final Set<String> _alertedMinuteKeys = {};
  bool _isInitialized = false;

  List<ReminderItem> get reminders => List.unmodifiable(_reminders);

  void initialize(BuildContext context) {
    if (_isInitialized) return;
    _isInitialized = true;

    loadReminders();

    // Check time every 15 seconds
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkPendingAlerts(context);
    });
  }

  void loadReminders() {
    try {
      final box = Hive.box('user_preferences');
      final saved = box.get('saved_reminders');
      if (saved != null && saved is List && saved.isNotEmpty) {
        _reminders = saved
            .map((e) => ReminderItem.fromMap(Map<dynamic, dynamic>.from(e)))
            .toList();
        _sortReminders();
        notifyListeners();
        return;
      }

      // Check if caregiver set care plan items
      final savedCarePlan = box.get('care_plan_items');
      if (savedCarePlan != null && savedCarePlan is List && savedCarePlan.isNotEmpty) {
        final mergedList = <ReminderItem>[];
        for (int i = 0; i < savedCarePlan.length; i++) {
          final item = savedCarePlan[i];
          if (item is Map) {
            final title = item['title']?.toString() ?? 'Routine Activity';
            final timeStr = item['time']?.toString() ?? '09:00 AM';
            final isActive = item['active'] == true;
            final type = item['type']?.toString() ?? 'Medication';
            final freq = item['freq']?.toString() ?? '';

            int hour = 8;
            int minute = 0;
            try {
              final parts = timeStr.split(' ');
              final hm = parts[0].split(':');
              hour = int.tryParse(hm[0]) ?? 8;
              minute = int.tryParse(hm[1]) ?? 0;
              if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
                hour += 12;
              } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
                hour = 0;
              }
            } catch (_) {}

            String emoji = '💊';
            ReminderCategory category = ReminderCategory.medicine;
            if (type == 'Cognitive' || title.toLowerCase().contains('game') || title.toLowerCase().contains('pattern')) {
              emoji = '🧠';
              category = ReminderCategory.activity;
            } else if (type == 'Dietary' || title.toLowerCase().contains('snack') || title.toLowerCase().contains('fruit') || title.toLowerCase().contains('water')) {
              emoji = title.toLowerCase().contains('water') ? '💧' : '🥗';
              category = ReminderCategory.hydration;
            } else if (type == 'Motor Care' || title.toLowerCase().contains('stabilization') || title.toLowerCase().contains('walk')) {
              emoji = title.toLowerCase().contains('walk') ? '🚶' : '🦾';
              category = ReminderCategory.walk;
            }

            if (isActive) {
              mergedList.add(
                ReminderItem(
                  id: 'cp-$i-${title.hashCode}',
                  title: title,
                  time: TimeOfDay(hour: hour, minute: minute),
                  category: category,
                  emoji: emoji,
                  notes: freq,
                  isCompleted: false,
                ),
              );
            }
          }
        }
        if (mergedList.isNotEmpty) {
          _reminders = mergedList;
          _sortReminders();
          saveReminders();
          return;
        }
      }
    } catch (e) {
      debugPrint('[ReminderService] Error loading: $e');
    }

    _reminders = ReminderItem.defaultReminders;
    saveReminders();
  }

  void speakReminder(ReminderItem item) {
    final lang = LocalizationService.instance.currentLanguage;
    final patientName = PatientProfile.loadFromHive()?.fullName.split(' ').first ?? 'Patient';
    final text = LocalizationService.buildReminderSpokenSentence(
      patientName: patientName,
      timeStr: item.formattedTime,
      rawTitle: item.title,
      rawNotes: item.notes,
      overrideLang: lang,
    );
    AudioNarrationService.instance.speak(text, language: lang);
  }

  void triggerTestAlert(BuildContext context) {
    final item = _reminders.isNotEmpty ? _reminders.first : ReminderItem.defaultReminders.first;
    _triggerReminderAlert(context, item);
  }

  void saveReminders() {
    try {
      final box = Hive.box('user_preferences');
      final listMap = _reminders.map((e) => e.toMap()).toList();
      box.put('saved_reminders', listMap);
    } catch (e) {
      debugPrint('[ReminderService] Error saving: $e');
    }
    notifyListeners();
  }

  void addReminder(ReminderItem item) {
    _reminders.add(item);
    _sortReminders();
    saveReminders();
  }

  void updateReminder(ReminderItem item) {
    final idx = _reminders.indexWhere((r) => r.id == item.id);
    if (idx != -1) {
      _reminders[idx] = item;
      _sortReminders();
      saveReminders();
    }
  }

  void toggleComplete(String id) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx].isCompleted = !_reminders[idx].isCompleted;
      saveReminders();
    }
  }

  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    saveReminders();
  }

  void snoozeReminder(String id, int minutes) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final item = _reminders[idx];
      final now = DateTime.now();
      final snoozedTime = now.add(Duration(minutes: minutes));
      _reminders[idx] = item.copyWith(
        time: TimeOfDay(hour: snoozedTime.hour, minute: snoozedTime.minute),
      );
      _sortReminders();
      saveReminders();
    }
  }

  void _sortReminders() {
    _reminders.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
  }

  void _checkPendingAlerts(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    for (final item in _reminders) {
      if (item.isCompleted) continue;

      if (item.time.hour == currentHour && item.time.minute == currentMinute) {
        final key = '${item.id}_${now.year}_${now.month}_${now.day}_${currentHour}_$currentMinute';
        if (!_alertedMinuteKeys.contains(key)) {
          _alertedMinuteKeys.add(key);
          _triggerReminderAlert(context, item);
          break; // Show one alert at a time
        }
      }
    }
  }

  void _triggerReminderAlert(BuildContext context, ReminderItem item) {
    if (!context.mounted) return;

    final lang = LocalizationService.instance.currentLanguage;
    final patientName = PatientProfile.loadFromHive()?.fullName.split(' ').first ?? 'Patient';

    // Real-time audio narration for the alert
    final alertSpeechText = LocalizationService.buildReminderSpokenSentence(
      patientName: patientName,
      timeStr: item.formattedTime,
      rawTitle: item.title,
      rawNotes: item.notes,
      overrideLang: lang,
    );
    AudioNarrationService.instance.speak(alertSpeechText, language: lang);

    final displayTitle = LocalizationService.trReminderTitle(item.title, lang);
    final displayNotes = LocalizationService.trReminderNotes(item.notes, lang);

    NotificationService.instance.showImmediateNotification(
      id: item.id.hashCode,
      title: '⏰ $displayTitle',
      body: alertSpeechText,
      payload: alertSpeechText,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (alertCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing alert badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.sageLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.forestGreen, width: 2.5),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.pastelYellow,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${LocalizationService.tr('reminders', lang).toUpperCase()} • ${item.formattedTime}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.warmTerracotta,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              '${LocalizationService.getTimeGreeting(lang)} $patientName',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              displayTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.forestGreen,
              ),
              textAlign: TextAlign.center,
            ),

            if (displayNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.forestGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayNotes,
                        style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons: Done & Snooze
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AudioNarrationService.instance.stop();
                      snoozeReminder(item.id, 10);
                      Navigator.pop(alertCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Snoozed "$displayTitle" for 10 minutes.', style: GoogleFonts.inter()),
                          backgroundColor: AppTheme.forestGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.snooze_rounded, size: 18),
                    label: Text(
                      'Snooze 10m',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AudioNarrationService.instance.stop();
                      toggleComplete(item.id);
                      Navigator.pop(alertCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Marked "$displayTitle" as completed!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          backgroundColor: AppTheme.forestGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      '✓ Done',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
