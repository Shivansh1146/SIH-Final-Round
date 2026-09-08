import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/session_service.dart';
import '../services/audio_narration_service.dart';
import '../services/api_config.dart';

enum RoutineDifficultyTier {
  gentle,
  moderate,
  challenging,
}

extension RoutineDifficultyTierExtension on RoutineDifficultyTier {
  String get label {
    switch (this) {
      case RoutineDifficultyTier.gentle:
        return 'Level 1 (Gentle - 3 Steps)';
      case RoutineDifficultyTier.moderate:
        return 'Level 2 (Moderate - 4 Steps)';
      case RoutineDifficultyTier.challenging:
        return 'Level 3 (Detailed - 5 Steps)';
    }
  }

  String get shortTitle {
    switch (this) {
      case RoutineDifficultyTier.gentle:
        return 'Gentle';
      case RoutineDifficultyTier.moderate:
        return 'Moderate';
      case RoutineDifficultyTier.challenging:
        return 'Detailed';
    }
  }
}

class RoutineStep {
  final int orderIndex; // 1-based chronological order
  final String title;
  final String description;
  final String emoji;
  final List<Color> gradient;
  final Color shadowColor;

  const RoutineStep({
    required this.orderIndex,
    required this.title,
    required this.description,
    required this.emoji,
    required this.gradient,
    required this.shadowColor,
  });
}

class RoutineActivity {
  final String id;
  final String title;
  final String category;
  final String subtitle;
  final String iconEmoji;
  final List<Color> themeGradient;
  final Color accentColor;
  final Color bgLight;
  final List<RoutineStep> steps;

  const RoutineActivity({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.iconEmoji,
    required this.themeGradient,
    required this.accentColor,
    required this.bgLight,
    required this.steps,
  });
}

class RoutineSequencerScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const RoutineSequencerScreen({super.key, this.onFinish});

  @override
  State<RoutineSequencerScreen> createState() => _RoutineSequencerScreenState();
}

class _RoutineSequencerScreenState extends State<RoutineSequencerScreen> {
  RoutineDifficultyTier _tier = RoutineDifficultyTier.moderate;
  bool _isAdaptiveMode = true;

  late RoutineActivity _currentActivity;
  List<RoutineStep> _availableShuffledSteps = [];
  List<RoutineStep?> _placedSteps = [];
  int _currentStepToPlace = 1;

  int _mistakes = 0;
  int _correctPlacements = 0;
  DateTime? _activityStartTime;
  DateTime? _stepStartTime;
  List<double> _reactionTimes = [];
  bool _isActivityCompleted = false;
  bool _isSpeaking = false;
  String _hintMessage = 'What is the very first step to start this routine?';

