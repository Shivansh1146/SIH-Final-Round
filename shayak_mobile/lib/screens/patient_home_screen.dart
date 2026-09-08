import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_sidebar.dart';
import '../models/patient_profile.dart';
import '../services/audio_narration_service.dart';
import '../services/reminder_service.dart';
import 'reminders_screen.dart';
import 'memory_match_screen.dart';
import 'clock_canvas_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const PatientHomeScreen({super.key, required this.onNavigate});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _sidebarIndex = 0;
  bool _isPlayingAudio = false;

  // Live Backend Patient State
  String _patientId = 'PT-9042';
  String _patientDisplayName = 'Ramesh';
  String _patientFullName = 'Ramesh Kumar';
  String _currentDifficultyLevel = 'Level 2 (Moderate)';
  bool _isAdaptiveMode = true;
  int _totalSessions = 13;
  double _avgAccuracy = 76.0;
  double _stabilityScore = 84.0;
  List<dynamic> _recentSessions = [];
  bool _isLoadingBackend = false;

  @override
  void initState() {
    super.initState();
    _initActiveProfile();
    PatientProfile.activeProfileNotifier.addListener(_onProfileChanged);
    ReminderService.instance.addListener(_onRemindersUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ReminderService.instance.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    PatientProfile.activeProfileNotifier.removeListener(_onProfileChanged);
    ReminderService.instance.removeListener(_onRemindersUpdated);
    super.dispose();
  }

  void _onRemindersUpdated() {
    if (mounted) setState(() {});
  }

  void _onProfileChanged() {
    _initActiveProfile();
  }

  Future<void> _initActiveProfile() async {
    final active = PatientProfile.loadFromHive();
    if (active != null) {
      setState(() {
        _patientFullName = active.fullName;
        _patientDisplayName = active.fullName.split(' ').first;
        _patientId = active.id.isNotEmpty ? active.id : 'PT-9042';
      });
    }
    await _fetchBackendPatientData();
  }

  Future<void> _fetchBackendPatientData() async {
    if (!mounted) return;
    setState(() => _isLoadingBackend = true);

    try {
      final backendId = _patientId.startsWith('patient-') ? 'PT-9042' : _patientId;
      final res = await http.get(Uri.parse('http://127.0.0.1:8000/api/v1/patient/$backendId/history'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _currentDifficultyLevel = data['current_difficulty_level'] ?? 'Level 2 (Moderate)';
            _isAdaptiveMode = data['is_adaptive_mode'] ?? true;
            _totalSessions = data['total_sessions_completed'] ?? 13;
            _avgAccuracy = (data['average_accuracy'] as num?)?.toDouble() ?? 76.0;
            if (data['latest_evaluation'] != null) {
              _stabilityScore = (data['latest_evaluation']['postural_stability_score'] as num?)?.toDouble() ?? 84.0;
            }
            _recentSessions = data['recent_sessions'] ?? [];
            _isLoadingBackend = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingBackend = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBackend = false);
    }
  }

  Future<void> _playListenAudio() async {
    final text = 'Good morning, $_patientDisplayName. Today\'s gentle activities include Memory Match and the Clock Contour drawing. Find matching pairs and draw at your own calm pace. Current level is $_currentDifficultyLevel. Anita is available anytime you need assistance.';

    setState(() => _isPlayingAudio = true);
    await AudioNarrationService.instance.speak(text, language: AppLanguage.english);
    if (mounted) {
      setState(() => _isPlayingAudio = false);
    }
  }

  void _resetData() {
    _fetchBackendPatientData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo activity & backend data refreshed.', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startClockDrawing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const ClockCanvasScreen()),
    ).then((_) => _fetchBackendPatientData());
  }

  void _startMemoryMatch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MemoryMatchScreen(
          onFinish: () {
            Navigator.pop(ctx);
            _fetchBackendPatientData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

            // Sidebar + Content Row
            Expanded(
              child: Row(
                children: [
                  // Left Navigation Sidebar
                  AppSidebar(
                    isCaregiver: false,
                    selectedIndex: _sidebarIndex,
                    onSelectIndex: (idx) {
                      setState(() => _sidebarIndex = idx);
                    },
                    onResetData: _resetData,
                  ),

                  // Main Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: _buildSelectedView(context),
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
    );
  }

  Widget _buildSelectedView(BuildContext context) {
    switch (_sidebarIndex) {
      case 1:
        return _buildGamesHubView(context);
      case 2:
        return _buildRemindersView(context);
      case 3:
        return _buildProgressView(context);
      case 0:
      default:
        return _buildPatientHomeContent(context);
    }
  }

  Widget _buildPatientHomeContent(BuildContext context) {
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
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _patientDisplayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34.0,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('🌿', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A calm start makes room for a good memory.',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
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
                    size: 16,
                    color: AppTheme.forestGreen,
                  ),
                  label: Text(
                    'Listen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.tune_rounded, size: 17, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Hero Today's Activity Banner
        _buildHeroActivityBanner(context),

        const SizedBox(height: 24),

        // Bottom Grid: Reminders & Need Help
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 640;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRemindersCard(context)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildNeedHelpCard(context)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildRemindersCard(context),
                  const SizedBox(height: 18),
                  _buildNeedHelpCard(context),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeroActivityBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: AppTheme.forestTealCard,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background concentric decorative rings
          Positioned(
            right: -20,
            top: -30,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 28),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            "TODAY'S ACTIVITY",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Memory Match',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Find the matching pairs. Take your time — one card at a time.',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          'About 5 minutes',
                          style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        const Text('·', style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 10),
                        Text(
                          '$_currentDifficultyLevel${_isAdaptiveMode ? " (AI-Adaptive)" : ""}',
                          style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Start Activity Button
                    ElevatedButton(
                      onPressed: _startMemoryMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warmPeach,
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start activity',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textPrimary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right 3D Brain Visual
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF94B8), Color(0xFFFF4081)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4081).withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🧠', style: TextStyle(fontSize: 38)),
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
    final allReminders = ReminderService.instance.reminders;
    final pending = allReminders.where((r) => !r.isCompleted).toList();
    final totalCount = allReminders.length;

    return Container(
      padding: const EdgeInsets.all(22.0),
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
                  Row(
                    children: [
                      Text(
                        'TODAY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: pending.isEmpty ? AppTheme.sageLight : AppTheme.pastelYellow,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            pending.isEmpty ? 'All Done 🎉' : '${pending.length} pending',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: pending.isEmpty ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reminders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _sidebarIndex = 2),
                    child: Text(
                      'View all ($totalCount)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (allReminders.isEmpty)
            InkWell(
              onTap: () => setState(() => _sidebarIndex = 2),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No reminders set. Tap to add your daily routine.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.forestGreen),
                  ],
                ),
              ),
            )
          else ...[
            ...allReminders.take(3).map((rem) {
              final isDone = rem.isCompleted;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    ReminderService.instance.toggleComplete(rem.id);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDone ? AppTheme.background.withOpacity(0.6) : AppTheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDone ? AppTheme.surfaceBorder : AppTheme.sageBorder.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDone ? Colors.white : AppTheme.sageLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(rem.emoji, style: const TextStyle(fontSize: 17)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rem.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? AppTheme.textSecondary : AppTheme.textPrimary,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Text(
                                rem.formattedTime,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDone ? AppTheme.textLight : AppTheme.warmTerracotta,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isDone ? AppTheme.forestGreen : AppTheme.textSecondary,
                            size: 22,
                          ),
                          onPressed: () {
                            ReminderService.instance.toggleComplete(rem.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.pastelYellow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.warmTerracotta)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Need a little help?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You can listen to instructions, take a pause, or ask a caregiver for assistance anytime.',
            style: GoogleFonts.inter(
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _showCaregiverCallDialog(context),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 15, color: AppTheme.forestGreen),
            label: Text(
              'Call Caregiver Anita',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: AppTheme.forestGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCaregiverCallDialog(BuildContext context) {
    AudioNarrationService.instance.speak(
      'Calling Caregiver Anita Kumar. Please hold on a moment.',
      language: AppLanguage.english,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            contentPadding: const EdgeInsets.all(28),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing Caller Avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.sageLight.withOpacity(0.6),
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.forestGreen,
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Anita Kumar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Primary Caregiver · +91 98450 12345',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Call Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.statusGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calling · Connecting to audio...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // End Call Button
                      ElevatedButton.icon(
                        onPressed: () {
                          AudioNarrationService.instance.stop();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 18),
                        label: const Text('End Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.alertCoral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // View Caregiver Portal Button
                      OutlinedButton.icon(
                        onPressed: () {
                          AudioNarrationService.instance.stop();
                          Navigator.pop(ctx);
                          widget.onNavigate(AppViewMode.caregiver);
                        },
                        icon: const Icon(Icons.dashboard_rounded, size: 16, color: AppTheme.forestGreen),
                        label: const Text('Caregiver View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.forestGreen,
                          side: const BorderSide(color: AppTheme.forestGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGamesHubView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GENTLE ACTIVITIES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Games & Exercises',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoyable cognitive exercises designed to strengthen memory and motor calm.',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen),
              onPressed: _playListenAudio,
              tooltip: 'Listen to instructions',
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Activity Card 1: Memory Match
        _buildActivityItemCard(
          emoji: '🧠',
          tag: 'WORKING MEMORY',
          title: 'Memory Match Activity',
          description: 'Turn over gentle pairs of everyday items at your own comfortable pace.',
          duration: '5 minutes',
          difficulty: 'Adaptive (Level 2)',
          buttonColor: AppTheme.forestGreen,
          buttonText: 'Play Memory Match',
          onPlay: _startMemoryMatch,
        ),

        const SizedBox(height: 18),

        // Activity Card 2: Clock Drawing Assessment
        _buildActivityItemCard(
          emoji: '⏰',
          tag: 'KINEMATIC & EXECUTIVE PLANNING',
          title: 'Clock Contour Assessment',
          description: 'Draw a clock circle, write numbers 1 to 12, and set the hands to 10 past 11 with stylus / touch.',
          duration: '3-5 minutes',
          difficulty: 'Diagnostic Contour',
          buttonColor: AppTheme.warmTerracotta,
          buttonText: 'Start Clock Drawing',
          onPlay: _startClockDrawing,
        ),

        const SizedBox(height: 18),

        // Activity Card 3: Cultural Pattern Sequence
        _buildActivityItemCard(
          emoji: '🌸',
          tag: 'VISUAL-SPATIAL RHYTHM',
          title: 'Cultural Pattern Sequence',
          description: 'Recall rhythmic patterns of rangoli shapes and traditional Indian motifs.',
          duration: '4 minutes',
          difficulty: 'Gentle Flow',
          buttonColor: AppTheme.forestGreen,
          buttonText: 'Explore Patterns',
          onPlay: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Starting Cultural Pattern Sequence session.', style: GoogleFonts.inter()),
                backgroundColor: AppTheme.forestGreen,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItemCard({
    required String emoji,
    required String tag,
    required String title,
    required String description,
    required String duration,
    required String difficulty,
    required Color buttonColor,
    required String buttonText,
    required VoidCallback onPlay,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.sageLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(duration, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    const Icon(Icons.tune_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(difficulty, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onPlay,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(buttonText, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersView(BuildContext context) {
    return const RemindersScreen(isEmbedded: true);
  }

  Widget _buildProgressView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR JOURNEY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.0,
            fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Progress & Wellness',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32.0,
            fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Consistent gentle practice nurtures brain reserve and physical confidence.',
          style: GoogleFonts.inter(fontSize: 14.5, color: AppTheme.textSecondary),
        ),

        const SizedBox(height: 24),

        // 3 Highlight Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildProgressStatCard('7 DAYS', 'Current Streak', '🔥 Daily consistency', AppTheme.warmPeach),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildProgressStatCard('$_totalSessions SESSIONS', 'Activities Completed', '${_avgAccuracy.toStringAsFixed(0)}% Avg Score', AppTheme.sageLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildProgressStatCard('${_stabilityScore.toStringAsFixed(0)}/100', 'Kinematic Stability', '⚖️ Motor balance score', AppTheme.pastelBlue),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Recent Milestones Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Clinical Milestones',
                    style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'AI Engine Live',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.forestGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentSessions.isNotEmpty) ...[
                for (final s in _recentSessions.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildMilestoneRow(
                      '${s['session_type'] ?? "Activity"} (${s['difficulty_level'] ?? "Standard"})',
                      'Score ${s['score']?.toStringAsFixed(1) ?? "80.0"}% · ${s['timestamp'] != null ? s['timestamp'].toString().substring(0, 10) : "Today"}',
                      (s['session_type'] == 'Clock Contour Drawing') ? Icons.draw_rounded : Icons.psychology_rounded,
                    ),
                  ),
              ] else ...[
                _buildMilestoneRow('Clock Contour Drawing Completed', 'Score 8.5/10 · Today, 09:15 AM', Icons.draw_rounded),
                const SizedBox(height: 12),
                _buildMilestoneRow('Memory Match Pairs Solved', 'Turn accuracy 82% · Yesterday, 08:45 AM', Icons.psychology_rounded),
                const SizedBox(height: 12),
                _buildMilestoneRow('ESP32 Tremor Compensation Active', '4-12 Hz jitter stabilized · 6 Sep, 02:30 PM', Icons.sensors_rounded),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStatCard(String val, String title, String subtitle, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppTheme.sageLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.forestGreen, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 14.0, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

