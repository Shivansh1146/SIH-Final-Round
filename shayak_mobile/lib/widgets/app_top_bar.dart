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
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
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
                    width: 38,
                    height: 38,
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
                    child: const Center(
                      child: Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.forestGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: '—AI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.warmTerracotta,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextSpanText(
                        text: 'COGNITIVE & MEMORY SUPPORT',
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

          // Right Status Pill & View Switcher
          if (currentMode == AppViewMode.landing) ...[
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
            ),
          ] else ...[
            // Status Pill with Green Dot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                  const SizedBox(width: 8),
                  Text(
                    'Local data  ·  Ramesh Kumar',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Mode Switcher Button
            if (currentMode == AppViewMode.patient)
              OutlinedButton.icon(
                onPressed: () => onModeChanged(AppViewMode.caregiver),
                icon: const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textPrimary),
                label: Text(
                  'Caregiver view',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => onModeChanged(AppViewMode.patient),
                icon: const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textPrimary),
                label: Text(
                  'Patient app',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

class TextSpanText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const TextSpanText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}
