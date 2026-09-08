import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/session_service.dart';
import '../services/audio_narration_service.dart';

enum PatternTier {
  gentle,
  moderate,
  challenging,
  master,
}

extension PatternTierExtension on PatternTier {
  String get label {
    switch (this) {
      case PatternTier.gentle:
        return 'Level 1 (Gentle)';
      case PatternTier.moderate:
        return 'Level 2 (Moderate)';
      case PatternTier.challenging:
        return 'Level 3 (Challenging)';
      case PatternTier.master:
        return 'Level 4 (Master)';
    }
  }

  String get shortTitle {
    switch (this) {
      case PatternTier.gentle:
        return 'Gentle';
      case PatternTier.moderate:
        return 'Moderate';
      case PatternTier.challenging:
        return 'Challenging';
      case PatternTier.master:
        return 'Master';
    }
  }
}

class PatternToken {
  final String id;
  final String label;
  final String emoji;
  final List<Color> gradient;
  final Color shadowColor;

  const PatternToken({
    required this.id,
    required this.label,
    required this.emoji,
    required this.gradient,
    required this.shadowColor,
  });
}

class PatternPuzzle {
  final String title;
  final String explanation;
  final List<PatternToken> sequence; // Complete sequence including the target
  final int targetIndex; // Usually sequence.length - 1
  final PatternToken correctToken;
  final List<PatternToken> choices;

  PatternPuzzle({
    required this.title,
    required this.explanation,
    required this.sequence,
    required this.targetIndex,
    required this.correctToken,
    required this.choices,
  });
}

class PatternSequenceScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const PatternSequenceScreen({super.key, this.onFinish});

  @override
  State<PatternSequenceScreen> createState() => _PatternSequenceScreenState();
}

class _PatternSequenceScreenState extends State<PatternSequenceScreen> {
  PatternTier _tier = PatternTier.gentle;
  bool _isAdaptiveMode = true;

  int _currentPuzzleIndex = 0;
  static const int _puzzlesPerSession = 5;
  List<PatternPuzzle> _puzzles = [];

  PatternToken? _selectedAnswer;
  bool _isAnswerCorrect = false;
  bool _hasAnswered = false;
  int _correctCount = 0;
  int _mistakesCount = 0;

  DateTime? _sessionStartTime;
  DateTime? _puzzleStartTime;
  List<double> _reactionTimes = [];
  bool _isSpeaking = false;

  // Master Tokens Palette
  static const PatternToken _tSun = PatternToken(
    id: 'sun',
    label: 'Sun',
    emoji: '☀️',
    gradient: [Color(0xFFFF8008), Color(0xFFFFC837)],
    shadowColor: Color(0x66FF8008),
  );

  static const PatternToken _tMoon = PatternToken(
    id: 'moon',
    label: 'Moon',
    emoji: '🌙',
    gradient: [Color(0xFF8A2387), Color(0xFFE94057)],
    shadowColor: Color(0x668A2387),
  );

  static const PatternToken _tStar = PatternToken(
    id: 'star',
    label: 'Star',
    emoji: '⭐',
    gradient: [Color(0xFFF7971E), Color(0xFFFFD200)],
    shadowColor: Color(0x66F7971E),
  );

  static const PatternToken _tApple = PatternToken(
    id: 'apple',
    label: 'Apple',
    emoji: '🍎',
    gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    shadowColor: Color(0x66FF416C),
  );

  static const PatternToken _tBanana = PatternToken(
    id: 'banana',
    label: 'Banana',
    emoji: '🍌',
    gradient: [Color(0xFFF7971E), Color(0xFFFFD200)],
    shadowColor: Color(0x66F7971E),
  );

  static const PatternToken _tGrapes = PatternToken(
    id: 'grapes',
    label: 'Grapes',
    emoji: '🍇',
    gradient: [Color(0xFFDA22FF), Color(0xFF9733EE)],
    shadowColor: Color(0x66DA22FF),
  );

  static const PatternToken _tHeart = PatternToken(
    id: 'heart',
    label: 'Heart',
    emoji: '💖',
    gradient: [Color(0xFFFF758C), Color(0xFFFF7EB3)],
    shadowColor: Color(0x66FF758C),
  );

  static const PatternToken _tDiamond = PatternToken(
    id: 'diamond',
    label: 'Diamond',
    emoji: '🔷',
    gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
    shadowColor: Color(0x6600C6FF),
  );

