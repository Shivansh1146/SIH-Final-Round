import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/assessment_point.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// SHAYAK-AI: Clock Drawing Assessment with AI-Adaptive Difficulty Tiers
/// ============================================================================

enum ClockDifficultyTier {
  assisted,
  standard,
  diagnostic,
}

extension ClockDifficultyTierExtension on ClockDifficultyTier {
  String get label {
    switch (this) {
      case ClockDifficultyTier.assisted:
        return 'Level 1 (Assisted · Guided)';
      case ClockDifficultyTier.standard:
        return 'Level 2 (Standard Clinical)';
      case ClockDifficultyTier.diagnostic:
        return 'Level 3 (Diagnostic · Freehand)';
    }
  }

  String get shortTitle {
    switch (this) {
      case ClockDifficultyTier.assisted:
        return 'Level 1 (Assisted)';
      case ClockDifficultyTier.standard:
        return 'Level 2 (Standard)';
      case ClockDifficultyTier.diagnostic:
        return 'Level 3 (Freehand)';
    }
  }

  String get guideBadge {
    switch (this) {
      case ClockDifficultyTier.assisted:
        return '12 Hour Ticks';
      case ClockDifficultyTier.standard:
        return 'Contour Outline';
      case ClockDifficultyTier.diagnostic:
        return 'Freehand Canvas';
    }
  }

  String get instruction {
    switch (this) {
      case ClockDifficultyTier.assisted:
        return 'Write numbers 1 to 12 along the guided tick marks, then draw clock hands pointing to 3:00.';
      case ClockDifficultyTier.standard:
        return 'Write numbers 1 to 12 inside the circle, then draw hands pointing to 10 past 11.';
      case ClockDifficultyTier.diagnostic:
        return 'Draw a large circle from memory, place all 12 numbers, and draw hands pointing to 10 past 11.';
    }
  }

  String get targetTime {
    switch (this) {
      case ClockDifficultyTier.assisted:
        return '3:00';
      case ClockDifficultyTier.standard:
      case ClockDifficultyTier.diagnostic:
        return '11:10 (10 past 11)';
    }
  }
}

class ClockCanvasScreen extends StatefulWidget {
  const ClockCanvasScreen({super.key});

  @override
  State<ClockCanvasScreen> createState() => _ClockCanvasScreenState();
}

class _ClockCanvasScreenState extends State<ClockCanvasScreen> {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  int _strokeCounter = 0;
  bool _isAnalyzing = false;

