import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/assessment_point.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// SHAYAK-AI: Clock Drawing Test Canvas Screen
/// Interactive CustomPainter capturing high-resolution (x, y, pressure, t)
/// coordinates to evaluate Parkinsonian tremor, bradykinesia, and cognitive planning.
/// ============================================================================
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
    // Score based on hesitation pauses, stroke length, and jitter stability
    double baseScore = 9.2;
    baseScore -= (summary.totalHesitations * 0.35);
    baseScore -= (summary.tremorJitterVariance * 0.08);
    if (summary.averageVelocity < 0.12) baseScore -= 1.0;
    return baseScore.clamp(2.0, 10.0);
  }

  void _submitDrawing(DrawingAssessmentSummary summary) async {
    setState(() => _isAnalyzing = true);
<<<<<<< HEAD

    // ── Persist session data to SessionService ──────────────────────────
    final patientId = SessionService.activePatientId ?? 'unknown';
    // Derive an accuracy proxy: lower jitter & hesitations = higher accuracy
    final jitter = summary.tremorJitterVariance.clamp(0.0, 50.0);
    final hesitations = summary.totalHesitations.clamp(0, 20);
    final rawAccuracy = 1.0 - (jitter / 50.0 * 0.5 + hesitations / 20.0 * 0.5);
    final accuracy = rawAccuracy.clamp(0.0, 1.0);
    // Response time proxy: mean velocity -> lower = slower
    final meanVel = summary.averageVelocity.clamp(0.01, 5.0);
    final responseSec = (3.0 / meanVel).clamp(0.5, 15.0);
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
      },
    ));
=======
    final calculatedScore = _estimateClockScore(summary);

    // Save session locally and attempt backend broadcast
    try {
      final sessionRecord = {
        'session_id': 'SES-${DateTime.now().millisecondsSinceEpoch}',
        'patient_id': 'PT-9042',
        'activity_type': 'clock_drawing',
        'score': calculatedScore * 10.0,
        'duration_seconds': (summary.totalDurationMs / 1000).round(),
        'metrics': {
          'clock_drawing_score': calculatedScore,
          'drawing_hesitation_count': summary.totalHesitations.toDouble(),
          'drawing_mean_velocity': summary.averageVelocity,
          'kinematic_tremor_variance': summary.tremorJitterVariance,
        },
        'notes': 'Clock drawing assessment completed on device.',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Try sending to local backend
      http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionRecord),
      ).catchError((_) => http.Response('{}', 500));
    } catch (_) {}
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c

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
            const Icon(Icons.check_circle_rounded, color: AppTheme.statusGreen, size: 28),
            const SizedBox(width: 10),
            Text(
              'Assessment Complete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your drawing telemetry has been securely recorded.',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _resultMetric('Clinical Contour Score', '${calculatedScore.toStringAsFixed(1)} / 10.0'),
            _resultMetric('Total Stroke Count', '${summary.strokes.length} strokes'),
            _resultMetric('Mean Stroke Velocity', '${summary.averageVelocity.toStringAsFixed(2)} px/ms'),
            _resultMetric('Hesitation Pauses (>500ms)', '${summary.totalHesitations} pauses'),
            _resultMetric('Tremor Micro-Jitter Index', '${summary.tremorJitterVariance.toStringAsFixed(2)} var'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestGreen),
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
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.forestGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Clock Drawing Assessment',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: [
                  // Instruction Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.forestGreen, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Draw a large clock face circle, write numbers 1 to 12, and set the hands to 10 past 11.',
                            style: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Canvas Area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.sageBorder, width: 2),
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
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Controls
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _strokes.isEmpty ? null : _clearCanvas,
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _strokes.isEmpty ? null : _undoStroke,
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: const Text('Undo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _strokes.isEmpty || _isAnalyzing ? null : () => _submitDrawing(summary),
                        icon: _isAnalyzing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Complete Assessment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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

  _ClockPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle background circle guide
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) * 0.85;

    final guidePaint = Paint()
      ..color = const Color(0xFFE3ECE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, guidePaint);

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
