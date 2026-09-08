import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_profile.dart';
import '../services/localization_service.dart';
import '../services/audio_narration_service.dart';
import '../theme/app_theme.dart';

enum AppViewMode { landing, patient, caregiver, register, doctor }

class AppTopBar extends StatelessWidget {
  final AppViewMode currentMode;
  final ValueChanged<AppViewMode> onModeChanged;
  final VoidCallback? onMenuPressed;

  const AppTopBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.onMenuPressed,
  });

  void _showLanguageSwitcherModal(BuildContext context) {
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
                              LocalizationService.tr('preferred_language', currentLang),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LocalizationService.tr('choose_interface_lang', currentLang),
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
                      LocalizationService.tr('choose_lang_desc', currentLang),
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

  void _showProfileSwitcherModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final allProfiles = PatientProfile.loadAllFromHive();
            final activeProfile = PatientProfile.loadFromHive();

            return Dialog(
              backgroundColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Text(
                      'SWITCH PATIENT PROFILE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profiles List
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: allProfiles.map((p) {
                            final isActive = p.id == activeProfile?.id;
                            final avatarEmoji = p.gender == Gender.female ? '👩‍🦳' : '👨‍🦳';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.sageLight.withOpacity(0.5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive ? AppTheme.sageBorder : AppTheme.surfaceBorder.withOpacity(0.5),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Text(avatarEmoji, style: const TextStyle(fontSize: 22)),
                                title: Text(
                                  p.fullName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${p.city ?? "Assam"} · ${p.id}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.forestGreen,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    if (!isActive)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.warmTerracotta),
                                        tooltip: 'Delete profile',
                                        onPressed: () {
                                          PatientProfile.deleteProfileFromHive(p.id);
                                          setDialogState(() {});
                                        },
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  PatientProfile.setActiveProfile(p.id);
                                  if (ctx.mounted) Navigator.pop(dialogCtx);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.surfaceBorder, height: 1),
                    const SizedBox(height: 16),

                    // Add New Patient Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          onModeChanged(AppViewMode.register);
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: Text(
                          'Register New Patient',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTiny = screenWidth < 420;

    return ValueListenableBuilder<String?>(
      valueListenable: PatientProfile.activeProfileNotifier,
      builder: (context, _, __) {
        final profile = PatientProfile.loadFromHive();
        final patientName = profile?.fullName ?? 'Ramesh Kumar';

        return Container(
          height: isMobile ? 60 : 72,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 28.0),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            border: Border(
              bottom: BorderSide(color: AppTheme.surfaceBorder, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              // Hamburger Menu (Mobile)
              if (onMenuPressed != null) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppTheme.forestGreen, size: 22),
                  onPressed: onMenuPressed,
                  tooltip: 'Open menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 2),
              ],

              // Logo & Branding
              InkWell(
                onTap: () => onModeChanged(AppViewMode.landing),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isMobile ? 28 : 38,
                        height: isMobile ? 28 : 38,
                        decoration: BoxDecoration(
                          color: AppTheme.forestGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.forestGreen.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: isMobile ? 14 : 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'SAHAYAK',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isMobile ? 14.0 : 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.forestGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '—AI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isMobile ? 14.0 : 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.warmTerracotta,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile)
                            Text(
                              'COGNITIVE & MEMORY SUPPORT',
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Language Switcher Pill Button
              ValueListenableBuilder<AppLanguage>(
                valueListenable: LocalizationService.languageNotifier,
                builder: (context, lang, _) {
                  return InkWell(
                    onTap: () => _showLanguageSwitcherModal(context),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 12,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 13)),
                          if (!isMobile) ...[
                            const SizedBox(width: 5),
                            Text(
                              lang.displayName.split(' ').first,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 4),

              // Right Status & Actions
              if (currentMode == AppViewMode.landing) ...[
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.touch_app_rounded, color: AppTheme.forestGreen, size: 20),
                    tooltip: 'Start',
                    onPressed: () => onModeChanged(AppViewMode.patient),
                  ),
              ] else ...[
                // Profile Switcher Pill / Chip
                if (screenWidth > 600)
                  InkWell(
                    onTap: () => _showProfileSwitcherModal(context),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.statusGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Local data · $patientName',
                            style: GoogleFonts.inter(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _showProfileSwitcherModal(context),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.statusGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: isTiny ? 45 : 60),
                            child: Text(
                              patientName.split(' ').first,
                              style: GoogleFonts.inter(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!isMobile) ...[
                  const SizedBox(width: 6),
                  // Mode Buttons: Patient, Caregiver, Doctor
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeTab(
                          label: LocalizationService.tr('patient'),
                          icon: Icons.person_rounded,
                          isSelected: currentMode == AppViewMode.patient,
                          onTap: () => onModeChanged(AppViewMode.patient),
                        ),
                        _buildModeTab(
                          label: LocalizationService.tr('caregiver'),
                          icon: Icons.favorite_rounded,
                          isSelected: currentMode == AppViewMode.caregiver,
                          onTap: () => onModeChanged(AppViewMode.caregiver),
                        ),
                        _buildModeTab(
                          label: 'Doctor',
                          icon: Icons.medical_services_rounded,
                          isSelected: currentMode == AppViewMode.doctor,
                          onTap: () => onModeChanged(AppViewMode.doctor),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<AppViewMode>(
                    onSelected: onModeChanged,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    elevation: 6,
                    offset: const Offset(0, 42),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: AppViewMode.patient,
                        child: Row(
                          children: [
                            Icon(Icons.person_rounded, size: 16, color: currentMode == AppViewMode.patient ? AppTheme.forestGreen : AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text('Patient View', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: currentMode == AppViewMode.patient ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: AppViewMode.caregiver,
                        child: Row(
                          children: [
                            Icon(Icons.favorite_rounded, size: 16, color: currentMode == AppViewMode.caregiver ? AppTheme.forestGreen : AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text('Caregiver Portal', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: currentMode == AppViewMode.caregiver ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: AppViewMode.doctor,
                        child: Row(
                          children: [
                            Icon(Icons.medical_services_rounded, size: 16, color: currentMode == AppViewMode.doctor ? const Color(0xFF1D4ED8) : AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text('Doctor Portal', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: currentMode == AppViewMode.doctor ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Icon(
                        currentMode == AppViewMode.doctor
                            ? Icons.medical_services_rounded
                            : (currentMode == AppViewMode.caregiver ? Icons.favorite_rounded : Icons.person_rounded),
                        size: 16,
                        color: currentMode == AppViewMode.doctor ? const Color(0xFF1D4ED8) : AppTheme.forestGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.forestGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
