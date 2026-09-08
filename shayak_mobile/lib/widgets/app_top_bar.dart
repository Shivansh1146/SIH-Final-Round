import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum AppViewMode { landing, patient, caregiver }

class AppTopBar extends StatelessWidget {
  final AppViewMode currentMode;
  final ValueChanged<AppViewMode> onModeChanged;

  const AppTopBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 680;

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
                              text: 'SHAYAK',
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
            // Status Pill with Green Dot (hidden on very small phones)
            if (screenWidth > 540) ...[
              Container(
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
                      'Ramesh Kumar',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
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
  }
}
