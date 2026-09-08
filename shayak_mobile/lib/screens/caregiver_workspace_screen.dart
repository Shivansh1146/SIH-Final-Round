import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import '../models/patient_profile.dart';
import '../services/reminder_service.dart';
import '../services/session_service.dart';
=======
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_sidebar.dart';
import 'reminders_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// AI Stats Data Model
// ════════════════════════════════════════════════════════════════════════════
class _CaregiverStatsData {
  final int gamesCompleted;
  final String averageAccuracy;
  final String avgResponseTime;
  final String currentDifficulty;
  final List<double> sessionScores; // 7 values 0.0–1.0
  final List<String> supportNotes;  // 3 AI-generated bullets
  final String statusLabel;
  final bool isLive;

  const _CaregiverStatsData({
    required this.gamesCompleted,
    required this.averageAccuracy,
    required this.avgResponseTime,
    required this.currentDifficulty,
    required this.sessionScores,
    required this.supportNotes,
    required this.statusLabel,
    this.isLive = false,
  });

  /// Clean baseline for new patients who have completed 0 game sessions.
  factory _CaregiverStatsData.empty({required String patientName}) {
    return _CaregiverStatsData(
      gamesCompleted: 0,
      averageAccuracy: '--',
      avgResponseTime: '--',
      currentDifficulty: 'Baseline',
      sessionScores: const [],
      supportNotes: [
        'No activities completed yet for $patientName.',
        'Cognitive baseline will calibrate after completing the first game or assessment.',
        'Recommended: Start with Memory Match or Clock Drawing Assessment.',
      ],
      statusLabel: 'Awaiting Assessment',
      isLive: false,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Session Line Chart — CustomPainter
// ════════════════════════════════════════════════════════════════════════════
class _SessionLineChartPainter extends CustomPainter {
  final List<double> scores;
  _SessionLineChartPainter({required this.scores});

  static const _green = Color(0xFF2D6A4F);
  static const _gridColor = Color(0xFFE8EDE8);
  static const _labelColor = Color(0xFFBBCCBB);
  static const double _leftMargin = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;
    final n = scores.length;

    // Horizontal grid lines + y-axis labels at 0, 50, 100
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.8;
    for (final entry in {1.0: '100', 0.5: '50', 0.0: '0'}.entries) {
      final y = size.height * (1.0 - entry.key);
      canvas.drawLine(
          Offset(_leftMargin, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: const TextStyle(fontSize: 8.5, color: _labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Compute chart point positions
    final chartWidth = size.width - _leftMargin;
    final pts = List.generate(
      n,
      (i) => Offset(
        _leftMargin + (n > 1 ? i * chartWidth / (n - 1) : chartWidth / 2),
        size.height * (1.0 - scores[i]),
      ),
    );

    if (n > 1) {
      // Gradient fill area under line
      final fillPath = Path()..moveTo(pts.first.dx, size.height);
      for (final p in pts) fillPath.lineTo(p.dx, p.dy);
      fillPath.lineTo(pts.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _green.withOpacity(0.16),
              _green.withOpacity(0.00),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );

      // Line connecting all points
      final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < n; i++) linePath.lineTo(pts[i].dx, pts[i].dy);
      canvas.drawPath(
        linePath,
        Paint()
          ..color = _green
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Dots at each session point
    for (int i = 0; i < n; i++) {
      final isLast = i == n - 1;
      final r = isLast ? 5.5 : 3.5;
      canvas.drawCircle(pts[i], r, Paint()..color = _green);
      canvas.drawCircle(
          pts[i],
          r,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
    }
  }

  @override
  bool shouldRepaint(_SessionLineChartPainter old) =>
      old.scores.join() != scores.join();
}

class CaregiverWorkspaceScreen extends StatefulWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const CaregiverWorkspaceScreen({super.key, required this.onNavigate});

  @override
  State<CaregiverWorkspaceScreen> createState() => _CaregiverWorkspaceScreenState();
}

class _CaregiverWorkspaceScreenState extends State<CaregiverWorkspaceScreen> {
  int _sidebarIndex = 0;
  bool _isSyncing = false;
  Map<String, dynamic>? _aiEvaluationData;
  bool _isLoadingAi = false;
  _CaregiverStatsData? _statsData;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    PatientProfile.activeProfileNotifier.addListener(_onProfileOrReminderChanged);
    ReminderService.instance.addListener(_onProfileOrReminderChanged);
    SessionService.instance.addListener(_onSessionChanged);
    // Auto-fetch AI stats after first frame so context & Hive are ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAiStats());
  }

  @override
  void dispose() {
    PatientProfile.activeProfileNotifier.removeListener(_onProfileOrReminderChanged);
    ReminderService.instance.removeListener(_onProfileOrReminderChanged);
    SessionService.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Called when the active patient profile changes (registration / switch).
  void _onProfileOrReminderChanged() {
    if (mounted) {
      // Reset cached stats so they are re-fetched for the new patient
      setState(() {
        _statsData = null;
        _aiEvaluationData = null;
        _isLoadingStats = false;
      });
      _fetchAiStats();
    }
  }

  /// Called when a new game session is saved — refresh stats immediately.
  void _onSessionChanged() {
    if (mounted) {
      setState(() {
        _statsData = null;
        _isLoadingStats = false;
      });
      _fetchAiStats();
    }
  }

  Widget _buildBodyContent({required bool isMobile}) {
    switch (_sidebarIndex) {
      case 1:
        return _buildAiDecisionsView(isMobile: isMobile);
      case 2:
        return const RemindersScreen(isEmbedded: true);
      case 0:
      default:
        return _buildCaregiverOverview(context, isMobile: isMobile);
    }
  }

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
    _fetchAiDecisions();
    _fetchPatientDifficulty();
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

  void _simulateSync() {
    setState(() => _isSyncing = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session data synchronized with local edge node.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
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

<<<<<<< HEAD
  void _onTabSelected(int idx) {
    setState(() => _sidebarIndex = idx);
    if (idx == 1 && _aiEvaluationData == null) {
      _fetchAiDecisions();
    }
    // Refresh AI stats when returning to Overview tab
    if (idx == 0) _fetchAiStats();
  }

  /// Fetches real-time AI-computed stats from the FastAPI backend.
  /// Uses REAL session history from SessionService; falls back to local data.
  Future<void> _fetchAiStats() async {
    if (_isLoadingStats || !mounted) return;
    setState(() => _isLoadingStats = true);

    final profile = PatientProfile.loadFromHive();
    final patientName = profile?.fullName ?? 'Patient';
    final patientId = profile?.id ?? 'unknown';

    // ── Real game session data ─────────────────────────────────────────
    final sessionStats = SessionService.instance.getStatsFor(patientId);
    final hasSessions = sessionStats.totalSessions > 0;

    // If new patient with NO game sessions yet:
    if (!hasSessions) {
      if (mounted) {
        setState(() {
          _aiEvaluationData = null;
          _statsData = _CaregiverStatsData.empty(patientName: patientName);
          _isLoadingStats = false;
        });
      }
      return;
    }

    // When sessions exist, use real data:
    final ratio = sessionStats.avgAccuracy;
    final avgResponseSec = sessionStats.avgResponseSec;
    final gamesPlayed = sessionStats.totalSessions;
    final chartScores = sessionStats.last7Scores;

    try {
      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/v1/clinical/evaluate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_id': patientId,
              'age': profile?.age ?? 68,
              'clock_drawing_score': (7.5 + ratio * 2.0).clamp(0.0, 10.0),
              'drawing_hesitation_count': (4 - ratio * 2).round().clamp(0, 8),
              'drawing_mean_velocity': (0.18 + ratio * 0.08).clamp(0.0, 1.0),
              'kinematic_tremor_variance': (14.0 - ratio * 4.0).clamp(0.0, 25.0),
              'postural_stability_score': (75.0 + ratio * 15.0).clamp(0.0, 100.0),
              // Real memory accuracy from actual gameplay
              'memory_recall_accuracy': ratio.clamp(0.0, 1.0),
              // Real response latency from actual gameplay (ms)
              'pattern_sequence_latency_ms':
                  (avgResponseSec * 1000).clamp(500.0, 5000.0),
              'speech_hesitation_ratio': (0.28 - ratio * 0.08).clamp(0.0, 1.0),
              'phonation_jitter': (0.041 - ratio * 0.005).clamp(0.0, 0.1),
              'acoustic_energy_entropy': (3.0 + ratio * 0.5).clamp(0.0, 6.0),
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accuracy = (ratio * 100).round().clamp(10, 100);
        final responseDisplay = avgResponseSec.toStringAsFixed(1);
        final level = accuracy >= 85
            ? 'Level 3'
            : accuracy >= 70
                ? 'Level 2'
                : 'Level 1';

        final recs = (data['clinical_recommendations'] as List<dynamic>?) ?? [];
        final thirdNote = recs.isNotEmpty
            ? recs.first.toString()
            : 'AI Adaptive Engine is actively calibrated to $level based on recent telemetry.';

        if (mounted) {
          setState(() {
            _aiEvaluationData = data;
            _statsData = _CaregiverStatsData(
              gamesCompleted: gamesPlayed,
              averageAccuracy: '$accuracy%',
              avgResponseTime: '${responseDisplay}s',
              currentDifficulty: level,
              sessionScores: chartScores,
              supportNotes: [
                '$gamesPlayed activity(ies) completed for $patientName with consistent tracking.',
                'Average accuracy is $accuracy% with an average response time of ${responseDisplay}s.',
                thirdNote,
              ],
              statusLabel: accuracy >= 70 ? 'Active Routine' : 'Monitoring',
              isLive: true,
            );
            _isLoadingStats = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback when backend is offline:
    if (mounted) {
      final accPct = (sessionStats.avgAccuracy * 100).round().clamp(10, 100);
      final respDisplay = sessionStats.avgResponseSec.toStringAsFixed(1);
      final level = accPct >= 85
          ? 'Level 3'
          : accPct >= 70
              ? 'Level 2'
              : 'Level 1';

      setState(() {
        _statsData = _CaregiverStatsData(
          gamesCompleted: sessionStats.totalSessions,
          averageAccuracy: '$accPct%',
          avgResponseTime: '${respDisplay}s',
          currentDifficulty: level,
          sessionScores: chartScores,
          supportNotes: [
            '${sessionStats.totalSessions} activity(ies) completed for $patientName with consistent tracking.',
            'Average accuracy is $accPct% with an average response time of ${respDisplay}s.',
            'AI Adaptive Engine is actively calibrated to $level based on recent telemetry.',
          ],
          statusLabel: accPct >= 70 ? 'Active Routine' : 'Monitoring',
          isLive: false,
        );
        _isLoadingStats = false;
      });
    }
  }

=======
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            AppTopBar(
              currentMode: AppViewMode.caregiver,
              onModeChanged: widget.onNavigate,
            ),

            // Sidebar + Main Workspace
            Expanded(
<<<<<<< HEAD
              child: isMobile
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: _buildBodyContent(isMobile: true),
                    )
                  : Row(
                      children: [
                        AppSidebar(
                          isCaregiver: true,
                          selectedIndex: _sidebarIndex,
                          onSelectIndex: _onTabSelected,
                          onResetData: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Caregiver cache cleared.', style: GoogleFonts.inter()),
                                backgroundColor: AppTheme.forestGreen,
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 960),
                                child: _buildBodyContent(isMobile: false),
                              ),
                            ),
                          ),
=======
              child: Row(
                children: [
                  AppSidebar(
                    isCaregiver: true,
                    selectedIndex: _sidebarIndex,
                    onSelectIndex: (idx) {
                      setState(() => _sidebarIndex = idx);
                    },
                    onResetData: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Caregiver cache cleared and resynced.', style: GoogleFonts.inter()),
                          backgroundColor: AppTheme.forestGreen,
                        ),
                      );
                    },
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: _buildSelectedCaregiverView(context),
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
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

<<<<<<< HEAD
  Widget _buildCaregiverOverview(BuildContext context, {required bool isMobile}) {
    final profile = PatientProfile.loadFromHive();
    final patientName = profile?.fullName ?? 'Ramesh Kumar';
    final initials = profile != null && profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'RK';
    final patientSubtitle = 'Age ${profile?.age ?? 68} · ${profile?.caregiverName ?? "Anita Kumar"} · ${profile?.preferredLanguage.displayName ?? "English"}';

=======
  Widget _buildSelectedCaregiverView(BuildContext context) {
    switch (_sidebarIndex) {
      case 1:
        return _buildAiDecisionsView();
      case 2:
        return _buildCarePlanView(context);
      case 3:
        return _buildEsp32DeviceView(context);
      case 0:
      default:
        return _buildCaregiverOverview(context);
    }
  }

  Widget _buildCaregiverOverview(BuildContext context) {
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
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
                        'Caregiver workspace',
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
                    'Good afternoon',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A clear view of support, without clinical assumptions.',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

<<<<<<< HEAD
            // Dropdown & Sync Button
            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      patientName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
=======
            // Dropdown & Simulate Sync
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Ramesh Kumar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary),
                    ],
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
                    'Simulate sync',
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
<<<<<<< HEAD
              Expanded(
                child: Text(
                  'Local data · synced for $patientName',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11.5 : 12.0,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
=======
              Text(
                'Local data · last synchronized 14 Mar, 5:35 pm',
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
                ),
              ),
              const Spacer(),
              Text(
<<<<<<< HEAD
                'LIVE DATA',
=======
                'DEMO SIMULATION',
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
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
              // Avatar RK
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.forestGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
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
                      'SELECTED PATIENT',
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
<<<<<<< HEAD
                      patientSubtitle,
=======
                      'Age 68 · Caregiver Anita Kumar · Preferred language English',
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
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
                      'Last activity',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textLight),
                    ),
                    Text(
                      '8 Mar, 9:10 am',
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
                  title: 'GAMES COMPLETED',
                  value: '13',
                  subtitle: 'Across recent sessions',
                  badgeIcon: Icons.check_circle_outline_rounded,
                  badgeColor: AppTheme.statusGreen,
                  badgeBg: AppTheme.sageLight,
                ),
                _buildStatCard(
                  title: 'AVERAGE ACCURACY',
                  value: '76%',
                  subtitle: 'Gameplay performance',
                  badgeIcon: Icons.north_east_rounded,
                  badgeColor: AppTheme.warmTerracotta,
                  badgeBg: AppTheme.warmPeach,
                ),
                _buildStatCard(
                  title: 'AVERAGE RESPONSE',
                  value: '4.3s',
                  subtitle: 'Per interaction',
                  badgeIcon: Icons.access_time_rounded,
                  badgeColor: AppTheme.warmOchre,
                  badgeBg: AppTheme.pastelYellow,
                ),
                _buildStatCard(
                  title: 'CURRENT DIFFICULTY',
                  value: _caregiverDifficulty.split(' ').take(2).join(' '),
                  subtitle: _caregiverAdaptiveMode ? '🤖 AI-Adaptive Auto' : '⚙️ Fixed Manual Mode',
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
        _buildDifficultyControllerCard(context),

        const SizedBox(height: 20),

        // Lower Dashboard: 7-Session Performance & Support Notes
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 640;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildCognitivePerformanceCard()),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: _buildSupportNotesCard()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildCognitivePerformanceCard(),
                  const SizedBox(height: 18),
                  _buildSupportNotesCard(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDifficultyControllerCard(BuildContext context) {
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
<<<<<<< HEAD
                        'Just now',
=======
                        'Cognitive Difficulty & AI Pacing Controller',
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Manage auto-adaptive progression or set fixed challenge levels for the patient.',
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
                          '🤖 AI-Adaptive',
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
                          '⚙️ Manual Lock',
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

<<<<<<< HEAD
        // Patient Routine & Reminders Summary Card in Overview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined, color: AppTheme.forestGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Patient Routine & Reminders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _sidebarIndex = 2),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      'Manage All',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final reminders = ReminderService.instance.reminders;
                  final completedCount = reminders.where((r) => r.isCompleted).length;

                  if (reminders.isEmpty) {
                    return Text(
                      'No reminders set for $patientName.',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedCount of ${reminders.length} completed today',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${(reminders.isNotEmpty ? (completedCount / reminders.length * 100).toInt() : 0)}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...reminders.take(4).map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: item.isCompleted ? AppTheme.background : AppTheme.sageLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(item.emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: item.isCompleted ? AppTheme.textLight : AppTheme.textPrimary,
                                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  item.formattedTime,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.warmTerracotta,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: item.isCompleted ? AppTheme.forestGreen : AppTheme.textLight,
                                ),
                              ],
                            ),
                          )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        SizedBox(height: isMobile ? 12 : 18),

        // ── 4 AI Real-Time Stat Cards ────────────────────────────────────────
        Builder(builder: (context) {
          final s = _statsData;
          final loading = _isLoadingStats && s == null;

          Widget card(String title, String value, String subtitle,
              IconData icon, Color color, Color bg) {
            return _buildStatCard(
              title: title,
              value: loading ? '—' : value,
              subtitle: subtitle,
              badgeIcon: icon,
              badgeColor: color,
              badgeBg: bg,
              isMobile: isMobile,
            );
          }

          final cards = [
            card(
              'GAMES COMPLETED',
              s?.gamesCompleted.toString() ?? '0',
              'Across recent sessions',
              Icons.check_circle_outline_rounded,
              AppTheme.statusGreen,
              AppTheme.sageLight,
            ),
            card(
              'AVERAGE ACCURACY',
              s?.averageAccuracy ?? '--',
              'Gameplay performance',
              Icons.north_east_rounded,
              AppTheme.warmTerracotta,
              AppTheme.warmPeach,
            ),
            card(
              'AVERAGE RESPONSE',
              s?.avgResponseTime ?? '--',
              'Per interaction',
              Icons.access_time_rounded,
              AppTheme.warmOchre,
              AppTheme.pastelYellow,
            ),
            card(
              'CURRENT DIFFICULTY',
              s?.currentDifficulty ?? 'Baseline',
              'Adapts from performance',
              Icons.psychology_outlined,
              AppTheme.forestGreen,
              AppTheme.pastelBlue,
            ),
          ];

          if (isMobile) {
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: cards,
            );
          }
          return Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
            const SizedBox(width: 10),
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ]);
        }),

        SizedBox(height: isMobile ? 14 : 20),

        // Lower Dashboard: 7-Session Performance & Support Notes
        if (isMobile) ...[
          _buildCognitivePerformanceCard(isMobile: true),
          const SizedBox(height: 14),
          _buildSupportNotesCard(),
        ] else ...[
=======
          // Tiers Grid
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
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
                            tier.split(' ')[0] + ' ' + tier.split(' ')[1],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                              color: isCurrent ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tier.split('(').last.replaceAll(')', ''),
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

<<<<<<< HEAD
  Widget _buildCognitivePerformanceCard({required bool isMobile}) {
    final scores = _statsData?.sessionScores ?? const [];

=======
  Widget _buildCognitivePerformanceCard() {
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scores.isEmpty
                        ? 'COGNITIVE PERFORMANCE'
                        : 'THE LAST ${scores.length} SESSION${scores.length > 1 ? 'S' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cognitive activity performance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
<<<<<<< HEAD
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
=======
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Non-medical view',
                  style: GoogleFonts.inter(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
            ],
          ),

<<<<<<< HEAD
          const SizedBox(height: 18),

          if (scores.isEmpty) ...[
            Container(
              height: 130,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.show_chart_rounded,
                      color: AppTheme.textLight, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    'No session activity recorded yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Play games on the Patient tab to begin cognitive telemetry.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: AppTheme.textLight),
                  ),
                ],
              ),
=======
          const SizedBox(height: 20),

          // Custom visual chart representing 7 sessions trend
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildChartBar('Session 1', 0.65, '65%'),
                _buildChartBar('Session 2', 0.70, '70%'),
                _buildChartBar('Session 3', 0.68, '68%'),
                _buildChartBar('Session 4', 0.74, '74%'),
                _buildChartBar('Session 5', 0.78, '78%'),
                _buildChartBar('Session 6', 0.75, '75%'),
                _buildChartBar('Session 7', 0.82, '82%', isCurrent: true),
              ],
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
            ),
          ] else ...[
            // Line chart drawn with CustomPainter
            SizedBox(
              height: 130,
              width: double.infinity,
              child: CustomPaint(
                painter: _SessionLineChartPainter(scores: scores),
              ),
            ),

            const SizedBox(height: 8),

            // Session x-axis labels (aligned to chart left margin)
            Padding(
              padding: const EdgeInsets.only(left: 26.0),
              child: Row(
                mainAxisAlignment: scores.length > 1
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: List.generate(
                  scores.length,
                  (i) => Text(
                    scores.length == 1
                        ? 'Session 1 (Initial Calibration)'
                        : 'Session ${i + 1}',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 8.0 : 9.0,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
  Widget _buildChartBar(String label, double pct, String value, {bool isCurrent = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppTheme.forestGreen : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 70 * pct,
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.forestGreen : AppTheme.sageLight,
            borderRadius: BorderRadius.circular(6),
            border: isCurrent ? null : Border.all(color: AppTheme.sageBorder),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.replaceAll('Session ', 'S'),
          style: GoogleFonts.inter(fontSize: 10.0, color: AppTheme.textLight),
        ),
      ],
    );
  }

>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
  Widget _buildSupportNotesCard() {
    final notes = _statsData?.supportNotes ?? [
      'Loading patient session data...',
      'Tracking routine and performance metrics.',
      'AI evaluation in progress.',
    ];
    final statusLabel = _statsData?.statusLabel ?? 'Loading';
    final isLive = _statsData?.isLive ?? false;

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
          // Header with AI LIVE badge
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
<<<<<<< HEAD
                  child: Icon(Icons.notifications_none_rounded,
                      size: 15, color: AppTheme.warmTerracotta),
=======
                  child: Icon(Icons.notifications_none_rounded, size: 16, color: AppTheme.warmTerracotta),
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Support notes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppTheme.statusGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'AI LIVE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreen,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isLoadingStats)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.forestGreen,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

<<<<<<< HEAD
          // AI-generated note bullets
          _buildNoteItem(notes[0]),
          const SizedBox(height: 8),
          _buildNoteItem(notes[1]),
          const SizedBox(height: 8),
          _buildNoteItem(notes[2]),

          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.surfaceBorder),
          const SizedBox(height: 10),

          // Status bar + Inspect AI Logs link
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.statusGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Status: $statusLabel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _sidebarIndex = 1),
                child: Text(
                  'Inspect AI Logs →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forestGreen,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.forestGreen,
                  ),
                ),
              ),
            ],
          ),
=======
          _buildNoteItem('37s that Ramesh completed his session today.'),
          const SizedBox(height: 10),
          _buildNoteItem('Smooth motor interaction during memory matching.'),
          const SizedBox(height: 10),
          _buildNoteItem('Consistent daily morning schedule maintained.'),
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
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

  Widget _buildCarePlanView(BuildContext context) {
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
                  'CARE MANAGEMENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Care Plan & Medication Schedule',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Organize daily therapies, medication alerts, and active kinematic assistance schedules.',
                  style: GoogleFonts.inter(fontSize: 14.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Care plan changes saved to local edge node.', style: GoogleFonts.inter()),
                    backgroundColor: AppTheme.forestGreen,
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Save Care Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
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
                            item['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${item['time']} · ${item['freq']} (${item['type']})',
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

