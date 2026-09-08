import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_profile.dart';
import '../models/reminder_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_sidebar.dart';
import 'memory_match_screen.dart';
import 'reminders_screen.dart';
import 'clock_canvas_screen.dart';
import '../services/reminder_service.dart';
import '../services/audio_narration_service.dart';

class PatientHomeScreen extends StatefulWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const PatientHomeScreen({super.key, required this.onNavigate});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  bool _isPlayingAudio = false;
  late List<ReminderItem> _reminders;
  PatientProfile? _profile;

  // Convenience getters that fall back gracefully
  String get _patientFirstName =>
      _profile?.fullName.split(' ').first ?? 'Ramesh';
  String get _patientFullName => _profile?.fullName ?? 'Ramesh Kumar';

  @override
  void initState() {
    super.initState();
    _profile = PatientProfile.loadFromHive();
    _loadReminders();
    ReminderService.instance.addListener(_onReminderServiceChanged);
    PatientProfile.activeProfileNotifier.addListener(_onActiveProfileChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ReminderService.instance.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    ReminderService.instance.removeListener(_onReminderServiceChanged);
    PatientProfile.activeProfileNotifier.removeListener(_onActiveProfileChanged);
    super.dispose();
  }

  void _onActiveProfileChanged() {
    if (mounted) {
      setState(() {
        _profile = PatientProfile.loadFromHive();
      });
    }
  }

  void _onReminderServiceChanged() {
    if (mounted) {
      setState(() {
        _loadReminders();
      });
    }
  }

  void _loadReminders() {
    try {
      final box = Hive.box('user_preferences');
      final saved = box.get('saved_reminders');
      if (saved != null && saved is List) {
        _reminders = saved.map((e) => ReminderItem.fromMap(Map<dynamic, dynamic>.from(e))).toList();
        return;
      }
    } catch (_) {}
    _reminders = ReminderItem.defaultReminders;
  }

  void _playListenAudio() {
    setState(() => _isPlayingAudio = true);
    final narrationText = "Good morning, $_patientFirstName. Today's gentle activity is Memory Match. Find matching pairs at your own pace. There is no rush.";
    AudioNarrationService.instance.speak(narrationText);

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
              '"$narrationText"',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                AudioNarrationService.instance.stop();
                setState(() => _isPlayingAudio = false);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestGreen),
              child: const Text('Stop Audio'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetData() {
    setState(() {
      _reminders = ReminderItem.defaultReminders;
    });
    try {
      final box = Hive.box('user_preferences');
      box.delete('saved_reminders');
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo activity data & reminders refreshed.', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onTabSelected(int idx) {
    setState(() => _selectedIndex = idx);
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
                      child: _buildActiveView(context, isMobile: true),
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
                                child: _buildActiveView(context, isMobile: false),
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

  Widget _buildActiveView(BuildContext context, {required bool isMobile}) {
    switch (_selectedIndex) {
      case 0:
        return _buildPatientHomeContent(context, isMobile: isMobile);
      case 1:
        return _buildGamesMenuContent(context, isMobile: isMobile);
      case 2:
        return RemindersScreen(
          reminders: _reminders,
          onRemindersUpdated: (updated) {
            setState(() => _reminders = updated);
          },
        );
      case 3:
        return _buildProgressSummaryContent(context, isMobile: isMobile);
      default:
        return _buildPatientHomeContent(context, isMobile: isMobile);
    }
  }

  Widget _buildPatientHomeContent(BuildContext context, {required bool isMobile}) {
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
                        _patientFirstName,
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
          _buildRemindersSummaryCard(context),
          const SizedBox(height: 14),
          _buildNeedHelpCard(context),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRemindersSummaryCard(context)),
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

  Widget _buildRemindersSummaryCard(BuildContext context) {
    final pending = _reminders.where((e) => !e.isCompleted).toList();
    final firstItem = pending.isNotEmpty ? pending.first : (_reminders.isNotEmpty ? _reminders.first : null);

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
                onPressed: () {
                  setState(() => _selectedIndex = 2);
                },
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

          if (firstItem != null)
            InkWell(
              onTap: () {
                setState(() => _selectedIndex = 2);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
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
                      child: Center(
                        child: Text(firstItem.emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              decoration: firstItem.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text(
                            firstItem.formattedTime,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      firstItem.isCompleted ? Icons.check_circle_rounded : Icons.notifications_none_rounded,
                      size: 17,
                      color: firstItem.isCompleted ? AppTheme.statusGreen : AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              'No reminders set for today.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
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
            onPressed: () => _showConnectCaregiverModal(context),
            icon: const Icon(Icons.favorite_rounded, size: 14, color: AppTheme.warmTerracotta),
            label: Text(
              'Connect to Caregiver',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.warmTerracotta,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.warmPeachDark),
              backgroundColor: AppTheme.warmPeach,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectCaregiverModal(BuildContext context) {
    bool _isCalling = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 8,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.warmPeach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppTheme.warmTerracotta, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect to Caregiver',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        Text(
                          'Reach your caregiver instantly',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Caregiver Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.sageBorder),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.forestTealCard,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text('👩‍⚕️', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anita Sharma',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Primary Caregiver · Family',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.statusGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Available now',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5, fontWeight: FontWeight.w600,
                                  color: AppTheme.statusGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  // Call Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setModalState(() => _isCalling = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Text('Calling Anita Sharma…', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              backgroundColor: AppTheme.forestGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        });
                      },
                      icon: _isCalling
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.phone_rounded, size: 18),
                      label: Text(
                        _isCalling ? 'Calling…' : 'Call Now',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Message Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message sent to Anita Sharma ✓', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            backgroundColor: AppTheme.forestGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                      label: Text(
                        'Send Message',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.forestGreen,
                        side: const BorderSide(color: AppTheme.sageBorder, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Link Code Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.sageBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppTheme.forestGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Link Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary, letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'SAH-4829-RXMT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: AppTheme.forestGreen, letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Link code copied!', style: GoogleFonts.inter()),
                            backgroundColor: AppTheme.forestGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: AppTheme.forestGreen),
                      child: Text(
                        'Copy',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Share this code with a new caregiver to link accounts.',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamesMenuContent(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cognitive Activities & Games',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gentle brain exercises designed for daily wellness without frustration.',
          style: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        _buildGameCard(
          title: 'Memory Match',
          subtitle: 'Match pairs of familiar objects at your own pace.',
          duration: '5 mins',
          level: 'Level 3',
          emoji: '🧠',
          color: AppTheme.forestTealCard,
          onTap: _startMemoryMatch,
        ),
        const SizedBox(height: 14),
        _buildGameCard(
          title: 'Clock Drawing Assessment',
          subtitle: 'Draw a clock face to assess planning and motor stability.',
          duration: '3 mins',
          level: 'Module 2',
          emoji: '🕒',
          color: AppTheme.warmTerracotta,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const ClockCanvasScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required String duration,
    required String level,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(duration, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
                      const SizedBox(width: 8),
                      Text('·', style: TextStyle(color: AppTheme.textLight)),
                      const SizedBox(width: 8),
                      Text(level, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.forestGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummaryContent(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Activity Journey',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Every small step strengthens calm focus and joyful memory.',
          style: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('This Week\'s Consistency', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('6 of 7 Days 🌟', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.forestGreen)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                  final isDone = day != 'Sun';
                  return Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.forestGreen : AppTheme.sageLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isDone ? Icons.check_rounded : Icons.circle_outlined,
                            size: 16,
                            color: isDone ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(day, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
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