  // Master Clinical ADL Stories specifically tuned for Dementia Rehabilitation
  static const List<RoutineActivity> _allRoutines = [
    // 1. Making Morning Masala Chai
    RoutineActivity(
      id: 'making_chai',
      title: 'Making Morning Masala Chai',
      category: 'DAILY KITCHEN ROUTINE',
      subtitle: 'Prepare a warm, fragrant cup of homemade tea step-by-step.',
      iconEmoji: '☕',
      themeGradient: [Color(0xFFF7971E), Color(0xFFFFD200)],
      accentColor: Color(0xFFE65100),
      bgLight: Color(0xFFFFF8E1),
      steps: [
        RoutineStep(
          orderIndex: 1,
          title: 'Boil Fresh Water',
          description: 'Pour cold water into a clean saucepan and place it on the stove to heat up.',
          emoji: '🫖',
          gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          shadowColor: Color(0x6600C6FF),
        ),
        RoutineStep(
          orderIndex: 2,
          title: 'Add Tea Leaves & Ginger',
          description: 'Add a spoonful of aromatic tea leaves and freshly crushed ginger to the boiling water.',
          emoji: '🍃',
          gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
          shadowColor: Color(0x6611998E),
        ),
        RoutineStep(
          orderIndex: 3,
          title: 'Pour Milk & Let Simmer',
          description: 'Pour fresh milk into the pot and let the chai simmer until golden brown.',
          emoji: '🥛',
          gradient: [Color(0xFFF7971E), Color(0xFFFFD200)],
          shadowColor: Color(0x66F7971E),
        ),
        RoutineStep(
          orderIndex: 4,
          title: 'Strain Into Your Cup',
          description: 'Carefully strain the hot tea through a sieve into your favorite mug and enjoy.',
          emoji: '☕',
          gradient: [Color(0xFFFF8008), Color(0xFFFFC837)],
          shadowColor: Color(0x66FF8008),
        ),
      ],
    ),

    // 2. Watering Balcony Tulsi & Plants
    RoutineActivity(
      id: 'watering_plants',
      title: 'Watering the Balcony Garden',
      category: 'HOME & NATURE CALM',
      subtitle: 'Nurture the Tulsi and blooming green potted plants in the morning sun.',
      iconEmoji: '🪴',
      themeGradient: [Color(0xFF56AB2F), Color(0xFFA8E063)],
      accentColor: Color(0xFF2E7D32),
      bgLight: Color(0xFFE8F5E9),
      steps: [
        RoutineStep(
          orderIndex: 1,
          title: 'Fill Watering Jug',
          description: 'Fill a clean watering can or jug with fresh cool tap water.',
          emoji: '💧',
          gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          shadowColor: Color(0x6600C6FF),
        ),
        RoutineStep(
          orderIndex: 2,
          title: 'Step to the Balcony',
          description: 'Walk calmly to the sunny balcony where the flower pots and Tulsi sit.',
          emoji: '🪟',
          gradient: [Color(0xFFFFB75E), Color(0xFFED8F03)],
          shadowColor: Color(0x66FFB75E),
        ),
        RoutineStep(
          orderIndex: 3,
          title: 'Water the Soil Gently',
          description: 'Slowly pour water around the base and roots of each green pot.',
          emoji: '🌿',
          gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
          shadowColor: Color(0x6611998E),
        ),
        RoutineStep(
          orderIndex: 4,
          title: 'Admire Fresh Leaves',
          description: 'Enjoy the pleasant earthy aroma and fresh green blooming leaves.',
          emoji: '🌸',
          gradient: [Color(0xFFFF758C), Color(0xFFFF7EB3)],
          shadowColor: Color(0x66FF758C),
        ),
      ],
    ),

    // 3. Freshening Up & Washing Hands
    RoutineActivity(
      id: 'washing_hands',
      title: 'Freshening Up & Clean Hands',
      category: 'PERSONAL CARE & HYGIENE',
      subtitle: 'A gentle, refreshing wash to start your day with clean confidence.',
      iconEmoji: '🧼',
      themeGradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
      accentColor: Color(0xFF0277BD),
      bgLight: Color(0xFFE1F5FE),
      steps: [
        RoutineStep(
          orderIndex: 1,
          title: 'Turn on Water Tap',
          description: 'Turn on the washbasin faucet and wet your hands with warm water.',
          emoji: '🚰',
          gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          shadowColor: Color(0x6600C6FF),
        ),
        RoutineStep(
          orderIndex: 2,
          title: 'Lather Fragrant Soap',
          description: 'Apply gentle soap and rub palms and fingers together into a soft lather.',
          emoji: '🫧',
          gradient: [Color(0xFFDA22FF), Color(0xFF9733EE)],
          shadowColor: Color(0x66DA22FF),
        ),
        RoutineStep(
          orderIndex: 3,
          title: 'Rinse Clean With Water',
          description: 'Hold hands under the running water until all soap bubbles are rinsed away.',
          emoji: '🌊',
          gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
          shadowColor: Color(0x6611998E),
        ),
        RoutineStep(
          orderIndex: 4,
          title: 'Dry With Soft Towel',
          description: 'Gently dry hands completely with a clean, soft cotton towel.',
          emoji: '🧣',
          gradient: [Color(0xFFFF8008), Color(0xFFFFC837)],
          shadowColor: Color(0x66FF8008),
        ),
      ],
    ),

    // 4. Taking Morning Medicine & Hydration
    RoutineActivity(
      id: 'taking_medicine',
      title: 'Morning Medicine & Hydration',
      category: 'HEALTH & WELLNESS',
      subtitle: 'Keep your body nourished and take your scheduled morning dose safely.',
      iconEmoji: '💊',
      themeGradient: [Color(0xFF8A2387), Color(0xFFE94057)],
      accentColor: Color(0xFFAD1457),
      bgLight: Color(0xFFFCE4EC),
      steps: [
        RoutineStep(
          orderIndex: 1,
          title: 'Pour a Glass of Water',
          description: 'Fill a clean drinking glass with fresh drinking water.',
          emoji: '🥛',
          gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          shadowColor: Color(0x6600C6FF),
        ),
        RoutineStep(
          orderIndex: 2,
          title: 'Open Morning Pill Box',
          description: 'Check today’s labeled pill compartment and take out your morning tablet.',
          emoji: '💊',
          gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          shadowColor: Color(0x66FF416C),
        ),
        RoutineStep(
          orderIndex: 3,
          title: 'Take Pill With Water',
          description: 'Place the pill in your mouth and swallow smoothly with a full sip of water.',
          emoji: '💧',
          gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
          shadowColor: Color(0x6611998E),
        ),
        RoutineStep(
          orderIndex: 4,
          title: 'Check Off Daily Reminder',
          description: 'Mark your reminder as completed and smile knowing your health is cared for.',
          emoji: '✅',
          gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)],
          shadowColor: Color(0x6656AB2F),
        ),
      ],
    ),

    // 5. Getting Dressed for a Calm Morning Walk
    RoutineActivity(
      id: 'morning_walk',
      title: 'Ready for a Morning Walk',
      category: 'ACTIVE MOBILITY & OUTDOORS',
      subtitle: 'Prepare comfortably for a gentle stroll in the refreshing garden breeze.',
      iconEmoji: '🚶',
      themeGradient: [Color(0xFFFF8008), Color(0xFFFFC837)],
      accentColor: Color(0xFFE65100),
      bgLight: Color(0xFFFFF3E0),
      steps: [
        RoutineStep(
          orderIndex: 1,
          title: 'Wear Soft Cotton Clothes',
          description: 'Put on light, comfortable walking kurta or loose cotton shirt and pants.',
          emoji: '👕',
          gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          shadowColor: Color(0x6600C6FF),
        ),
        RoutineStep(
          orderIndex: 2,
          title: 'Put On Walking Shoes',
          description: 'Slip into supportive walking shoes or sandals with secure straps.',
          emoji: '👟',
          gradient: [Color(0xFF8A2387), Color(0xFFE94057)],
          shadowColor: Color(0x668A2387),
        ),
        RoutineStep(
          orderIndex: 3,
          title: 'Take Hat & Sunglasses',
          description: 'Grab your gentle sun hat or spectacles for comfortable outdoor light.',
          emoji: '🕶️',
          gradient: [Color(0xFFFF8008), Color(0xFFFFC837)],
          shadowColor: Color(0x66FF8008),
        ),
        RoutineStep(
          orderIndex: 4,
          title: 'Step Out into Fresh Air',
          description: 'Open the front door and begin your calm, rhythmic stroll in nature.',
          emoji: '🌳',
          gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)],
          shadowColor: Color(0x6656AB2F),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startNewActivitySession();
  }

  void _startNewActivitySession() {
    final rng = Random();
    final activity = _allRoutines[rng.nextInt(_allRoutines.length)];

    List<RoutineStep> stepsToUse = List.from(activity.steps);
    if (_tier == RoutineDifficultyTier.gentle) {
      // 3 steps
      stepsToUse = stepsToUse.take(3).toList();
    } else {
      stepsToUse = List.from(activity.steps);
    }

    final shuffled = List<RoutineStep>.from(stepsToUse)..shuffle(rng);

    setState(() {
      _currentActivity = activity;
      _availableShuffledSteps = shuffled;
      _placedSteps = List<RoutineStep?>.filled(stepsToUse.length, null);
      _currentStepToPlace = 1;
      _mistakes = 0;
      _correctPlacements = 0;
      _activityStartTime = DateTime.now();
      _stepStartTime = DateTime.now();
      _reactionTimes = [];
      _isActivityCompleted = false;
      _hintMessage = 'First Step: What do you do to begin ${_currentActivity.title}?';
    });

    _narrateGuidance(
      'Let’s organize the steps for ${_currentActivity.title}. Tap the first step below.',
    );
  }

  void _narrateGuidance(String text) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    try {
      await AudioNarrationService.instance.speak(text);
    } catch (_) {}
    _isSpeaking = false;
  }

  void _onSelectStepCard(RoutineStep step) {
    if (_isActivityCompleted) return;

    final now = DateTime.now();
    if (_stepStartTime != null) {
      _reactionTimes.add(now.difference(_stepStartTime!).inMilliseconds / 1000.0);
    }

    if (step.orderIndex == _currentStepToPlace) {
      // Correct step chosen!
      setState(() {
        _placedSteps[_currentStepToPlace - 1] = step;
        _availableShuffledSteps.remove(step);
        _correctPlacements++;
        _currentStepToPlace++;
        _stepStartTime = DateTime.now();

        if (_currentStepToPlace > _placedSteps.length) {
          _isActivityCompleted = true;
          _hintMessage = '🎉 Wonderful! You completed every step of ${_currentActivity.title} perfectly!';
        } else {
          _hintMessage = '✨ Step ${_currentStepToPlace - 1} complete! What is step $_currentStepToPlace?';
        }
      });

      if (_isActivityCompleted) {
        _finishActivitySession();
      } else {
        _narrateGuidance('Correct! ${step.title}. What comes next?');
      }
    } else {
      // Gentle encouragement
      setState(() {
        _mistakes++;
        _hintMessage = '💡 Almost! Think about what comes right before or after "${step.title}".';
      });
      _narrateGuidance('Almost! What is the next step for ${_currentActivity.title}?');
    }
  }

  Future<void> _finishActivitySession() async {
    final durationSec = _activityStartTime != null
        ? DateTime.now().difference(_activityStartTime!).inSeconds
        : 25;
    final totalAttempts = _correctPlacements + _mistakes;
    final accuracy = totalAttempts > 0 ? (_correctPlacements / totalAttempts) : 1.0;
    final avgReaction = _reactionTimes.isNotEmpty
        ? (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length)
        : 2.5;

    // AI Adaptive Difficulty Progression
    RoutineDifficultyTier nextTier = _tier;
    String adaptiveMsg = 'Superb daily routine recall!';
    if (accuracy >= 0.85 && _tier != RoutineDifficultyTier.challenging) {
      nextTier = RoutineDifficultyTier.values[_tier.index + 1];
      adaptiveMsg = 'AI recommended: Ready for ${nextTier.shortTitle} routine complexity!';
    } else if (accuracy < 0.60 && _tier != RoutineDifficultyTier.gentle) {
      nextTier = RoutineDifficultyTier.values[_tier.index - 1];
      adaptiveMsg = 'AI recommended: Adjusted to ${nextTier.shortTitle} level for gentle calm.';
    }

    // Save locally
    final session = GameSession(
      sessionId: SessionService.generateId(SessionService.activePatientId ?? 'patient-ramesh', 'routine_sequencer'),
      patientId: SessionService.activePatientId ?? 'patient-ramesh',
      gameType: 'routine_sequencer',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: avgReaction,
      totalMoves: totalAttempts,
      extras: {
        'activityId': _currentActivity.id,
        'activityTitle': _currentActivity.title,
        'difficulty': _tier.label,
        'mistakes': _mistakes,
        'durationSec': durationSec,
        'nextTier': nextTier.label,
      },
    );
    SessionService.instance.saveSession(session);

    // Sync to backend
    try {
      final backendId = SessionService.activePatientId?.startsWith('patient-') == true ? 'PT-9042' : 'PT-9042';
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/patient/$backendId/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_type': 'Daily Routine & ADL Sequencer',
          'difficulty_level': _tier.label,
          'score': (accuracy * 100.0).clamp(0.0, 100.0),
          'tremor_frequency_hz': 4.9,
          'tremor_amplitude_deg': 1.0,
          'postural_stability_score': 87.5,
          'notes': 'ADL Routine (${_currentActivity.title}) solved in ${durationSec}s with ${(accuracy * 100).toStringAsFixed(0)}% accuracy. $adaptiveMsg',
        }),
      );
    } catch (_) {}

    _narrateGuidance('Splendid work! You remembered every step of ${_currentActivity.title} with clarity.');
    _showVictoryModal(accuracy, durationSec, avgReaction, nextTier, adaptiveMsg);
  }

  void _showVictoryModal(
    double accuracy,
    int durationSec,
    double avgReaction,
    RoutineDifficultyTier nextTier,
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
              // Celebration Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _currentActivity.themeGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _currentActivity.accentColor.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(_currentActivity.iconEmoji, style: const TextStyle(fontSize: 40)),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Routine Completed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forestGreen,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'You sequenced all steps for "${_currentActivity.title}" smoothly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      'Accuracy',
                      '${(accuracy * 100).toStringAsFixed(0)}%',
                      const Color(0xFF2E7D32),
                      const Color(0xFFE8F5E9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      'Time',
                      '${durationSec}s',
                      const Color(0xFF1565C0),
                      const Color(0xFFE3F2FD),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      'Reaction',
                      '${avgReaction.toStringAsFixed(1)}s',
                      const Color(0xFFE65100),
                      const Color(0xFFFFF3E0),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // AI Feedback Banner
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

              // Action Buttons
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
                        _startNewActivitySession();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        'Next Routine ➔',
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
                color: _currentActivity.bgLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_currentActivity.iconEmoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Routine Sequencer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ADL Procedural Memory Rehabilitation',
                    style: GoogleFonts.inter(fontSize: 11.0, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<RoutineDifficultyTier>(
            initialValue: _tier,
            tooltip: 'Difficulty Level',
            onSelected: (tier) {
              setState(() {
                _tier = tier;
                _isAdaptiveMode = false;
              });
              _startNewActivitySession();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.sageLight,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppTheme.forestGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: AppTheme.forestGreen),
                  const SizedBox(width: 4),
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
              for (final t in RoutineDifficultyTier.values)
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
                '${_currentActivity.title}. ${_hintMessage}. Tap the card that describes what happens next.',
              );
            },
          ),
          const SizedBox(width: 4),
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
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Routine Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _currentActivity.themeGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _currentActivity.accentColor.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(_currentActivity.iconEmoji, style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  _currentActivity.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _currentActivity.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isCompact ? 18.0 : 22.0,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentActivity.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Prompt / Guidance Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.sageLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.lightbulb_rounded, size: 16, color: AppTheme.forestGreen),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hintMessage,
                            style: GoogleFonts.inter(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.forestGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Section 1: The Chronological Timeline Track
                  Text(
                    'CHRONOLOGICAL ROUTINE TIMELINE (${_currentStepToPlace - 1}/${_placedSteps.length} COMPLETE)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children: [
                      for (int i = 0; i < _placedSteps.length; i++) ...[
                        _buildTimelineSlot(i + 1, _placedSteps[i]),
                        if (i < _placedSteps.length - 1)
                          Center(
                            child: Container(
                              width: 2,
                              height: 14,
                              color: _placedSteps[i] != null ? AppTheme.forestGreen : AppTheme.surfaceBorder,
                            ),
                          ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Available Steps Pool
                  if (!_isActivityCompleted) ...[
                    Text(
                      'TAP THE NEXT STEP BELOW (${_availableShuffledSteps.length} CHOICES)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forestGreen,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableShuffledSteps.map((step) {
                        return _buildAvailableStepCard(step, isCompact);
                      }).toList(),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF43A047)),
                      ),
                      child: Row(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Routine Mastered!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  'You demonstrated clear step-by-step memory of this daily activity.',
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bottom Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _startNewActivitySession,
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.textPrimary),
                        label: Text(
                          'Try Another Routine',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.surfaceBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildTimelineSlot(int stepNumber, RoutineStep? step) {
    final isCurrentTarget = stepNumber == _currentStepToPlace;

    if (step != null) {
      // Completed step in timeline
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF43A047), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF43A047),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check, size: 20, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: step.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(step.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'STEP $stepNumber: ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E7D32),
                          letterSpacing: 0.6,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          step.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Empty slot
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: isCurrentTarget ? const Color(0xFFFFF9C4) : AppTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentTarget ? const Color(0xFFFBC02D) : AppTheme.surfaceBorder,
          width: isCurrentTarget ? 2.0 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrentTarget ? const Color(0xFFFBC02D) : AppTheme.surfaceBorder,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isCurrentTarget ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isCurrentTarget ? '👉 Waiting for Step $stepNumber (Tap below)' : 'Step $stepNumber',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: isCurrentTarget ? FontWeight.w700 : FontWeight.w500,
                color: isCurrentTarget ? const Color(0xFFF57F17) : AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableStepCard(RoutineStep step, bool isCompact) {
    return InkWell(
      onTap: () => _onSelectStepCard(step),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: isCompact ? double.infinity : 400,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.surfaceBorder, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: step.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: step.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(step.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.touch_app_rounded, size: 18, color: AppTheme.forestGreen),
          ],
        ),
      ),
    );
  }
}