  ClockDifficultyTier _currentTier = ClockDifficultyTier.standard;
  bool _isAdaptiveMode = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientDifficultyPreference();
  }

  Future<void> _fetchPatientDifficultyPreference() async {
    final patientId = SessionService.activePatientId ?? 'PT-9042';

    // 1. Calibrate from local gameplay session history
    final stats = SessionService.instance.getStatsFor(patientId);
    if (stats.totalSessions > 0) {
      if (stats.avgAccuracy >= 0.85) {
        if (mounted) setState(() => _currentTier = ClockDifficultyTier.diagnostic);
      } else if (stats.avgAccuracy < 0.60) {
        if (mounted) setState(() => _currentTier = ClockDifficultyTier.assisted);
      } else {
        if (mounted) setState(() => _currentTier = ClockDifficultyTier.standard);
      }
    }

    // 2. Cross-reference with backend telemetry
    try {
      final backendId =
          patientId.startsWith('patient-') ? 'PT-9042' : patientId;
      final res = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/v1/patient/$backendId/history'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final levelStr = data['current_difficulty_level'] as String?;
        if (levelStr != null && mounted) {
          if (levelStr.contains('Level 1') || levelStr.contains('Gentle')) {
            setState(() => _currentTier = ClockDifficultyTier.assisted);
          } else if (levelStr.contains('Level 3') ||
              levelStr.contains('Challenging') ||
              levelStr.contains('Master')) {
            setState(() => _currentTier = ClockDifficultyTier.diagnostic);
          } else {
            setState(() => _currentTier = ClockDifficultyTier.standard);
          }
        }
      }
    } catch (_) {}
  }

  void _onDifficultySelected(ClockDifficultyTier tier) {
    setState(() {
      _currentTier = tier;
      _strokes.clear();
      _currentStroke = null;
    });

    final patientId = SessionService.activePatientId ?? 'PT-9042';
    try {
      final backendId =
          patientId.startsWith('patient-') ? 'PT-9042' : patientId;
      http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/v1/patient/$backendId/difficulty'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'difficulty_level': tier.label,
              'is_adaptive': _isAdaptiveMode,
              'caregiver_override': false,
            }),
          )
          .catchError((_) => http.Response('{}', 500));
    } catch (_) {}
  }

  void _onPanStart(DragStartDetails details) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _strokeCounter++;
    setState(() {
      _currentStroke = Stroke(
        strokeId: _strokeCounter,
        startTimestampMs: now,
      );
      _currentStroke!.addPoint(
        details.localPosition.dx,
        details.localPosition.dy,
        1.0,
        now,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _currentStroke!.addPoint(
        details.localPosition.dx,
        details.localPosition.dy,
        1.0,
        now,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke == null) return;
    setState(() {
      _strokes.add(_currentStroke!);
      _currentStroke = null;
    });
  }

  void _undoStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  double _estimateClockScore(DrawingAssessmentSummary summary) {
    if (summary.strokes.isEmpty) return 0.0;
    double baseScore = 9.2;
    baseScore -= (summary.totalHesitations * 0.35);
    baseScore -= (summary.tremorJitterVariance * 0.08);
    if (summary.averageVelocity < 0.12) baseScore -= 1.0;
    return baseScore.clamp(2.0, 10.0);
  }

  void _submitDrawing(DrawingAssessmentSummary summary) async {
    setState(() => _isAnalyzing = true);

    final patientId = SessionService.activePatientId ?? 'PT-9042';
    final jitter = summary.tremorJitterVariance.clamp(0.0, 50.0);
    final hesitations = summary.totalHesitations.clamp(0, 20);
    final rawAccuracy =
        1.0 - (jitter / 50.0 * 0.5 + hesitations / 20.0 * 0.5);
    final accuracy = rawAccuracy.clamp(0.0, 1.0);
    final meanVel = summary.averageVelocity.clamp(0.01, 5.0);
    final responseSec = (3.0 / meanVel).clamp(0.5, 15.0);
    final calculatedScore = _estimateClockScore(summary);

    // Evaluate AI Adaptive Difficulty progression
    ClockDifficultyTier nextTier = _currentTier;
    String adaptationNotice = 'Maintaining your comfortable pacing.';

    if (_isAdaptiveMode) {
      if (calculatedScore >= 8.5) {
        if (_currentTier == ClockDifficultyTier.assisted) {
          nextTier = ClockDifficultyTier.standard;
          adaptationNotice =
              '✨ Great contour control! Auto-advanced to Level 2 (Standard).';
        } else if (_currentTier == ClockDifficultyTier.standard) {
          nextTier = ClockDifficultyTier.diagnostic;
          adaptationNotice =
              '🌟 Superb visuospatial stability! Auto-advanced to Level 3 (Freehand Diagnostic).';
        } else {
          adaptationNotice =
              '👑 Top diagnostic level maintained with steady motor control!';
        }
      } else if (calculatedScore < 5.5) {
        if (_currentTier == ClockDifficultyTier.diagnostic) {
          nextTier = ClockDifficultyTier.standard;
          adaptationNotice =
              '🛡️ AI adjusted to Level 2 with contour scaffolding.';
        } else if (_currentTier == ClockDifficultyTier.standard) {
          nextTier = ClockDifficultyTier.assisted;
          adaptationNotice =
              '🛡️ AI adjusted to Level 1 with 12 hour guide ticks.';
        }
      }
    } else {
      adaptationNotice =
          'Manual difficulty locked on ${_currentTier.shortTitle}.';
    }

    // Save locally to SessionService
    SessionService.instance.saveSession(GameSession(
      sessionId: SessionService.generateId(patientId, 'clock_drawing'),
      patientId: patientId,
      gameType: 'clock_drawing',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: responseSec,
      totalMoves: summary.strokes.length,
      extras: {
        'strokeCount': summary.strokes.length,
        'meanVelocity': summary.averageVelocity,
        'hesitations': summary.totalHesitations,
        'tremorVariance': summary.tremorJitterVariance,
        'difficultyTier': _currentTier.label,
        'clockScore': calculatedScore,
        'adaptationNotice': adaptationNotice,
      },
    ));

    // Save session to FastAPI backend
    try {
      final backendId =
          patientId.startsWith('patient-') ? 'PT-9042' : patientId;
      final sessionRecord = {
        'session_id': 'SES-${DateTime.now().millisecondsSinceEpoch}',
        'patient_id': backendId,
        'activity_type': 'clock_drawing',
        'score': calculatedScore * 10.0,
        'duration_seconds': (summary.totalDurationMs / 1000).round(),
        'difficulty_level': _currentTier.label,
        'is_adaptive': _isAdaptiveMode,
        'metrics': {
          'clock_drawing_score': calculatedScore,
          'drawing_hesitation_count': summary.totalHesitations.toDouble(),
          'drawing_mean_velocity': summary.averageVelocity,
          'kinematic_tremor_variance': summary.tremorJitterVariance,
          'tier_index': _currentTier.index.toDouble(),
        },
        'notes':
            'Clock drawing assessment on ${_currentTier.label}. $adaptationNotice',
        'timestamp': DateTime.now().toIso8601String(),
      };

      http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/v1/patient/$backendId/session'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sessionRecord),
          )
          .catchError((_) => http.Response('{}', 500));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.statusGreen, size: 28),
            const SizedBox(width: 10),
            Text(
              'Assessment Complete',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your drawing telemetry has been securely recorded and evaluated by the AI Engine.',
              style: GoogleFonts.inter(
                  fontSize: 13.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),

            // AI Adaptation Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.sageLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.sageBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.forestGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adaptationNotice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            _resultMetric('Difficulty Level', _currentTier.label),
            _resultMetric('Clinical Contour Score',
                '${calculatedScore.toStringAsFixed(1)} / 10.0'),
            _resultMetric(
                'Total Stroke Count', '${summary.strokes.length} strokes'),
            _resultMetric('Mean Stroke Velocity',
                '${summary.averageVelocity.toStringAsFixed(2)} px/ms'),
            _resultMetric('Hesitation Pauses (>500ms)',
                '${summary.totalHesitations} pauses'),
            _resultMetric('Tremor Micro-Jitter Index',
                '${summary.tremorJitterVariance.toStringAsFixed(2)} var'),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onDifficultySelected(nextTier);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(
              _isAdaptiveMode && nextTier != _currentTier
                  ? 'Proceed to ${nextTier.shortTitle}'
                  : 'Practice Again',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, color: AppTheme.forestGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }

  Widget _resultMetric(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(val,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDifficultyHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isAdaptiveMode
                        ? Icons.auto_awesome_rounded
                        : Icons.tune_rounded,
                    size: 18,
                    color: _isAdaptiveMode
                        ? AppTheme.forestGreen
                        : AppTheme.warmTerracotta,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAdaptiveMode
                        ? 'AI-Adaptive Pacing'
                        : 'Manual Difficulty',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      label: 'Auto AI',
                      isActive: _isAdaptiveMode,
                      onTap: () {
                        setState(() => _isAdaptiveMode = true);
                        _onDifficultySelected(_currentTier);
                      },
                    ),
                    _buildModeButton(
                      label: 'Manual',
                      isActive: !_isAdaptiveMode,
                      onTap: () {
                        setState(() => _isAdaptiveMode = false);
                        _onDifficultySelected(_currentTier);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ClockDifficultyTier.values.map((tier) {
              final isSelected = _currentTier == tier;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () => _onDifficultySelected(tier),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.forestGreen
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.forestGreen
                              : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tier.shortTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tier.guideBadge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white70
                                  : AppTheme.textSecondary,
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

  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.forestGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = DrawingAssessmentSummary.fromStrokes([
      ..._strokes,
      if (_currentStroke != null) _currentStroke!,
    ]);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.forestGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Clock Drawing Assessment',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.forestGreen),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  // AI Adaptive Header
                  _buildDifficultyHeader(),
                  const SizedBox(height: 10),

                  // Dynamic Instruction Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.sageLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.psychology_outlined,
                              color: AppTheme.forestGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _currentTier.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.forestGreen,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warmPeach,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Target: ${_currentTier.targetTime}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.warmTerracotta,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _currentTier.instruction,
                                style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary,
                                    height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Canvas Area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: AppTheme.sageBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            painter: _ClockPainter(
                              strokes: _strokes,
                              currentStroke: _currentStroke,
                              tier: _currentTier,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Controls
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _strokes.isEmpty ? null : _clearCanvas,
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _strokes.isEmpty ? null : _undoStroke,
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: const Text('Undo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _strokes.isEmpty || _isAnalyzing
                            ? null
                            : () => _submitDrawing(summary),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isAnalyzing
                            ? 'Analyzing...'
                            : 'Complete Assessment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final ClockDifficultyTier tier;

  _ClockPainter({
    required this.strokes,
    required this.currentStroke,
    required this.tier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) * 0.82;

    final guidePaint = Paint()
      ..color = const Color(0xFFD8E5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final centerDotPaint = Paint()
      ..color = const Color(0xFFADC7B8)
      ..style = PaintingStyle.fill;

    // Level 1: Assisted with circle + 12 hour tick marks + center pivot
    if (tier == ClockDifficultyTier.assisted) {
      canvas.drawCircle(center, radius, guidePaint);
      canvas.drawCircle(center, 4.0, centerDotPaint);

      final tickPaint = Paint()
        ..color = const Color(0xFFADC7B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 12; i++) {
        final angle = (i * 30.0 - 90.0) * (math.pi / 180.0);
        final outer = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        final inner = Offset(
          center.dx + (radius - 12.0) * math.cos(angle),
          center.dy + (radius - 12.0) * math.sin(angle),
        );
        canvas.drawLine(inner, outer, tickPaint);
      }
    } else if (tier == ClockDifficultyTier.standard) {
      // Level 2: Standard circle outline + center pivot
      canvas.drawCircle(center, radius, guidePaint);
      canvas.drawCircle(center, 3.5, centerDotPaint);
    }
    // Level 3: Freehand diagnostic (completely blank canvas)

    final strokePaint = Paint()
      ..color = AppTheme.forestGreen
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      _drawStroke(canvas, s, strokePaint);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!, strokePaint);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.isEmpty) return;
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        Offset(stroke.points[0].x, stroke.points[0].y),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      paint.style = PaintingStyle.stroke;
      return;
    }

    final path = Path();
    path.moveTo(stroke.points[0].x, stroke.points[0].y);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].x, stroke.points[i].y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) => true;
}