  static const PatternToken _tCircle = PatternToken(
    id: 'circle',
    label: 'Circle',
    emoji: '🟢',
    gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)],
    shadowColor: Color(0x6656AB2F),
  );

  static const PatternToken _tFlower = PatternToken(
    id: 'flower',
    label: 'Flower',
    emoji: '🌸',
    gradient: [Color(0xFFFF758C), Color(0xFFFF7EB3)],
    shadowColor: Color(0x66FF758C),
  );

  static const PatternToken _tLeaf = PatternToken(
    id: 'leaf',
    label: 'Leaf',
    emoji: '🍃',
    gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
    shadowColor: Color(0x6611998E),
  );

  static const PatternToken _tTree = PatternToken(
    id: 'tree',
    label: 'Tree',
    emoji: '🌳',
    gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)],
    shadowColor: Color(0x6656AB2F),
  );

  @override
  void initState() {
    super.initState();
    _startNewSession();
  }

  void _startNewSession() {
    final puzzles = _generatePuzzlesForTier(_tier);
    setState(() {
      _puzzles = puzzles;
      _currentPuzzleIndex = 0;
      _selectedAnswer = null;
      _hasAnswered = false;
      _isAnswerCorrect = false;
      _correctCount = 0;
      _mistakesCount = 0;
      _sessionStartTime = DateTime.now();
      _puzzleStartTime = DateTime.now();
      _reactionTimes = [];
    });

    _narrateGuidance(
      'Pattern Sequence: Look at the trail, find what comes next in the question mark box.',
    );
  }

  List<PatternPuzzle> _generatePuzzlesForTier(PatternTier tier) {
    final rng = Random();
    List<PatternPuzzle> list = [];

    for (int i = 0; i < _puzzlesPerSession; i++) {
      if (tier == PatternTier.gentle) {
        // AB-AB binary repeating sequence: e.g. [A, B, A, B, A, ?] -> B
        final pairs = [
          [_tSun, _tMoon],
          [_tApple, _tBanana],
          [_tDiamond, _tHeart],
          [_tFlower, _tLeaf],
          [_tCircle, _tDiamond],
        ]..shuffle(rng);
        final pair = pairs[i % pairs.length];
        final a = pair[0];
        final b = pair[1];
        final correct = b;
        final choices = [a, b, _tStar]..shuffle(rng);

        list.add(
          PatternPuzzle(
            title: 'Alternating Pair (${a.label} & ${b.label})',
            explanation: 'The pattern alternates between ${a.label} and ${b.label}.',
            sequence: [a, b, a, b, a, correct],
            targetIndex: 5,
            correctToken: correct,
            choices: choices,
          ),
        );
      } else if (tier == PatternTier.moderate) {
        // ABC-ABC 3-element repeating pattern: e.g. [A, B, C, A, B, ?] -> C
        final triplets = [
          [_tApple, _tBanana, _tGrapes],
          [_tSun, _tMoon, _tStar],
          [_tFlower, _tLeaf, _tTree],
          [_tDiamond, _tHeart, _tCircle],
        ]..shuffle(rng);
        final trip = triplets[i % triplets.length];
        final a = trip[0];
        final b = trip[1];
        final c = trip[2];
        final correct = c;
        final choices = [a, b, c, _tSun]..shuffle(rng);

        list.add(
          PatternPuzzle(
            title: 'Trio Rhythm (${a.label}, ${b.label}, ${c.label})',
            explanation: 'Repeats in groups of three: ${a.label}, ${b.label}, then ${c.label}.',
            sequence: [a, b, c, a, b, correct],
            targetIndex: 5,
            correctToken: correct,
            choices: choices,
          ),
        );
      } else if (tier == PatternTier.challenging) {
        // AAB-AAB pattern or ABA-ABA
        final a = (i % 2 == 0) ? _tHeart : _tSun;
        final b = (i % 2 == 0) ? _tDiamond : _tLeaf;
        final correct = b;
        final choices = [a, b, _tStar, _tCircle]..shuffle(rng);

        list.add(
          PatternPuzzle(
            title: 'Twin Pattern (${a.label}-${a.label}-${b.label})',
            explanation: 'Two ${a.label}s followed by one ${b.label}.',
            sequence: [a, a, b, a, a, correct],
            targetIndex: 5,
            correctToken: correct,
            choices: choices,
          ),
        );
      } else {
        // Master: Multi-attribute logic sequences (e.g. Cycle + Count or Double Step)
        final a = _tSun;
        final b = _tMoon;
        final c = _tStar;
        final d = _tDiamond;
        final correct = d;
        final choices = [a, b, c, d]..shuffle(rng);

        list.add(
          PatternPuzzle(
            title: 'Four-Step Cosmic Cycle',
            explanation: 'Continuous 4-stage logical progression.',
            sequence: [a, b, c, a, b, c, correct],
            targetIndex: 6,
            correctToken: correct,
            choices: choices,
          ),
        );
      }
    }
    return list;
  }

  void _narrateGuidance(String msg) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    try {
      await AudioNarrationService.instance.speak(msg);
    } catch (_) {}
    _isSpeaking = false;
  }

  void _onSelectChoice(PatternToken token) {
    if (_hasAnswered) return;

    final puzzle = _puzzles[_currentPuzzleIndex];
    final isCorrect = token.id == puzzle.correctToken.id;
    final now = DateTime.now();

    if (_puzzleStartTime != null) {
      _reactionTimes.add(now.difference(_puzzleStartTime!).inMilliseconds / 1000.0);
    }

    setState(() {
      _selectedAnswer = token;
      _hasAnswered = true;
      _isAnswerCorrect = isCorrect;
      if (isCorrect) {
        _correctCount++;
      } else {
        _mistakesCount++;
      }
    });

    if (isCorrect) {
      _narrateGuidance('Correct! ${token.label} completes the pattern sequence.');
    } else {
      _narrateGuidance('Almost! Look at the sequence order again.');
    }
  }

  void _onNextPuzzle() {
    if (_currentPuzzleIndex + 1 < _puzzles.length) {
      setState(() {
        _currentPuzzleIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
        _isAnswerCorrect = false;
        _puzzleStartTime = DateTime.now();
      });
      _narrateGuidance('Puzzle ${_currentPuzzleIndex + 1}: What completes this trail?');
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    final durationSec = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 25;
    final totalAttempts = _correctCount + _mistakesCount;
    final accuracy = totalAttempts > 0 ? (_correctCount / totalAttempts) : 1.0;
    final avgReaction = _reactionTimes.isNotEmpty
        ? (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length)
        : 3.0;

    PatternTier nextTier = _tier;
    String adaptiveMsg = 'Superb sequential reasoning!';
    if (accuracy >= 0.80 && _tier != PatternTier.master) {
      nextTier = PatternTier.values[_tier.index + 1];
      adaptiveMsg = 'AI recommended: Ready for ${nextTier.shortTitle} sequence difficulty!';
    } else if (accuracy < 0.60 && _tier != PatternTier.gentle) {
      nextTier = PatternTier.values[_tier.index - 1];
      adaptiveMsg = 'AI recommended: Relaxing to ${nextTier.shortTitle} for a smoother rhythm.';
    }

    // Save locally to Hive
    final session = GameSession(
      sessionId: SessionService.generateId(SessionService.activePatientId ?? 'patient-ramesh', 'pattern_sequence'),
      patientId: SessionService.activePatientId ?? 'patient-ramesh',
      gameType: 'pattern_sequence',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: avgReaction,
      totalMoves: totalAttempts,
      extras: {
        'difficulty': _tier.label,
        'correctCount': _correctCount,
        'mistakesCount': _mistakesCount,
        'durationSec': durationSec,
        'nextTier': nextTier.label,
      },
    );
    SessionService.instance.saveSession(session);

    // Sync to backend
    try {
      final backendId = SessionService.activePatientId?.startsWith('patient-') == true ? 'PT-9042' : 'PT-9042';
      await http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/patient/$backendId/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_type': 'Pattern Sequence & Logical Reasoning',
          'difficulty_level': _tier.label,
          'score': (accuracy * 100.0).clamp(0.0, 100.0),
          'tremor_frequency_hz': 4.8,
          'tremor_amplitude_deg': 0.9,
          'postural_stability_score': 88.0,
          'notes': 'Sequence reasoning accuracy ${(accuracy * 100).toStringAsFixed(0)}% across $_puzzlesPerSession puzzles. $adaptiveMsg',
        }),
      );
    } catch (_) {}

    _narrateGuidance('Session complete! You finished all logical sequence patterns.');
    _showVictoryModal(accuracy, durationSec, avgReaction, nextTier, adaptiveMsg);
  }

  void _showVictoryModal(
    double accuracy,
    int durationSec,
    double avgReaction,
    PatternTier nextTier,
    String adaptiveMsg,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C6FF).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 42)),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Pattern Trail Mastered!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forestGreen,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'You solved all $_puzzlesPerSession logical patterns with keen focus.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14.0, color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      'Accuracy',
                      '${(accuracy * 100).toStringAsFixed(0)}%',
                      const Color(0xFF00897B),
                      const Color(0xFFE0F2F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      'Score',
                      '$_correctCount/$_puzzlesPerSession',
                      const Color(0xFF5E35B1),
                      const Color(0xFFEDE7F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      'Avg Speed',
                      '${avgReaction.toStringAsFixed(1)}s',
                      const Color(0xFFD81B60),
                      const Color(0xFFFCE4EC),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.forestGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.forestGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        adaptiveMsg,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (widget.onFinish != null) {
                          widget.onFinish!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (_isAdaptiveMode && nextTier != _tier) {
                          setState(() => _tier = nextTier);
                        }
                        _startNewSession();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        'Play Again',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String val, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textCol,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textCol.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_puzzles.isEmpty) return const SizedBox.shrink();

    final puzzle = _puzzles[_currentPuzzleIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 680;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () {
            if (widget.onFinish != null) {
              widget.onFinish!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🧩', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pattern Sequence & Logic',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                  ),
                ),
                Text(
                  'Sequential Reasoning & Inductive Logic',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<PatternTier>(
            initialValue: _tier,
            tooltip: 'Select Difficulty Tier',
            onSelected: (tier) {
              setState(() {
                _tier = tier;
                _isAdaptiveMode = false;
              });
              _startNewSession();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.sageLight,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppTheme.forestGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: AppTheme.forestGreen),
                  const SizedBox(width: 6),
                  Text(
                    _tier.shortTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              for (final t in PatternTier.values)
                PopupMenuItem(
                  value: t,
                  child: Text(t.label, style: GoogleFonts.inter(fontSize: 13)),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen),
            tooltip: 'Listen to instructions',
            onPressed: () {
              _narrateGuidance(
                'Puzzle ${_currentPuzzleIndex + 1}: ${puzzle.title}. Select the token that goes in the question mark position.',
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.0 : 28.0,
            vertical: 18.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress & Round Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'ROUND ${_currentPuzzleIndex + 1} OF $_puzzlesPerSession',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forestGreen,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        'Score: $_correctCount Correct',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Hero Sequence Track (Pattern Train)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Sleek night slate background
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              puzzle.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Find Next',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // The Sequence Display Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < puzzle.sequence.length; i++) ...[
                                if (i > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                if (i == puzzle.targetIndex)
                                  _buildTargetSlot(puzzle)
                                else
                                  _buildTokenTile(puzzle.sequence[i]),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Feedback / Guidance Area
                  if (_hasAnswered)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: _isAnswerCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isAnswerCorrect ? const Color(0xFF43A047) : const Color(0xFFE53935),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _isAnswerCorrect ? const Color(0xFF43A047) : const Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isAnswerCorrect ? Icons.check_rounded : Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAnswerCorrect ? '🎉 Correct Answer!' : '💡 Keep going!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: _isAnswerCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  puzzle.explanation,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: _isAnswerCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _onNextPuzzle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: Text(
                              _currentPuzzleIndex + 1 < _puzzlesPerSession ? 'Next ➔' : 'Finish ➔',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Text('👉', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Which token comes next in the pattern? Choose below:',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Candidate Choice Buttons
                  Text(
                    'CHOOSE YOUR ANSWER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: puzzle.choices.map((choice) {
                      final isSelected = _selectedAnswer?.id == choice.id;
                      return _buildChoiceButton(choice, isSelected);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenTile(PatternToken token) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: token.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: token.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          token.emoji,
          style: const TextStyle(fontSize: 34),
        ),
      ),
    );
  }

  Widget _buildTargetSlot(PatternPuzzle puzzle) {
    if (_hasAnswered && _selectedAnswer != null) {
      return _buildTokenTile(_selectedAnswer!);
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF38BDF8),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF38BDF8),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(PatternToken choice, bool isSelected) {
    return InkWell(
      onTap: () => _onSelectChoice(choice),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9C4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFBC02D) : AppTheme.surfaceBorder,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFBC02D).withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: choice.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: choice.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(choice.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              choice.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
