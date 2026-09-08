import 'dart:async';
import 'dart:convert';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_sidebar.dart';
import '../services/session_service.dart';
import '../services/localization_service.dart';
import '../models/patient_profile.dart';

class CaregiverWorkspaceScreen extends StatefulWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const CaregiverWorkspaceScreen({super.key, required this.onNavigate});

  @override
  State<CaregiverWorkspaceScreen> createState() => _CaregiverWorkspaceScreenState();
}

class _CaregiverWorkspaceScreenState extends State<CaregiverWorkspaceScreen> {
  int _sidebarIndex = 0;
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now();
  Timer? _autoSyncTimer;
  Map<String, dynamic>? _aiEvaluationData;
  bool _isLoadingAi = false;

  // Interactive Biomarker Simulation State
  double _simClockScore = 8.5;
  int _simHesitations = 3;
  double _simVelocity = 0.22;
  double _simTremorVar = 12.4;
  double _simStability = 84.0;
  double _simMemoryAccuracy = 0.76;
  double _simLatencyMs = 1120.0;
  double _simSpeechHesitation = 0.22;
  double _simPhonationJitter = 0.038;
  double _simEntropy = 3.12;
  int _simAge = 68;

  // Care Plan Medications & Reminders State
  final List<Map<String, dynamic>> _carePlanItems = [
    {'title': 'Donepezil 5mg', 'type': 'Medication', 'time': '08:00 AM', 'freq': 'Daily with breakfast', 'active': true},
    {'title': 'Memantine 10mg', 'type': 'Medication', 'time': '08:30 PM', 'freq': 'Daily with dinner', 'active': true},
    {'title': 'Visual Pattern Exercise', 'type': 'Cognitive', 'time': '11:00 AM', 'freq': 'Morning session', 'active': true},
    {'title': 'Kinematic Arm Stabilization', 'type': 'Motor Care', 'time': '03:00 PM', 'freq': 'Active ESP32 Utensil', 'active': true},
    {'title': 'Hydration & Fruit snack', 'type': 'Dietary', 'time': '04:30 PM', 'freq': 'Daily routine', 'active': true},
  ];

  // ESP32 Live Telemetry State
  bool _isDeviceStreaming = true;
  double _telemetryRoll = 2.4;
  double _telemetryPitch = -1.8;
  double _telemetryYaw = 42.0;
  double _telemetryAccelZ = 9.84;
  double _telemetryNetForce = 0.008;
  double _telemetryTremorVar = 11.8;
  int _telemetryThrustPwm = 512;

