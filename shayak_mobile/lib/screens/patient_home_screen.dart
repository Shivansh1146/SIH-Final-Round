import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_sidebar.dart';
import '../models/patient_profile.dart';
import '../services/audio_narration_service.dart';
import '../services/reminder_service.dart';
import '../services/localization_service.dart';
import 'reminders_screen.dart';
import 'memory_match_screen.dart';
import 'clock_canvas_screen.dart';
import 'routine_sequencer_screen.dart';
import '../widgets/patient_progress_dashboard.dart';

class PatientHomeScreen extends StatefulWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const PatientHomeScreen({super.key, required this.onNavigate});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _sidebarIndex = 0;
  bool _isPlayingAudio = false;

  // Live Backend Patient State
  String _patientId = 'PT-9042';
  String _patientDisplayName = 'Ramesh';
  String _currentDifficultyLevel = 'Level 2 (Moderate)';
  bool _isAdaptiveMode = true;
  int _totalSessions = 13;
  double _avgAccuracy = 76.0;
  double _stabilityScore = 84.0;
  List<dynamic> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    LocalizationService.instance.init();
    _initActiveProfile();
    PatientProfile.activeProfileNotifier.addListener(_onProfileChanged);
    ReminderService.instance.addListener(_onRemindersUpdated);
    LocalizationService.languageNotifier.addListener(_onLanguageChanged);
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
    LocalizationService.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
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
        _patientDisplayName = active.fullName.split(' ').first;
        _patientId = active.id.isNotEmpty ? active.id : 'PT-9042';
      });
    }
    await _fetchBackendPatientData();
  }

  Future<void> _fetchBackendPatientData() async {
    if (!mounted) return;

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
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _playListenAudio() async {
    if (_isPlayingAudio) {
      await AudioNarrationService.instance.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }

    setState(() => _isPlayingAudio = true);
    final currentLang = LocalizationService.instance.currentLanguage;
    final timeGreeting = LocalizationService.getTimeGreeting(currentLang).replaceAll(',', '').trim();
    String textToRead;

    switch (currentLang) {
      case AppLanguage.hindi:
        textToRead = "$timeGreeting $_patientDisplayName। आज की मुख्य गतिविधि स्मृति मिलान (Memory Match) है। "
            "आपने $_totalSessions अभ्यास सत्र पूरे किए हैं और आपकी औसत सटीकता ${_avgAccuracy.toStringAsFixed(0)} प्रतिशत है।";
        break;
      case AppLanguage.assamese:
        textToRead = "$timeGreeting $_patientDisplayName। আজিৰ মুখ্য কাৰ্যকলাপ স্মৃতি মিলন (Memory Match)। "
            "আপুনি $_totalSessions টা অনুশীলন সম্পূৰ্ণ কৰিছে আৰু আপোনাৰ গড় সঠিকতা ${_avgAccuracy.toStringAsFixed(0)} শতাংশ।";
        break;
      case AppLanguage.bengali:
        textToRead = "$timeGreeting $_patientDisplayName। আজকের প্রধান কার্যকলাপ স্মৃতি মেলানো (Memory Match)। "
            "আপনি $_totalSessions টি সেশন সম্পন্ন করেছেন এবং গড় নির্ভুলতা ${_avgAccuracy.toStringAsFixed(0)} শতাংশ।";
        break;
      case AppLanguage.manipuri:
        textToRead = "$timeGreeting $_patientDisplayName। ঙসিগী মরুওইবা থবক নিংশিংবা চাংয়েং (Memory Match) নি। "
            "নহাক্না সেসন $_totalSessions লোইশিনখ্রে অমসুং অচুম্বা চাং চাদা ${_avgAccuracy.toStringAsFixed(0)} নি।";
        break;
      case AppLanguage.bodo:
        textToRead = "$timeGreeting $_patientDisplayName। दिनैनि गाहाय हाबाफारिया गोसोखांथि गोरोबनाय (Memory Match)। "
            "नोंथाङा $_totalSessions खेब आनजाद फुंखांबाय आरो गोरोबनाय बिबाङा ${_avgAccuracy.toStringAsFixed(0)} जौखोन्दो।";
        break;
      case AppLanguage.nepali:
        textToRead = "$timeGreeting $_patientDisplayName। आजको मुख्य गतिविधि स्मरण मिलान (Memory Match) हो। "
            "तपाईंले $_totalSessions सत्रहरू पूरा गर्नुभएको छ र औसत शुद्धता ${_avgAccuracy.toStringAsFixed(0)} प्रतिशत छ।";
        break;
      case AppLanguage.mizo:
        textToRead = "$timeGreeting $_patientDisplayName. Vawiin thiltih ber chu Hriatrengna Inmilh (Memory Match) a ni. "
            "Session $_totalSessions i zo tawh a, i ti tha hle mai (${_avgAccuracy.toStringAsFixed(0)}%).";
        break;
      case AppLanguage.english:
      default:
        textToRead = "$timeGreeting $_patientDisplayName. Today's focus is the Memory Match Activity, "
            "designed for gentle cognitive engagement at difficulty level $_currentDifficultyLevel. "
            "You have completed $_totalSessions sessions with an average accuracy of ${_avgAccuracy.toStringAsFixed(0)} percent.";
        break;
    }

    await AudioNarrationService.instance.speak(textToRead, language: currentLang);
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  void _resetData() {
    setState(() {
      _currentDifficultyLevel = 'Level 2 (Moderate)';
      _isAdaptiveMode = true;
      _totalSessions = 13;
      _avgAccuracy = 76.0;
      _stabilityScore = 84.0;
      _recentSessions = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo session state reset to default baseline.', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.forestGreen,
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



  void _startRoutineSequencer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RoutineSequencerScreen(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.background,
          drawer: isMobile
              ? Drawer(
                  backgroundColor: AppTheme.background,
                  child: AppSidebar(
                    isCaregiver: false,
                    selectedIndex: _sidebarIndex,
                    onSelectIndex: (idx) {
                      setState(() => _sidebarIndex = idx);
                    },
                    onResetData: _resetData,
                  ),
                )
              : null,
          bottomNavigationBar: isMobile
              ? Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppTheme.surfaceBorder, width: 1.0),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _sidebarIndex.clamp(0, 3),
                    onDestinationSelected: (idx) {
                      setState(() => _sidebarIndex = idx);
                    },
                    backgroundColor: Colors.white,
                    indicatorColor: AppTheme.sageLight,
                    elevation: 3,
                    height: 64,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home_rounded, color: AppTheme.forestGreen),
                        label: LocalizationService.tr('home', lang),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.psychology_outlined),
                        selectedIcon: const Icon(Icons.psychology_rounded, color: AppTheme.forestGreen),
                        label: LocalizationService.tr('games', lang),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.alarm_outlined),
                        selectedIcon: const Icon(Icons.alarm_rounded, color: AppTheme.forestGreen),
                        label: LocalizationService.tr('reminders', lang),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.bar_chart_rounded),
                        selectedIcon: const Icon(Icons.bar_chart_rounded, color: AppTheme.forestGreen),
                        label: LocalizationService.tr('progress', lang),
                      ),
                    ],
                  ),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar
                AppTopBar(
                  currentMode: AppViewMode.patient,
                  onModeChanged: widget.onNavigate,
                  onMenuPressed: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                ),

                // Sidebar + Content Row
                Expanded(
                  child: Row(
                    children: [
                      // Left Navigation Sidebar (Desktop & Tablet only)
                      if (!isMobile)
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 18.0 : 36.0,
                            vertical: isMobile ? 16.0 : 24.0,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 960),
                              child: _buildSelectedView(context, lang),
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
      },
    );
  }

  Widget _buildSelectedView(BuildContext context, AppLanguage lang) {
    switch (_sidebarIndex) {
      case 1:
        return _buildGamesHubView(context);
      case 2:
        return _buildRemindersView(context);
      case 3:
        return _buildProgressView(context);
      case 0:
      default:
        return _buildPatientHomeContent(context, lang);
    }
  }

  Widget _buildPatientHomeContent(BuildContext context, AppLanguage lang) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 520;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting Header & Action Buttons
        if (isCompact) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocalizationService.getTimeGreeting(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _playListenAudio,
                    icon: Icon(
                      _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      size: 15,
                      color: AppTheme.forestGreen,
                    ),
                    label: Text(
                      LocalizationService.tr('listen'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _patientDisplayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('🌿', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                LocalizationService.tr('calm_quote'),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.getTimeGreeting(),
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
                      LocalizationService.tr('calm_quote'),
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
                      LocalizationService.tr('listen'),
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
        ],

        const SizedBox(height: 24),

        // Hero Today's Activity Banner
        _buildHeroActivityBanner(context, lang),

        const SizedBox(height: 24),

        // Bottom Grid: Reminders & Need Help
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 640;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRemindersCard(context, lang)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildNeedHelpCard(context, lang)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildRemindersCard(context, lang),
                  const SizedBox(height: 18),
                  _buildNeedHelpCard(context, lang),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeroActivityBanner(BuildContext context, AppLanguage lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isCompact ? 20.0 : 28.0),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                LocalizationService.tr('todays_activity', lang),
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
                        const SizedBox(height: 12),
                        Text(
                          LocalizationService.tr('memory_match', lang),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isCompact ? 24.0 : 30.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LocalizationService.tr('memory_match_sub', lang),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  LocalizationService.tr('about_5_mins', lang),
                                  style: GoogleFonts.inter(fontSize: 12.0, color: Colors.white70, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              '$_currentDifficultyLevel${_isAdaptiveMode ? " (AI-Adaptive)" : ""}',
                              style: GoogleFonts.inter(fontSize: 12.0, color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _startMemoryMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warmPeach,
                            foregroundColor: AppTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                LocalizationService.tr('start_activity'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
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
                  if (!isCompact) ...[
                    const SizedBox(width: 20),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Container(
                          width: 72,
                          height: 72,
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
                            child: Text('🧠', style: TextStyle(fontSize: 34)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemindersCard(BuildContext context, AppLanguage lang) {
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
                        LocalizationService.tr('today', lang),
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
                            pending.isEmpty
                                ? LocalizationService.tr('all_done', lang)
                                : '${pending.length} ${LocalizationService.tr('pending', lang)}',
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
                    LocalizationService.tr('reminders', lang),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 4,
                children: [
                  // Test Alarm Quick Preview
                  Tooltip(
                    message: 'Preview Voice Alarm Alert',
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ReminderService.instance.triggerTestAlert(context);
                      },
                      icon: const Icon(Icons.notifications_active_rounded, size: 14, color: AppTheme.warmTerracotta),
                      label: Text(
                        'Test Alarm 🔔',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warmTerracotta,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.pastelYellow),
                        backgroundColor: AppTheme.pastelYellow.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _sidebarIndex = 2),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View all ($totalCount)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
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
            ...allReminders.take(4).map((rem) {
              final isDone = rem.isCompleted;
              final displayTitle = LocalizationService.trReminderTitle(rem.title);
              final displayNotes = LocalizationService.trReminderNotes(rem.notes);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        child: InkWell(
                          onTap: () {
                            final willComplete = !rem.isCompleted;
                            ReminderService.instance.toggleComplete(rem.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  willComplete ? '✓ Completed "$displayTitle" 🌸' : 'Marked "$displayTitle" as pending',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: willComplete ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? AppTheme.textSecondary : AppTheme.textPrimary,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    rem.formattedTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDone ? AppTheme.textLight : AppTheme.warmTerracotta,
                                    ),
                                  ),
                                  if (displayNotes.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    const Text('·', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        displayNotes,
                                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // TTS Speak icon button
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(),
                        tooltip: 'Listen to reminder',
                        icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppTheme.forestGreen),
                        onPressed: () {
                          ReminderService.instance.speakReminder(rem);
                        },
                      ),
                      const SizedBox(width: 6),
                      // Checkbox toggle button
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: isDone ? 'Mark Incomplete' : 'Mark Complete',
                        icon: Icon(
                          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isDone ? AppTheme.forestGreen : AppTheme.textSecondary,
                          size: 24,
                        ),
                        onPressed: () {
                          final willComplete = !rem.isCompleted;
                          ReminderService.instance.toggleComplete(rem.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                willComplete ? '✓ Completed "${rem.title}" 🌸' : 'Marked "${rem.title}" as pending',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: willComplete ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard(BuildContext context, AppLanguage lang) {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppTheme.pastelYellow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.warmTerracotta)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LocalizationService.tr('need_help', lang),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            LocalizationService.tr('need_help_sub', lang),
            style: GoogleFonts.inter(
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCaregiverCallDialog(context, lang),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.white),
            label: Text(
              '${LocalizationService.tr('call_caregiver', lang)} Anita',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeRealPhoneCall(String rawPhoneNumber) async {
    final cleanNumber = rawPhoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching real phone call: $e');
    }
  }

  Future<void> _makeWhatsAppCall(String rawPhoneNumber) async {
    final digits = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits?text=Hello%20Anita,%20I%20am%20calling%20for%20assistance.');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  void _showCaregiverCallDialog(BuildContext context, AppLanguage lang) {
    const caregiverPhone = '+91 98450 12345';
    const caregiverName = 'Anita Kumar';

    // 1. Immediately launch native cellular telephone dialer
    _makeRealPhoneCall(caregiverPhone);

    // 2. Play live spoken caregiver voice in the patient's selected language
    AudioNarrationService.instance.speak(
      LocalizationService.getCaregiverVoiceGreeting(lang, _patientDisplayName),
      language: lang,
    );

    int callDurationSec = 0;
    bool isMuted = false;
    bool isSpeakerOn = true;
    Timer? callTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          callTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (dialogCtx.mounted) {
              setDialogState(() {
                callDurationSec++;
              });
            }
          });

          final mins = (callDurationSec ~/ 60).toString().padLeft(2, '0');
          final secs = (callDurationSec % 60).toString().padLeft(2, '0');

          return Dialog(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 24,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Call Header Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CONNECTED · $mins:$secs',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () {
                          callTimer?.cancel();
                          AudioNarrationService.instance.stop();
                          Navigator.pop(dialogCtx);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Animated Calling Wave Avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.85, end: 1.25),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981).withOpacity(0.15),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x6610B981),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Text(
                    caregiverName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Primary Caregiver · $caregiverPhone',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Live Caregiver Voice Prompt Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_up_rounded, color: Color(0xFF38BDF8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            LocalizationService.getCaregiverVoiceGreeting(lang, _patientDisplayName),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Telephony Direct Actions (Real Phone & WhatsApp)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makeRealPhoneCall(caregiverPhone),
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          label: const Text('Cellular Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makeWhatsAppCall(caregiverPhone),
                          icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // In-Call Controls (Mute, Speaker, End)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Button
                      IconButton(
                        onPressed: () {
                          setDialogState(() => isMuted = !isMuted);
                        },
                        icon: Icon(
                          isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          color: isMuted ? const Color(0xFFEF4444) : Colors.white70,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),

                      // End Call Button (Big Red)
                      InkWell(
                        onTap: () {
                          callTimer?.cancel();
                          AudioNarrationService.instance.stop();
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ Caregiver call ended.', style: GoogleFonts.inter()),
                              backgroundColor: AppTheme.forestGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66EF4444),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),

                      // Speakerphone Button
                      IconButton(
                        onPressed: () {
                          setDialogState(() => isSpeakerOn = !isSpeakerOn);
                        },
                        icon: Icon(
                          isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: isSpeakerOn ? const Color(0xFF38BDF8) : Colors.white70,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          padding: const EdgeInsets.all(12),
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
                  LocalizationService.tr('gentle_activities'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationService.tr('games_exercises'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationService.tr('games_sub'),
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

        // Premier Dementia Activity: Daily Routine & ADL Sequencer
        _buildActivityItemCard(
          emoji: '☕',
          tag: 'CLINICAL ADL PROCEDURAL REHABILITATION',
          title: LocalizationService.tr('routine_sequencer'),
          description: LocalizationService.tr('routine_sub'),
          duration: '3–5 minutes',
          difficulty: 'AI-Adaptive (3–5 Steps)',
          buttonColor: const Color(0xFFE65100),
          buttonText: LocalizationService.tr('play_routine'),
          onPlay: _startRoutineSequencer,
        ),

        const SizedBox(height: 18),

        // Activity Card 1: Memory Match Activity
        _buildActivityItemCard(
          emoji: '🧠',
          tag: 'WORKING MEMORY',
          title: LocalizationService.tr('memory_match'),
          description: LocalizationService.tr('memory_match_sub'),
          duration: '5 minutes',
          difficulty: '$_currentDifficultyLevel${_isAdaptiveMode ? " (AI Adaptive)" : ""}',
          buttonColor: AppTheme.forestGreen,
          buttonText: LocalizationService.tr('play_memory_match'),
          onPlay: _startMemoryMatch,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isCompact ? 18.0 : 24.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isCompact ? 52 : 64,
                    height: isCompact ? 52 : 64,
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(emoji, style: TextStyle(fontSize: isCompact ? 26 : 32)),
                    ),
                  ),
                  SizedBox(width: isCompact ? 14 : 20),
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
                            fontSize: isCompact ? 16.5 : 18.0,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: isCompact ? 12.5 : 13.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(duration, style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(difficulty, style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
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
                ],
              ),
              if (isCompact) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(buttonText, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 15),
                      ],
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

  Widget _buildRemindersView(BuildContext context) {
    return const RemindersScreen(isEmbedded: true);
  }

  Widget _buildProgressView(BuildContext context) {
    return PatientProgressDashboard(
      patientId: _patientId,
      patientDisplayName: _patientDisplayName,
      totalSessions: _totalSessions,
      avgAccuracy: _avgAccuracy,
      stabilityScore: _stabilityScore,
      recentSessions: _recentSessions,
      onStartMemoryMatch: _startMemoryMatch,
      onStartRoutineSequencer: _startRoutineSequencer,
    );
  }
}

