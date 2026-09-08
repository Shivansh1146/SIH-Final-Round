import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_profile.dart';
import '../theme/app_theme.dart';

enum AppViewMode { landing, patient, caregiver, register }

class AppTopBar extends StatelessWidget {
  final AppViewMode currentMode;
  final ValueChanged<AppViewMode> onModeChanged;

  const AppTopBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

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
                                    ? AppTheme.sageLight.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive ? AppTheme.sageBorder : AppTheme.surfaceBorder.withValues(alpha: 0.5),
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
                                      const Icon(
                                        Icons.check_rounded,
                                        color: AppTheme.forestGreen,
                                        size: 18,
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.textLight,
                                        size: 18,
                                      ),
                                      tooltip: 'Delete Profile',
                                      onPressed: () {
                                        PatientProfile.deleteProfileFromHive(p.id);
                                        setDialogState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  PatientProfile.setActiveProfile(p.id);
                                  Navigator.pop(dialogCtx);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const Divider(height: 24, color: AppTheme.surfaceBorder),

                    // Action: Register New Patient
                    InkWell(
                      onTap: () {
                        Navigator.pop(dialogCtx);
                        onModeChanged(AppViewMode.register);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.person_add_outlined, color: AppTheme.forestGreen, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '+ Register New Patient',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.forestGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action: Manage & Delete IDs
                    InkWell(
                      onTap: () {
                        setDialogState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline_rounded, color: AppTheme.textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Manage & Delete IDs',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
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
    final isMobile = screenWidth < 680;

    return ValueListenableBuilder<String?>(
      valueListenable: PatientProfile.activeProfileNotifier,
      builder: (context, _, __) {
        final profile = PatientProfile.loadFromHive();
        final patientName = profile?.fullName ?? 'Ramesh Kumar';

        return Container(
          height: isMobile ? 64 : 72,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 28.0),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            border: Border(
              bottom: BorderSide(color: AppTheme.surfaceBorder, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              // Logo & Branding
              InkWell(
                onTap: () => onModeChanged(AppViewMode.landing),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Container(
                        width: isMobile ? 32 : 38,
                        height: isMobile ? 32 : 38,
                        decoration: BoxDecoration(
                          color: AppTheme.forestGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.forestGreen.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: isMobile ? 16 : 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                                    fontSize: isMobile ? 15 : 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.forestGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '—AI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isMobile ? 15 : 17,
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

              // Right Status & Actions (Mobile Adaptive)
              if (currentMode == AppViewMode.landing) ...[
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      'Demo mode · local data',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.touch_app_rounded, color: AppTheme.forestGreen, size: 20),
                    tooltip: 'Start',
                    onPressed: () => onModeChanged(AppViewMode.patient),
                  ),
              ] else ...[
                // Status Pill with Green Dot (Clickable for Switcher)
                if (screenWidth > 540) ...[
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
                  ),
                  const SizedBox(width: 8),
                ],

                // Mode Switcher Button
                if (currentMode == AppViewMode.patient)
                  OutlinedButton.icon(
                    onPressed: () => onModeChanged(AppViewMode.caregiver),
                    icon: const Icon(Icons.person_outline_rounded, size: 15, color: AppTheme.textPrimary),
                    label: Text(
                      isMobile ? 'Caregiver' : 'Caregiver view',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 12.0 : 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 6 : 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => onModeChanged(AppViewMode.patient),
                    icon: const Icon(Icons.person_outline_rounded, size: 15, color: AppTheme.textPrimary),
                    label: Text(
                      isMobile ? 'Patient' : 'Patient app',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 12.0 : 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 6 : 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
