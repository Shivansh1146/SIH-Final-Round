import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_profile.dart';
import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  final bool isCaregiver;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onResetData;
  final VoidCallback? onHelp;
  final VoidCallback? onAccessibility;

  const AppSidebar({
    super.key,
    required this.isCaregiver,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.onResetData,
    this.onHelp,
    this.onAccessibility,
  });

  @override
  Widget build(BuildContext context) {
    final activeProfile = PatientProfile.loadFromHive();
    final patientName = activeProfile?.fullName ?? (isCaregiver ? 'Care Team' : 'Ramesh Kumar');

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
                      isCaregiver ? 'CARE TEAM' : 'PATIENT APP',
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
                          ? 'Understand patterns, support with confidence.'
                          : 'A gentle space for daily activities.',
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
                _buildNavItem(context, 0, Icons.home_outlined, 'Home'),
                _buildNavItem(context, 1, Icons.psychology_outlined, 'Games'),
                _buildNavItem(context, 2, Icons.alarm_outlined, 'Reminders'),
                _buildNavItem(context, 3, Icons.bar_chart_rounded, 'Progress'),
              ] else ...[
                _buildNavItem(context, 0, Icons.dashboard_outlined, 'Overview'),
                _buildNavItem(context, 1, Icons.auto_awesome_outlined, 'AI decisions'),
                _buildNavItem(context, 2, Icons.calendar_today_outlined, 'Care plan'),
                _buildNavItem(context, 3, Icons.sensors_rounded, 'ESP32 Device'),
              ],

              const SizedBox(height: 24),
              const Divider(color: AppTheme.surfaceBorder, height: 1),
              const SizedBox(height: 14),

              // Bottom Action Links
              _buildActionItem(
                context,
                Icons.help_outline_rounded,
                'Help',
                onTap: onHelp ?? () => _showHelpDialog(context),
              ),
              if (!isCaregiver) ...[
                const SizedBox(height: 6),
                _buildActionItem(
                  context,
                  Icons.tune_rounded,
                  'Accessibility',
                  onTap: onAccessibility ?? () => _showAccessibilityDialog(context),
                ),
              ],
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  }
                  onResetData();
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_fix_high_rounded,
                        size: 16,
                        color: AppTheme.warmTerracotta,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Reset demo data',
                        style: GoogleFonts.inter(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warmTerracotta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppTheme.forestGreen),
            const SizedBox(width: 10),
            Text('Gentle Help & Guide', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SHAYAK-AI provides a calm, supportive rhythm for memory and daily cognitive activities.',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            _helpRow(Icons.touch_app_rounded, 'Large Touch Targets: Tap anywhere on cards to begin.'),
            const SizedBox(height: 10),
            _helpRow(Icons.volume_up_rounded, 'Audio Narration: Tap "Listen" anytime to hear instructions read aloud.'),
            const SizedBox(height: 10),
            _helpRow(Icons.shield_outlined, 'Private & Local: Your activity metrics stay on this device.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestGreen),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _helpRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.forestGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }

  void _showAccessibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Accessibility Settings', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.format_size_rounded, color: AppTheme.forestGreen),
              title: Text('Text Size Scaling'),
              subtitle: Text('Comfortable 125% magnification active'),
              trailing: Icon(Icons.check_circle_rounded, color: AppTheme.statusGreen),
            ),
            ListTile(
              leading: Icon(Icons.contrast_rounded, color: AppTheme.forestGreen),
              title: Text('High Contrast Outlines'),
              subtitle: Text('2px clear borders on interactive elements'),
              trailing: Icon(Icons.check_circle_rounded, color: AppTheme.statusGreen),
            ),
            ListTile(
              leading: Icon(Icons.vibration_rounded, color: AppTheme.forestGreen),
              title: Text('Tremor Dampening Filter'),
              subtitle: Text('Active IMU low-pass sensor filter'),
              trailing: Icon(Icons.check_circle_rounded, color: AppTheme.statusGreen),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestGreen),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
