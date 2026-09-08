import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

class LandingScreen extends StatelessWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const LandingScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            AppTopBar(
              currentMode: AppViewMode.landing,
              onModeChanged: onNavigate,
            ),

            // Hero Main Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 36.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 860;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left Text & CTA Column
                              Expanded(
                                flex: 6,
                                child: _buildLeftHero(context),
                              ),
                              const SizedBox(width: 48),
                              // Right Interactive Preview Card Column
                              Expanded(
                                flex: 5,
                                child: _buildRightPreview(context),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLeftHero(context),
                              const SizedBox(height: 40),
                              Center(child: _buildRightPreview(context)),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftHero(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.sageLight,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.sageBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.forestGreen),
              const SizedBox(width: 6),
              Text(
                'A GENTLE DAILY RHYTHM',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forestGreen,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Giant Heading with stylized terracotta memory.
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 54.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.forestGreen,
              letterSpacing: -1.2,
              height: 1.08,
            ),
            children: [
              const TextSpan(text: 'Support for\n'),
              TextSpan(
                text: 'memory.\n',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.warmTerracotta,
                ),
              ),
              const TextSpan(text: 'Made\nhuman.'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Subtitle
        Text(
          'AI-assisted cognitive activities and memory support designed for everyday moments, with caregivers close by.',
          style: GoogleFonts.inter(
            fontSize: 17.0,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 36),

        // Action Buttons
        Wrap(
          spacing: 16,
          runSpacing: 14,
          children: [
            ElevatedButton(
              onPressed: () => onNavigate(AppViewMode.patient),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open patient app',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => onNavigate(AppViewMode.caregiver),
              icon: const Icon(Icons.favorite_border_rounded, size: 16, color: AppTheme.textPrimary),
              label: Text(
                'Caregiver dashboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightPreview(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background soft gradient ambient glow
        Positioned(
          right: -30,
          top: -20,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.sageLight.withValues(alpha: 0.6),
            ),
          ),
        ),

        // Floating Card Container
        Container(
          width: 420,
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: TODAY, TOGETHER & Leaf badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TODAY, TOGETHER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppTheme.pastelPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Good morning, Ramesh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 20),

              // Inner Card: Next Activity
              InkWell(
                onTap: () => onNavigate(AppViewMode.patient),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: AppTheme.sageBorder.withValues(alpha: 0.7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.pastelPink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text('🧠', style: TextStyle(fontSize: 17)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT ACTIVITY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.forestGreen,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Memory Match',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Find a few familiar objects, one pair at a time.',
                        style: GoogleFonts.inter(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 0.45,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.forestGreen),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '5 minutes',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom 3 Quick Action Chips
              Row(
                children: [
                  Expanded(
                    child: _buildQuickChip(
                      color: AppTheme.warmPeach,
                      emoji: '💊',
                      label: 'Medicine',
                      onTap: () => onNavigate(AppViewMode.patient),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickChip(
                      color: AppTheme.pastelBlue,
                      emoji: '🍽',
                      label: 'Lunch',
                      onTap: () => onNavigate(AppViewMode.patient),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickChip(
                      color: AppTheme.pastelPink,
                      emoji: '🧠',
                      label: 'Activity',
                      onTap: () => onNavigate(AppViewMode.patient),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Floating Bottom Badge: Private by design
        Positioned(
          bottom: -16,
          left: -14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.shield_outlined, size: 16, color: AppTheme.forestGreen),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Private by design',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Works with local data',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip({
    required Color color,
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
