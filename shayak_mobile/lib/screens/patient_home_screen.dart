import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_sidebar.dart';
import 'memory_match_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const PatientHomeScreen({super.key, required this.onNavigate});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  bool _isPlayingAudio = false;

  void _playListenAudio() {
    setState(() => _isPlayingAudio = true);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Audio Narration Active',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
            ),
            const SizedBox(height: 10),
            Text(
              '"Good morning, Ramesh. Today’s gentle activity is Memory Match. Find matching pairs at your own pace. There is no rush."',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() => _isPlayingAudio = false);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestGreen),
              child: const Text('Close Audio'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo activity data refreshed.', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onTabSelected(int idx) {
    setState(() => _selectedIndex = idx);
    if (idx == 1) {
      _startMemoryMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            AppTopBar(
              currentMode: AppViewMode.patient,
              onModeChanged: widget.onNavigate,
            ),

            // Content Area (Responsive)
            Expanded(
              child: isMobile
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: _buildPatientContent(context, isMobile: true),
                    )
                  : Row(
                      children: [
                        // Left Desktop/Tablet Navigation Sidebar
                        AppSidebar(
                          isCaregiver: false,
                          selectedIndex: _selectedIndex,
                          onSelectIndex: _onTabSelected,
                          onResetData: _resetData,
                        ),

                        // Main Content Area
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 960),
                                child: _buildPatientContent(context, isMobile: false),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1.0)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTabSelected,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppTheme.forestGreen,
                unselectedItemColor: AppTheme.textSecondary,
                selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.psychology_outlined),
                    activeIcon: Icon(Icons.psychology_rounded),
                    label: 'Games',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_awesome_outlined),
                    activeIcon: Icon(Icons.auto_awesome_rounded),
                    label: 'Reminders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_outlined),
                    activeIcon: Icon(Icons.grid_view_rounded),
                    label: 'Progress',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildPatientContent(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting Header & Action Buttons Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 14.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Ramesh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 26.0 : 34.0,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('🌿', style: TextStyle(fontSize: isMobile ? 22 : 28)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A calm start makes room for a good memory.',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 13.0 : 14.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Right Actions: Listen & Adjust
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _playListenAudio,
                  icon: Icon(
                    _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    size: 15,
                    color: AppTheme.forestGreen,
                  ),
                  label: Text(
                    'Listen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 12.0 : 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 6 : 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: isMobile ? 32 : 38,
                  height: isMobile ? 32 : 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.tune_rounded, size: isMobile ? 15 : 17, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: isMobile ? 16 : 24),

        // Hero Today's Activity Banner
        _buildHeroActivityBanner(context, isMobile: isMobile),

        SizedBox(height: isMobile ? 16 : 24),

        // Bottom Grid: Reminders & Need Help
        if (isMobile) ...[
          _buildRemindersCard(context),
          const SizedBox(height: 14),
          _buildNeedHelpCard(context),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRemindersCard(context)),
              const SizedBox(width: 20),
              Expanded(child: _buildNeedHelpCard(context)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeroActivityBanner(BuildContext context, {required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20.0 : 28.0),
      decoration: BoxDecoration(
        color: AppTheme.forestTealCard,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative rings
          Positioned(
            right: -20,
            top: -30,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 24),
                ),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Activity Info
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            "TODAY'S ACTIVITY",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Memory Match',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 24.0 : 30.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Find the matching pairs. Take your time — one card at a time.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 13.0 : 14.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          'About 5 mins',
                          style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        const Text('·', style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        Text(
                          'Level 3',
                          style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 16 : 22),

                    // Start Activity Button
                    ElevatedButton(
                      onPressed: _startMemoryMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warmPeach,
                        foregroundColor: AppTheme.textPrimary,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 24, vertical: isMobile ? 10 : 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start activity',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 13.5 : 15.0,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 15, color: AppTheme.textPrimary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right 3D Brain Visual
              Container(
                width: isMobile ? 80 : 120,
                height: isMobile ? 80 : 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    width: isMobile ? 54 : 76,
                    height: isMobile ? 54 : 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF94B8), Color(0xFFFF4081)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4081).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('🧠', style: TextStyle(fontSize: isMobile ? 28 : 38)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reminders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reminder List Item
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('💊', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Morning medicine',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '08:00',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.notifications_none_rounded, size: 17, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.pastelYellow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.warmTerracotta)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Need a little help?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'You can listen to instructions, take a pause, or ask a caregiver for assistance anytime.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connected to Caregiver Anita.', style: GoogleFonts.inter()),
                  backgroundColor: AppTheme.forestGreen,
                ),
              );
            },
            icon: const Icon(Icons.phone_in_talk_rounded, size: 14, color: AppTheme.forestGreen),
            label: Text(
              'Call Caregiver Anita',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.forestGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _startMemoryMatch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MemoryMatchScreen(
          onFinish: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}