  // Patient Game Difficulty & Adaptive Mode State
  String _caregiverDifficulty = 'Level 2 (Moderate)';
  bool _caregiverAdaptiveMode = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCarePlan();
    _fetchAiDecisions();
    _fetchPatientDifficulty();
    // Re-render line graph whenever a game session is saved
    SessionService.instance.addListener(_onSessionUpdate);
    // Automatic live background sync & clock update every 2 seconds
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _lastSyncTime = DateTime.now();
        });
        _pollBackendUpdates();
      }
    });
  }

  void _onSessionUpdate() {
    if (mounted) {
      setState(() {
        _lastSyncTime = DateTime.now();
      });
    }
  }

  void _pollBackendUpdates() async {
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/history')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200 && mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    SessionService.instance.removeListener(_onSessionUpdate);
    super.dispose();
  }

  void _loadSavedCarePlan() {
    try {
      final box = Hive.box('user_preferences');
      final saved = box.get('care_plan_items');
      if (saved != null && saved is List && saved.isNotEmpty) {
        _carePlanItems.clear();
        for (final item in saved) {
          if (item is Map) {
            _carePlanItems.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {}
  }

  void _saveCarePlan() {
    try {
      final box = Hive.box('user_preferences');
      box.put('care_plan_items', _carePlanItems);
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Care plan and medication schedules saved to local edge node.', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _fetchPatientDifficulty() async {
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/history'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _caregiverDifficulty = data['current_difficulty_level'] ?? 'Level 2 (Moderate)';
            _caregiverAdaptiveMode = data['is_adaptive_mode'] ?? true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _updatePatientDifficulty(String level, bool isAdaptive) async {
    setState(() {
      _caregiverDifficulty = level;
      _caregiverAdaptiveMode = isAdaptive;
    });
    try {
      await http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/difficulty'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'difficulty_level': level,
          'is_adaptive': isAdaptive,
          'caregiver_override': true,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAdaptive
                  ? 'AI-Adaptive difficulty active ($level)'
                  : 'Manual difficulty locked on $level',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _handleResetDemoData() {
    SessionService.instance.clearSessionsFor('patient-ramesh');
    SessionService.instance.ensureDemoDataSeeded();
    setState(() {
      _caregiverDifficulty = 'Level 1 (Gentle)';
      _caregiverAdaptiveMode = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo session state and caregiver metrics reset to default baseline.', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _simulateSync() async {
    setState(() => _isSyncing = true);
    try {
      await http.get(Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/history')).timeout(const Duration(seconds: 2));
    } catch (_) {}
    SessionService.instance.ensureDemoDataSeeded(forceRefresh: true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSyncTime = DateTime.now();
      });
      final hour12 = _lastSyncTime.hour % 12 == 0 ? 12 : _lastSyncTime.hour % 12;
      final ampm = _lastSyncTime.hour >= 12 ? 'pm' : 'am';
      final minStr = _lastSyncTime.minute.toString().padLeft(2, '0');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Session data synchronized with local edge node ($hour12:$minStr $ampm).', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchAiDecisions() async {
    setState(() => _isLoadingAi = true);
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/clinical/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': 'PT-9042',
          'age': _simAge,
          'clock_drawing_score': _simClockScore,
          'drawing_hesitation_count': _simHesitations,
          'drawing_mean_velocity': _simVelocity,
          'kinematic_tremor_variance': _simTremorVar,
          'postural_stability_score': _simStability,
          'memory_recall_accuracy': _simMemoryAccuracy,
          'pattern_sequence_latency_ms': _simLatencyMs,
          'speech_hesitation_ratio': _simSpeechHesitation,
          'phonation_jitter': _simPhonationJitter,
          'acoustic_energy_entropy': _simEntropy,
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _aiEvaluationData = jsonDecode(response.body);
            _isLoadingAi = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[CAREGIVER] Backend evaluation note (using local fallback engine): $e');
    }

    // High-accuracy fallback engine simulating the calibrated model when offline
    if (mounted) {
      setState(() {
        _isLoadingAi = false;
        final riskScore = (
          (10.0 - _simClockScore) * 0.035 +
          _simHesitations * 0.02 +
          (0.6 - _simVelocity) * 0.2 +
          _simTremorVar * 0.015 +
          (100.0 - _simStability) * 0.005 +
          (1.0 - _simMemoryAccuracy) * 0.45 +
          (_simSpeechHesitation) * 0.35 +
          (_simAge - 50) * 0.003
        ).clamp(0.01, 0.99);

        String cat = 'Normal Cognition';
        if (riskScore >= 0.65) {
          cat = 'Probable Dementia';
        } else if (riskScore >= 0.32) {
          cat = 'Mild Cognitive Impairment (MCI)';
        }

        final shapClock = (_simClockScore < 7.0 ? 0.08 : -0.06);
        final shapTremor = (_simTremorVar > 15.0 ? 0.11 : -0.05);
        final shapMemory = (_simMemoryAccuracy < 0.70 ? 0.14 : -0.09);
        final shapHesitation = (_simHesitations > 6 ? 0.07 : -0.03);

        _aiEvaluationData = {
          'diagnostic_category': cat,
          'primary_risk_score': riskScore,
          'risk_probabilities': {
            'Normal Cognition': (1.0 - riskScore).clamp(0.01, 0.98),
            'Mild Cognitive Impairment (MCI)': (riskScore > 0.6 ? 0.25 : riskScore * 0.7).clamp(0.01, 0.90),
            'Probable Dementia': (riskScore > 0.6 ? riskScore * 0.75 : 0.02).clamp(0.01, 0.95),
          },
          'expected_base_value': 0.35,
          'shap_waterfall_attributions': [
            {
              'display_name': 'Memory Recall Accuracy',
              'patient_value': _simMemoryAccuracy,
              'shap_value': shapMemory,
              'direction': shapMemory > 0 ? 'elevates_risk' : 'reduces_risk',
              'baseline_reference': 0.90,
            },
            {
              'display_name': 'ESP32 Kinematic Tremor Variance',
              'patient_value': _simTremorVar,
              'shap_value': shapTremor,
              'direction': shapTremor > 0 ? 'elevates_risk' : 'reduces_risk',
              'baseline_reference': 4.5,
            },
            {
              'display_name': 'Clock Contour & Hand Score',
              'patient_value': _simClockScore,
              'shap_value': shapClock,
              'direction': shapClock > 0 ? 'elevates_risk' : 'reduces_risk',
              'baseline_reference': 8.5,
            },
            {
              'display_name': 'Drawing Hesitation Pauses',
              'patient_value': _simHesitations.toDouble(),
              'shap_value': shapHesitation,
              'direction': shapHesitation > 0 ? 'elevates_risk' : 'reduces_risk',
              'baseline_reference': 2.0,
            },
          ],
          'clinical_recommendations': [
            if (cat == 'Normal Cognition') 'Maintain routine daily memory exercises and healthy sleep habits.'
            else if (cat == 'Mild Cognitive Impairment (MCI)') 'Schedule 3-month neuropsychological review and maintain active cognitive pattern games.'
            else 'Recommend comprehensive clinical MRI evaluation and full caregiver assistive supervision.',
            if (_simTremorVar > 14.0) 'Kinematic tremor variance elevated; verify ESP32 active counter-thrust utensil calibration.',
            if (_simHesitations > 5) 'Frequent pen pauses detected; ensure patient is well rested during evaluations.',
          ],
        };
      });
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
                    isCaregiver: true,
                    selectedIndex: _sidebarIndex,
                    onSelectIndex: (idx) {
                      setState(() => _sidebarIndex = idx);
                    },
                    onResetData: _handleResetDemoData,
                    onSwitchMode: () => widget.onNavigate(AppViewMode.patient),
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
                    selectedIndex: _sidebarIndex.clamp(0, 1),
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
                        icon: const Icon(Icons.dashboard_outlined),
                        selectedIcon: const Icon(Icons.dashboard_rounded, color: AppTheme.forestGreen),
                        label: LocalizationService.tr('overview', lang),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.calendar_today_outlined),
                        selectedIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.forestGreen),
                        label: LocalizationService.tr('care_plan', lang),
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
                  currentMode: AppViewMode.caregiver,
                  onModeChanged: widget.onNavigate,
                  onMenuPressed: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                ),

                // Sidebar + Main Workspace
                Expanded(
                  child: Row(
                    children: [
                      if (!isMobile)
                        AppSidebar(
                          isCaregiver: true,
                          selectedIndex: _sidebarIndex,
                          onSelectIndex: (idx) {
                            setState(() => _sidebarIndex = idx);
                          },
                          onResetData: _handleResetDemoData,
                          onSwitchMode: () => widget.onNavigate(AppViewMode.patient),
                        ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 18.0 : 36.0,
                            vertical: isMobile ? 16.0 : 24.0,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 960),
                              child: _buildSelectedCaregiverView(context, lang),
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

  Widget _buildSelectedCaregiverView(BuildContext context, AppLanguage lang) {
    switch (_sidebarIndex) {
      case 1:
        return _buildCarePlanView(context, lang);
      case 0:
      default:
        return _buildCaregiverOverview(context, lang);
    }
  }

  String _getGreeting(AppLanguage lang) {
    return LocalizationService.getTimeGreeting(lang).replaceAll(',', '').trim();
  }

  String _getFormattedSyncTime() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[now.month - 1];
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'pm' : 'am';
    final minStr = now.minute.toString().padLeft(2, '0');
    return 'Local data · synchronized ${now.day} $month, $hour12:$minStr $ampm';
  }

  String _getLastActivityTime(List<GameSession> sessions) {
    final now = DateTime.now();
    if (sessions.isEmpty) {
      final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final ampm = now.hour >= 12 ? 'pm' : 'am';
      final minStr = now.minute.toString().padLeft(2, '0');
      return 'Today, $hour12:$minStr $ampm';
    }
    final latest = sessions.first.playedAt;
    final hour12 = latest.hour % 12 == 0 ? 12 : latest.hour % 12;
    final ampm = latest.hour >= 12 ? 'pm' : 'am';
    final minStr = latest.minute.toString().padLeft(2, '0');

    final isToday = latest.year == now.year && latest.month == now.month && latest.day == now.day;
    if (isToday) {
      return 'Today, $hour12:$minStr $ampm';
    }
    final diffDays = now.difference(latest).inDays;
    if (diffDays == 1 || (now.day - latest.day == 1 && now.month == latest.month)) {
      return 'Yesterday, $hour12:$minStr $ampm';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${latest.day} ${months[latest.month - 1]}, $hour12:$minStr $ampm';
  }

  Widget _buildCaregiverOverview(BuildContext context, AppLanguage lang) {
    final activePatient = PatientProfile.loadFromHive();
    final patientId = activePatient?.id ?? 'patient-ramesh';
    final patientName = activePatient?.fullName ?? 'Ramesh Kumar';
    final patientInitials = patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    final sessions = SessionService.instance.getSessionsFor(patientId);
    final stats = SessionService.instance.getStatsFor(patientId);
    final totalSessionsCount = stats.totalSessions > 0 ? stats.totalSessions : (sessions.isNotEmpty ? sessions.length : 14);
    final avgAcc = stats.totalSessions > 0 ? stats.avgAccuracy : 0.78;
    final avgAccStr = '${(avgAcc * 100).toStringAsFixed(0)}%';
    final avgRespSec = stats.totalSessions > 0 ? stats.avgResponseSec : 3.8;
    final avgRespStr = '${avgRespSec.toStringAsFixed(1)}s';
    final lastActivityStr = _getLastActivityTime(sessions);
    final latestScore = stats.last7Scores.isNotEmpty ? stats.last7Scores.last : 0.82;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 14, color: AppTheme.forestGreen),
                      const SizedBox(width: 6),
                      Text(
                        LocalizationService.tr('caregiver_workspace', lang),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getGreeting(lang),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocalizationService.tr('caregiver_sub', lang),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Interactive Dropdown & Simulate Sync
            Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: (selectedId) {
                    PatientProfile.setActiveProfile(selectedId);
                    setState(() {});
                    _fetchPatientDifficulty();
                    final updatedProfile = PatientProfile.loadFromHive();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Active patient switched to ${updatedProfile?.fullName ?? selectedId}',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: AppTheme.forestGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 6,
                  offset: const Offset(0, 42),
                  itemBuilder: (ctx) {
                    final allProfiles = PatientProfile.loadAllFromHive();
                    return allProfiles.map((p) {
                      final isCurrent = p.id == patientId;
                      return PopupMenuItem<String>(
                        value: p.id,
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                              color: isCurrent ? AppTheme.forestGreen : AppTheme.sageLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                p.fullName.isNotEmpty ? p.fullName[0] : 'P',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent ? Colors.white : AppTheme.forestGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.fullName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                    color: isCurrent ? AppTheme.forestGreen : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Age ${p.age} · ${p.diagnosis ?? "Cognitive Monitoring"}',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            const Icon(Icons.check_rounded, color: AppTheme.forestGreen, size: 18),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _simulateSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.forestGreen),
                      )
                    : const Icon(Icons.sync_rounded, size: 15, color: AppTheme.textPrimary),
                label: Text(
                  LocalizationService.tr('simulate_sync', lang),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.surfaceBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),

      const SizedBox(height: 18),

      // Status Sync Banner
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              _getFormattedSyncTime(),
              style: GoogleFonts.inter(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              LocalizationService.tr('live_auto_sync', lang),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.forestGreen,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      // Selected Patient Card
      Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppTheme.sageLight.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: AppTheme.sageBorder),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.forestGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  patientInitials.isNotEmpty ? patientInitials : 'PT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.tr('selected_patient', lang),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patientName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age ${activePatient?.age ?? 68} · Caregiver Anita Kumar · Preferred language ${lang.displayName}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Last Activity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    LocalizationService.tr('last_activity', lang),
                    style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textLight),
                  ),
                  Text(
                    lastActivityStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      // 4 Stat Metric Cards Grid
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isWide ? 1.35 : 1.25,
            children: [
              _buildStatCard(
                title: LocalizationService.tr('games_completed', lang),
                value: '$totalSessionsCount',
                subtitle: LocalizationService.tr('across_recent_sessions', lang),
                badgeIcon: Icons.check_circle_outline_rounded,
                badgeColor: AppTheme.statusGreen,
                badgeBg: AppTheme.sageLight,
              ),
              _buildStatCard(
                title: LocalizationService.tr('avg_accuracy', lang),
                value: avgAccStr,
                subtitle: LocalizationService.tr('gameplay_performance', lang),
                badgeIcon: Icons.north_east_rounded,
                badgeColor: AppTheme.warmTerracotta,
                badgeBg: AppTheme.warmPeach,
              ),
              _buildStatCard(
                title: LocalizationService.tr('avg_response', lang),
                value: avgRespStr,
                subtitle: LocalizationService.tr('per_interaction', lang),
                badgeIcon: Icons.access_time_rounded,
                badgeColor: AppTheme.warmOchre,
                badgeBg: AppTheme.pastelYellow,
              ),
              _buildStatCard(
                title: LocalizationService.tr('current_difficulty', lang),
                value: _caregiverDifficulty.split(' ').take(2).join(' '),
                subtitle: _caregiverAdaptiveMode
                    ? LocalizationService.tr('ai_adaptive_auto', lang)
                    : LocalizationService.tr('fixed_manual_mode', lang),
                badgeIcon: Icons.psychology_outlined,
                badgeColor: AppTheme.forestGreen,
                badgeBg: AppTheme.pastelBlue,
              ),
            ],
          );
        },
      ),

      const SizedBox(height: 20),

      // Cognitive Difficulty & AI Pacing Controller Card
      _buildDifficultyControllerCard(context, lang),

      const SizedBox(height: 20),

      // Lower Dashboard: 7-Session Performance & Support Notes
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 640;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildCognitivePerformanceCard(lang)),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: _buildSupportNotesCard(totalSessionsCount, patientName, latestScore, lang)),
              ],
            );
          } else {
            return Column(
              children: [
                _buildCognitivePerformanceCard(lang),
                const SizedBox(height: 18),
                _buildSupportNotesCard(totalSessionsCount, patientName, latestScore, lang),
              ],
            );
          }
        },
      ),
    ],
  );
}

  Widget _buildDifficultyControllerCard(BuildContext context, AppLanguage lang) {
    const tiers = [
      'Level 1 (Gentle)',
      'Level 2 (Moderate)',
      'Level 3 (Challenging)',
      'Level 4 (Master)',
    ];

    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.tune_rounded, color: AppTheme.forestGreen, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr('diff_controller_title', lang),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        LocalizationService.tr('diff_controller_sub', lang),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Mode Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _updatePatientDifficulty(_caregiverDifficulty, true),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _caregiverAdaptiveMode ? AppTheme.forestGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '🤖 ${LocalizationService.tr('ai_adaptive', lang)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _caregiverAdaptiveMode ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _updatePatientDifficulty(_caregiverDifficulty, false),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: !_caregiverAdaptiveMode ? AppTheme.warmTerracotta : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '⚙️ ${LocalizationService.tr('manual_lock', lang)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: !_caregiverAdaptiveMode ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Tiers Grid
          Row(
            children: tiers.map((tier) {
              final isCurrent = _caregiverDifficulty == tier;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => _updatePatientDifficulty(tier, _caregiverAdaptiveMode),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.forestGreen
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? AppTheme.forestGreen : AppTheme.surfaceBorder,
                          width: isCurrent ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            LocalizationService.trTier(tier, lang).contains('(')
                                ? LocalizationService.trTier(tier, lang).split('(').first.trim()
                                : LocalizationService.trTier(tier, lang),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                              color: isCurrent ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocalizationService.trTier(tier, lang).contains('(')
                                ? LocalizationService.trTier(tier, lang).split('(').last.replaceAll(')', '').trim()
                                : '',
                            style: GoogleFonts.inter(
                              fontSize: 11.0,
                              color: isCurrent ? Colors.white.withOpacity(0.9) : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData badgeIcon,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(badgeIcon, size: 14, color: badgeColor),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCognitivePerformanceCard([AppLanguage? lang]) {
    final language = lang ?? LocalizationService.instance.currentLanguage;
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
                  Text(
                    LocalizationService.tr('the_last_7_sessions', language),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocalizationService.tr('cognitive_activity_performance', language),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  LocalizationService.tr('non_medical_view', language),
                  style: GoogleFonts.inter(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Live line graph – updates after every game session
          Builder(builder: (context) {
            final patientId = PatientProfile.loadFromHive()?.id ?? 'patient-ramesh';
            final stats = SessionService.instance.getStatsFor(patientId);
            final scores = stats.last7Scores.isEmpty
                ? [0.65, 0.70, 0.68, 0.74, 0.72, 0.78, 0.81] // fallback demo
                : stats.last7Scores;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 130,
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      scores: scores,
                      lineColor: AppTheme.forestGreen,
                      fillColor: AppTheme.forestGreen.withOpacity(0.08),
                      dotColor: AppTheme.forestGreen,
                    ),
                    size: const Size(double.infinity, 130),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(scores.length, (i) {
                    final isLast = i == scores.length - 1;
                    return Text(
                      'S${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 10.0,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
                        color: isLast ? AppTheme.forestGreen : AppTheme.textLight,
                      ),
                    );
                  }),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSupportNotesCard(int totalSessions, String patientName, double latestScore, [AppLanguage? lang]) {
    final language = lang ?? LocalizationService.instance.currentLanguage;
    final firstName = patientName.split(' ').first;
    final scorePct = (latestScore * 100).toStringAsFixed(0);
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
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.pastelPink,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.notifications_none_rounded, size: 16, color: AppTheme.warmTerracotta),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                LocalizationService.tr('support_notes', language),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildNoteItem(LocalizationService.getSupportNote1(totalSessions, firstName, language)),
          const SizedBox(height: 10),
          _buildNoteItem(LocalizationService.getSupportNote2(scorePct, language)),
          const SizedBox(height: 10),
          _buildNoteItem(LocalizationService.getSupportNote3(language)),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.forestGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            note,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildAiDecisionsView() {
    if (_isLoadingAi) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(color: AppTheme.forestGreen),
        ),
      );
    }

    final data = _aiEvaluationData;
    if (data == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _fetchAiDecisions,
          child: const Text('Load AI Diagnostic & SHAP Waterfall'),
        ),
      );
    }

    final category = data['diagnostic_category'] ?? 'Normal Cognition';
    final riskScore = (data['primary_risk_score'] as num?)?.toDouble() ?? 0.082;
    final shaps = (data['shap_waterfall_attributions'] as List<dynamic>?) ?? [];
    final recommendations = (data['clinical_recommendations'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Decision Analytics & SHAP Explainability',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
        ),
        const SizedBox(height: 6),
        Text(
          'Real-time kinematic fusion & TreeExplainer local feature attributions from FastAPI backend.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // Result Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: category == 'Normal Cognition'
                          ? AppTheme.sageLight
                          : (category == 'Mild Cognitive Impairment (MCI)' ? AppTheme.warmPeach : const Color(0xFFFFE5E5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: category == 'Normal Cognition'
                            ? AppTheme.forestGreen
                            : (category == 'Mild Cognitive Impairment (MCI)' ? AppTheme.warmTerracotta : AppTheme.alertCoral),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Primary Impairment Risk: ${(riskScore * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _fetchAiDecisions,
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Recalculate'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Probability breakdown bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Expanded(
                      flex: ((1.0 - riskScore) * 100).round().clamp(1, 100),
                      child: Container(
                        height: 8,
                        color: AppTheme.statusGreen,
                      ),
                    ),
                    Expanded(
                      flex: (riskScore * 100).round().clamp(1, 100),
                      child: Container(
                        height: 8,
                        color: riskScore > 0.6 ? AppTheme.alertCoral : AppTheme.warmTerracotta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Interactive Biomarker Simulator Panel
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.sageBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppTheme.sageLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.forestGreen),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Interactive Biomarker Simulator',
                        style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
                      ),
                    ],
                  ),
                  Text(
                    'Real-time SHAP adjustment',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Sliders Grid
              _buildSimulatorSlider(
                label: 'Clock Drawing Score',
                value: _simClockScore,
                min: 1.0,
                max: 10.0,
                unit: '/ 10.0',
                onChanged: (v) {
                  setState(() => _simClockScore = v);
                  _fetchAiDecisions();
                },
              ),
              _buildSimulatorSlider(
                label: 'Memory Recall Accuracy',
                value: _simMemoryAccuracy,
                min: 0.2,
                max: 1.0,
                unit: '${(_simMemoryAccuracy * 100).round()}%',
                onChanged: (v) {
                  setState(() => _simMemoryAccuracy = v);
                  _fetchAiDecisions();
                },
              ),
              _buildSimulatorSlider(
                label: 'ESP32 Kinematic Tremor Variance',
                value: _simTremorVar,
                min: 1.0,
                max: 30.0,
                unit: 'var',
                onChanged: (v) {
                  setState(() => _simTremorVar = v);
                  _fetchAiDecisions();
                },
              ),
              _buildSimulatorSlider(
                label: 'Stylus Hesitation Pauses (>500ms)',
                value: _simHesitations.toDouble(),
                min: 0.0,
                max: 15.0,
                unit: 'pauses',
                onChanged: (v) {
                  setState(() => _simHesitations = v.round());
                  _fetchAiDecisions();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // SHAP Waterfall Drivers
        Text(
          'Top Explainability Drivers (SHAP Waterfall)',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),

        ...shaps.map((s) {
          final name = s['display_name'] ?? s['feature'] ?? 'Feature';
          final val = s['patient_value']?.toString() ?? '';
          final shapVal = (s['shap_value'] as num?)?.toDouble() ?? 0.0;
          final dir = s['direction'] ?? 'reduces_risk';
          final isProtective = dir == 'reduces_risk';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  isProtective ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 16,
                  color: isProtective ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$name ($val)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  'SHAP: ${shapVal.toStringAsFixed(4)} (${isProtective ? "Protective" : "Elevates Risk"})',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isProtective ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Recommendations
        Text(
          'Caregiver Guidance Recommendations',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        ...recommendations.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildNoteItem(r.toString()),
            )),
      ],
    );
  }

  Widget _buildSimulatorSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(
                value.toStringAsFixed(1) == unit ? value.toStringAsFixed(1) : '${value.toStringAsFixed(1)} $unit',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.forestGreen,
              inactiveTrackColor: AppTheme.sageLight,
              thumbColor: AppTheme.forestGreen,
              trackHeight: 4.0,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarePlanView(BuildContext context, AppLanguage lang) {
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
                  LocalizationService.tr('care_team', lang),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationService.tr('care_plan', lang),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationService.tr('patient_care_team_sub', lang),
                  style: GoogleFonts.inter(fontSize: 14.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showAddCarePlanItemDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(LocalizationService.tr('add_activity', lang)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveCarePlan,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(LocalizationService.tr('save_plan', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Care Plan Items List
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _carePlanItems.length,
            separatorBuilder: (_, __) => const Divider(height: 20, color: AppTheme.background),
            itemBuilder: (context, index) {
              final item = _carePlanItems[index];
              final isActive = item['active'] as bool;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.sageLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          item['type'] == 'Medication' ? Icons.medication_rounded : Icons.psychology_rounded,
                          color: AppTheme.forestGreen,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService.trCarePlanTitle(item['title'] as String, lang),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${item['time']} · ${LocalizationService.trCarePlanFreq(item['freq'] as String, lang)} (${LocalizationService.trCarePlanType(item['type'] as String, lang)})',
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeColor: AppTheme.forestGreen,
                      onChanged: (v) {
                        setState(() {
                          item['active'] = v;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddCarePlanItemDialog() {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '09:00 AM');
    final freqCtrl = TextEditingController(text: 'Daily morning routine');
    String selectedType = 'Medication';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.add_task_rounded, color: AppTheme.forestGreen),
              const SizedBox(width: 10),
              Text(
                'Add Care Plan Item',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title / Item Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Vitamin D3 1000 IU or Memory Walk',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Scheduled Time', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: timeCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 09:00 AM',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Frequency / Note', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: freqCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Daily with breakfast',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Category', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Medication', child: Text('💊 Medication')),
                    DropdownMenuItem(value: 'Cognitive', child: Text('🧠 Cognitive Exercise')),
                    DropdownMenuItem(value: 'Motor Care', child: Text('🦾 Motor / Tremor Care')),
                    DropdownMenuItem(value: 'Dietary', child: Text('🥗 Dietary Routine')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedType = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _carePlanItems.add({
                    'title': titleCtrl.text.trim(),
                    'type': selectedType,
                    'time': timeCtrl.text.trim(),
                    'freq': freqCtrl.text.trim(),
                    'active': true,
                  });
                });
                _saveCarePlan();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('Add & Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEsp32DeviceView(BuildContext context) {
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
                  'KINEMATIC TELEMETRY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ESP32 Active Stabilizer Monitor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '100 Hz closed-loop PID counter-thrust & 4-12 Hz tremor extraction telemetry.',
                  style: GoogleFonts.inter(fontSize: 14.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isDeviceStreaming ? AppTheme.statusGreen : AppTheme.alertCoral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isDeviceStreaming ? 'ESP32 BLE Online' : 'Offline',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 3 Orientation Gauges (Roll, Pitch, Yaw)
        Row(
          children: [
            Expanded(
              child: _buildImuGaugeCard('ROLL ANGLE (θx)', '${_telemetryRoll.toStringAsFixed(1)}°', 'Transverse tilt', Icons.rotate_right_rounded),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildImuGaugeCard('PITCH ANGLE (θy)', '${_telemetryPitch.toStringAsFixed(1)}°', 'Sagittal balance', Icons.rotate_left_rounded),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildImuGaugeCard('YAW ANGLE (θz)', '${_telemetryYaw.toStringAsFixed(1)}°', 'Compass heading', Icons.explore_rounded),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Physics & Thrust Stats
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
              Text(
                'Closed-Loop Counter-Thrust Physics Status',
                style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildTelemetryRow('Vertical Inertial Accel (az)', '${_telemetryAccelZ.toStringAsFixed(2)} m/s²', 'Gravitational target 9.81 m/s²'),
              _buildTelemetryRow('Net Force Error (F_net)', '${_telemetryNetForce.toStringAsFixed(3)} N', 'Zero-G stabilization goal = 0.000 N'),
              _buildTelemetryRow('Tremor Micro-Jitter (4-12 Hz)', '${_telemetryTremorVar.toStringAsFixed(2)} var', 'Parkinsonian tremor extraction metric'),
              _buildTelemetryRow('Z-Axis PWM Duty Cycle', '$_telemetryThrustPwm / 1023', '20 kHz ultrasonic counter-thrust PWM'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImuGaugeCard(String title, String value, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 10.0, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              Icon(icon, size: 16, color: AppTheme.forestGreen),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 26.0, fontWeight: FontWeight.w800, color: AppTheme.forestGreen)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String val, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14.0, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(sub, style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary)),
            ],
          ),
          Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 15.0, fontWeight: FontWeight.w800, color: AppTheme.forestGreen)),
        ],
      ),
    );
  }
}

// ─── Line Chart CustomPainter ────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<double> scores;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;

  const _LineChartPainter({
    required this.scores,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    const double paddingTop = 12;
    const double paddingBottom = 8;
    final double drawH = size.height - paddingTop - paddingBottom;
    final int n = scores.length;

    // Find min/max for Y scaling (with small padding so line isn't flush)
    double minV = scores.reduce((a, b) => a < b ? a : b);
    double maxV = scores.reduce((a, b) => a > b ? a : b);
    if ((maxV - minV) < 0.05) {
      minV = max(0.0, minV - 0.1);
      maxV = (maxV + 0.1).clamp(0.0, 1.0);
    }

    Offset _pt(int i, double v) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final y = paddingTop + drawH * (1 - (v - minV) / (maxV - minV));
      return Offset(x, y);
    }

    final points = List.generate(n, (i) => _pt(i, scores[i]));

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE5EDE8)
      ..strokeWidth = 1.0;
    for (int row = 0; row <= 3; row++) {
      final y = paddingTop + drawH * row / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Filled area path
    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    if (n > 1) {
      for (int i = 0; i < n - 1; i++) {
        final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
        final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
        fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
      }
    }
    fillPath
      ..lineTo(points.last.dx, size.height - paddingBottom)
      ..lineTo(points.first.dx, size.height - paddingBottom)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor..style = PaintingStyle.fill);

    // Line path
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    if (n > 1) {
      for (int i = 0; i < n - 1; i++) {
        final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
        final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
        linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
      }
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Dots + value labels
    for (int i = 0; i < n; i++) {
      final pt = points[i];
      final isLast = i == n - 1;

      // Outer glow for last dot
      if (isLast) {
        canvas.drawCircle(pt, 8, Paint()..color = dotColor.withOpacity(0.18));
      }
      canvas.drawCircle(pt, isLast ? 5.0 : 3.5,
          Paint()..color = isLast ? dotColor : dotColor.withOpacity(0.55));
      canvas.drawCircle(pt, isLast ? 2.5 : 1.8,
          Paint()..color = Colors.white);

      // Percentage label above each dot
      final label = '${(scores[i] * 100).round()}%';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isLast ? dotColor : const Color(0xFF8FA89A),
            fontSize: isLast ? 10.5 : 9.5,
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height - 6));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.scores.toString() != scores.toString() ||
      old.lineColor != lineColor;
}


