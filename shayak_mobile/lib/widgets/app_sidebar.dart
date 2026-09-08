import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_profile.dart';
import '../services/localization_service.dart';
import '../services/audio_narration_service.dart';
import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  final bool isCaregiver;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback? onResetData;
  final VoidCallback? onHelp;
  final VoidCallback? onAccessibility;

  const AppSidebar({
    super.key,
    required this.isCaregiver,
    required this.selectedIndex,
    required this.onSelectIndex,
    this.onResetData,
    this.onHelp,
    this.onAccessibility,
  });

  @override
  Widget build(BuildContext context) {
    final activeProfile = PatientProfile.loadFromHive();
    final patientName = activeProfile?.fullName ?? (isCaregiver ? 'Care Team' : 'Ramesh Kumar');

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, lang, _) {
        return Container(
          width: 270,
          decoration: const BoxDecoration(
            color: AppTheme.background,
            border: Border(
              right: BorderSide(color: AppTheme.surfaceBorder, width: 1.0),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 16, top: 18, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Signature Brand Logo
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 18, top: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7.5),
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'SAHAYAK',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.forestGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: '—AI',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.warmTerracotta,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Header Card (PATIENT APP / CARE TEAM)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppTheme.sageBorder.withOpacity(0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCaregiver ? LocalizationService.tr('care_team', lang) : LocalizationService.tr('patient_app', lang),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forestGreen,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patientName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCaregiver
                              ? LocalizationService.tr('patient_care_team_sub', lang)
                              : LocalizationService.tr('patient_space_sub', lang),
                          style: GoogleFonts.inter(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Primary Navigation Menu Items
                  if (!isCaregiver) ...[
                    _buildNavItem(context, 0, Icons.home_outlined, LocalizationService.tr('home', lang)),
                    _buildNavItem(context, 1, Icons.psychology_outlined, LocalizationService.tr('games', lang)),
                    _buildNavItem(context, 2, Icons.alarm_outlined, LocalizationService.tr('reminders', lang)),
                    _buildNavItem(context, 3, Icons.bar_chart_rounded, LocalizationService.tr('progress', lang)),
                  ] else ...[
                    _buildNavItem(context, 0, Icons.dashboard_outlined, LocalizationService.tr('overview', lang)),
                    _buildNavItem(context, 1, Icons.calendar_today_outlined, LocalizationService.tr('care_plan', lang)),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 14),

                  // Bottom Action Links
                  _buildActionItem(
                    context,
                    Icons.translate_rounded,
                    'Language: ${lang.flag} ${lang.displayName.split(' ').first}',
                    onTap: () => _showLanguageModal(context),
                  ),
                  const SizedBox(height: 6),
                  _buildActionItem(
                    context,
                    Icons.help_outline_rounded,
                    LocalizationService.tr('help', lang),
                    onTap: onHelp ?? () => _showHelpDialog(context),
                  ),
                  if (!isCaregiver) ...[
                    const SizedBox(height: 6),
                    _buildActionItem(
                      context,
                      Icons.tune_rounded,
                      LocalizationService.tr('accessibility', lang),
                      onTap: onAccessibility ?? () => _showAccessibilityDialog(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            onSelectIndex(index);
          },
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14.0),
              border: isSelected ? Border.all(color: AppTheme.surfaceBorder) : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? AppTheme.forestGreen : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.forestGreen : AppTheme.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isSelected ? AppTheme.forestGreen : AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final currentLang = LocalizationService.instance.currentLanguage;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.forestGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_outline_rounded, color: AppTheme.forestGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gentle Help & Guide',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  Text(
                    'Supportive tips for memory & routines',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.forestGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, color: AppTheme.forestGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SAHAYAK—AI provides a calm, supportive rhythm for memory, motor calm, and daily activities.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.forestGreen, height: 1.35, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _helpRow(Icons.touch_app_rounded, 'Large Touch Targets: Tap anywhere on cards or buttons to begin.'),
              const SizedBox(height: 12),
              _helpRow(Icons.volume_up_rounded, 'Audio Narration: Tap "Listen" anytime to hear instructions read aloud.'),
              const SizedBox(height: 12),
              _helpRow(Icons.language_rounded, 'Multilingual Voice: Switch between English, Hindi, and NER languages in 1-tap.'),
              const SizedBox(height: 12),
              _helpRow(Icons.shield_outlined, 'Private & Local: Your activity metrics and logs stay secure on this device.'),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              const helpSpeech = 'Welcome to the Sahayak guide. Tap anywhere on cards to begin activities. '
                  'Tap Listen anytime to hear instructions spoken aloud. '
                  'You can choose English, Hindi, or North-Eastern regional languages anytime.';
              AudioNarrationService.instance.speak(helpSpeech, language: currentLang);
            },
            icon: const Icon(Icons.volume_up_rounded, size: 18, color: AppTheme.forestGreen),
            label: Text('Read Aloud', style: GoogleFonts.plusJakartaSans(color: AppTheme.forestGreen, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              AudioNarrationService.instance.stop();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Got it', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _helpRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.forestGreen.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppTheme.forestGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13.2, color: AppTheme.textPrimary, height: 1.35),
          ),
        ),
      ],
    );
  }

  void _showAccessibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        Box? prefBox;
        try {
          if (Hive.isBoxOpen('user_preferences')) {
            prefBox = Hive.box('user_preferences');
          }
        } catch (_) {}

        bool textScaling = prefBox?.get('accessibility_text_scale', defaultValue: true) ?? true;
        bool highContrast = prefBox?.get('accessibility_high_contrast', defaultValue: true) ?? true;
        bool tremorFilter = prefBox?.get('accessibility_tremor_filter', defaultValue: true) ?? true;
        bool voicePrompts = prefBox?.get('accessibility_voice_prompts', defaultValue: true) ?? true;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.accessibility_new_rounded, color: AppTheme.forestGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accessibility Settings',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        Text(
                          'Personalize visual & motor assistance',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAccessibilitySwitchTile(
                        icon: Icons.format_size_rounded,
                        title: 'Text Size Scaling',
                        subtitle: textScaling ? 'Comfortable 125% magnification active' : 'Standard 100% text scaling',
                        value: textScaling,
                        onChanged: (val) {
                          setDialogState(() => textScaling = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildAccessibilitySwitchTile(
                        icon: Icons.contrast_rounded,
                        title: 'High Contrast Outlines',
                        subtitle: highContrast ? '2px clear borders on interactive elements' : 'Standard theme borders',
                        value: highContrast,
                        onChanged: (val) {
                          setDialogState(() => highContrast = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildAccessibilitySwitchTile(
                        icon: Icons.vibration_rounded,
                        title: 'Tremor Dampening Filter',
                        subtitle: tremorFilter ? 'Active IMU low-pass sensor filter' : 'Filter disabled (raw touch)',
                        value: tremorFilter,
                        onChanged: (val) {
                          setDialogState(() => tremorFilter = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildAccessibilitySwitchTile(
                        icon: Icons.record_voice_over_rounded,
                        title: 'Voice Narration Prompts',
                        subtitle: voicePrompts ? 'Spoken guidance & reminders enabled' : 'Visual cues only',
                        value: voicePrompts,
                        onChanged: (val) {
                          setDialogState(() => voicePrompts = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (prefBox != null) {
                      await prefBox.put('accessibility_text_scale', textScaling);
                      await prefBox.put('accessibility_high_contrast', highContrast);
                      await prefBox.put('accessibility_tremor_filter', tremorFilter);
                      await prefBox.put('accessibility_voice_prompts', voicePrompts);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Accessibility preferences saved successfully!'),
                            ],
                          ),
                          backgroundColor: AppTheme.forestGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }

                    if (voicePrompts) {
                      AudioNarrationService.instance.speak(
                        'Accessibility settings saved. Visual magnification, high contrast, and tremor dampening filters are updated.',
                      );
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  label: Text('Save Settings', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAccessibilitySwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? AppTheme.sageLight.withOpacity(0.5) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppTheme.forestGreen.withOpacity(0.3) : AppTheme.surfaceBorder,
          width: 1.2,
        ),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.forestGreen,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? AppTheme.forestGreen.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: value ? AppTheme.forestGreen : AppTheme.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: value ? AppTheme.forestGreen : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentLang = LocalizationService.instance.currentLanguage;

            return Dialog(
              backgroundColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PREFERRED LANGUAGE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose Interface Language',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.forestGreen,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'All reminders, instructions, audio speech, and games adapt to your selected language.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        child: Column(
                          children: AppLanguage.values.map((lang) {
                            final isSel = lang == currentLang;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.sageLight : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel ? AppTheme.forestGreen : AppTheme.surfaceBorder,
                                  width: isSel ? 1.8 : 1,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                leading: Text(lang.flag, style: const TextStyle(fontSize: 20)),
                                title: Text(
                                  lang.displayName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel ? AppTheme.forestGreen : AppTheme.textPrimary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, size: 18, color: AppTheme.forestGreen),
                                      tooltip: 'Voice preview',
                                      onPressed: () {
                                        final greeting = LocalizationService.getLanguageWelcomeSpeech(lang);
                                        AudioNarrationService.instance.speak(greeting, language: lang);
                                      },
                                    ),
                                    if (isSel)
                                      const Icon(Icons.check_circle_rounded, color: AppTheme.forestGreen, size: 20),
                                  ],
                                ),
                                onTap: () {
                                  LocalizationService.instance.setLanguage(lang, speakPreview: true);
                                  setDialogState(() {});
                                  Future.delayed(const Duration(milliseconds: 400), () {
                                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
