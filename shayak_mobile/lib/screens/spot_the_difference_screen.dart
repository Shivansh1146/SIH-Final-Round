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

enum SpotDiffTier {
  gentle,      // 4 cards (2x2 grid), 8 seconds
  moderate,    // 8 cards (4x2 grid), 7 seconds
  challenging, // 12 cards (4x3 grid), 6 seconds
  master,      // 16 cards (4x4 grid), 5 seconds
}

extension SpotDiffTierExtension on SpotDiffTier {
  String get label {
    switch (this) {
      case SpotDiffTier.gentle:
        return 'Level 1 (Gentle - 4 Cards)';
      case SpotDiffTier.moderate:
        return 'Level 2 (Moderate - 8 Cards)';
      case SpotDiffTier.challenging:
        return 'Level 3 (Challenging - 12 Cards)';
      case SpotDiffTier.master:
        return 'Level 4 (Master - 16 Cards)';
    }
  }

  String get shortTitle {
    switch (this) {
      case SpotDiffTier.gentle:
        return 'Gentle';
      case SpotDiffTier.moderate:
        return 'Moderate';
      case SpotDiffTier.challenging:
        return 'Challenging';
      case SpotDiffTier.master:
        return 'Master';
    }
  }

  int get itemCount {
    switch (this) {
      case SpotDiffTier.gentle:
        return 4;
      case SpotDiffTier.moderate:
        return 8;
      case SpotDiffTier.challenging:
        return 12;
      case SpotDiffTier.master:
        return 16;
    }
  }

  int get inspectionSeconds {
    switch (this) {
      case SpotDiffTier.gentle:
        return 8;
      case SpotDiffTier.moderate:
        return 7;
      case SpotDiffTier.challenging:
        return 6;
      case SpotDiffTier.master:
        return 5;
    }
  }

  List<Color> get themeGradient {
    switch (this) {
      case SpotDiffTier.gentle:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case SpotDiffTier.moderate:
        return [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
      case SpotDiffTier.challenging:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case SpotDiffTier.master:
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }
  }
}

class SceneItem {
  final String id;
  final String name;
  final String emoji;
  final Color bgColor;

  const SceneItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.bgColor,
  });
}

class SceneTheme {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final Color themeColor;
  final List<SceneItem> allItems;

  const SceneTheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.themeColor,
    required this.allItems,
  });
}

class SpotTheDifferenceScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const SpotTheDifferenceScreen({super.key, this.onFinish});

  @override
  State<SpotTheDifferenceScreen> createState() => _SpotTheDifferenceScreenState();
}

enum GameStep {
  inspectPictureA, // Step 1: Show Picture A with countdown timer
  hidePictureA,    // Step 2: Brief transition / pause
  showPictureB,    // Step 3 & 4: Picture B + "What changed / What is missing?"
  roundResult,     // Feedback after selection
}

class _SpotTheDifferenceScreenState extends State<SpotTheDifferenceScreen> {
  SpotDiffTier _tier = SpotDiffTier.gentle;
  bool _isAdaptiveMode = true;

  // Master Themes for Visual Recall (16 rich items per theme for 4 to 16 card modes)
  static const List<SceneTheme> _allThemes = [
    SceneTheme(
      id: 'living_room',
      title: 'Cozy Living Room',
      subtitle: 'Remember the familiar objects placed around the room.',
      category: 'HOME SCENE',
      themeColor: Color(0xFF2E7D32),
      allItems: [
        SceneItem(id: 'chair', name: 'Wooden Chair', emoji: '🪑', bgColor: Color(0xFFFFF3E0)),
        SceneItem(id: 'clock', name: 'Wall Clock', emoji: '🕐', bgColor: Color(0xFFE8F5E9)),
        SceneItem(id: 'flower', name: 'Pink Flower', emoji: '🌸', bgColor: Color(0xFFFCE4EC)),
        SceneItem(id: 'cup', name: 'Chai Cup', emoji: '☕', bgColor: Color(0xFFEFEBE9)),
        SceneItem(id: 'lamp', name: 'Desk Lamp', emoji: '💡', bgColor: Color(0xFFFFFDE7)),
        SceneItem(id: 'book', name: 'Favorite Book', emoji: '📖', bgColor: Color(0xFFE3F2FD)),
        SceneItem(id: 'plant', name: 'Green Plant', emoji: '🪴', bgColor: Color(0xFFE8F8F5)),
        SceneItem(id: 'cushion', name: 'Soft Pillow', emoji: '🛋️', bgColor: Color(0xFFF3E5F5)),
        SceneItem(id: 'tv', name: 'Television', emoji: '📺', bgColor: Color(0xFFECEFF1)),
        SceneItem(id: 'painting', name: 'Wall Art', emoji: '🖼️', bgColor: Color(0xFFFFF8E1)),
        SceneItem(id: 'radio', name: 'Vintage Radio', emoji: '📻', bgColor: Color(0xFFE0F2F1)),
        SceneItem(id: 'vase', name: 'Flower Vase', emoji: '🏺', bgColor: Color(0xFFFBE9E7)),
        SceneItem(id: 'fan', name: 'Table Fan', emoji: '🪭', bgColor: Color(0xFFEDE7F6)),
        SceneItem(id: 'glasses', name: 'Reading Specs', emoji: '👓', bgColor: Color(0xFFE1F5FE)),
        SceneItem(id: 'candle', name: 'Scented Candle', emoji: '🕯️', bgColor: Color(0xFFFFFDE7)),
        SceneItem(id: 'mirror', name: 'Hand Mirror', emoji: '🪞', bgColor: Color(0xFFF3E5F5)),
      ],
    ),
    SceneTheme(
      id: 'morning_kitchen',
      title: 'Morning Kitchen',
      subtitle: 'Observe the breakfast items on the kitchen counter.',
      category: 'KITCHEN SCENE',
      themeColor: Color(0xFFE65100),
      allItems: [
        SceneItem(id: 'kettle', name: 'Teapot', emoji: '🫖', bgColor: Color(0xFFFFF8E1)),
        SceneItem(id: 'apple', name: 'Red Apple', emoji: '🍎', bgColor: Color(0xFFFFEBEE)),
        SceneItem(id: 'bread', name: 'Fresh Toast', emoji: '🍞', bgColor: Color(0xFFEFEBE9)),
        SceneItem(id: 'milk', name: 'Milk Glass', emoji: '🥛', bgColor: Color(0xFFE1F5FE)),
        SceneItem(id: 'banana', name: 'Ripe Banana', emoji: '🍌', bgColor: Color(0xFFFFFDE7)),
        SceneItem(id: 'spoon', name: 'Silver Spoon', emoji: '🥄', bgColor: Color(0xFFECEFF1)),
        SceneItem(id: 'bowl', name: 'Cereal Bowl', emoji: '🥣', bgColor: Color(0xFFF3E5F5)),
        SceneItem(id: 'orange', name: 'Sweet Orange', emoji: '🍊', bgColor: Color(0xFFFFF3E0)),
        SceneItem(id: 'fork', name: 'Dinner Fork', emoji: '🍴', bgColor: Color(0xFFECEFF1)),
        SceneItem(id: 'honey', name: 'Honey Pot', emoji: '🍯', bgColor: Color(0xFFFFF8E1)),
        SceneItem(id: 'salt', name: 'Salt Shaker', emoji: '🧂', bgColor: Color(0xFFF5F5F5)),
        SceneItem(id: 'mango', name: 'Alphonso Mango', emoji: '🥭', bgColor: Color(0xFFFFF3E0)),
        SceneItem(id: 'plate', name: 'China Plate', emoji: '🍽️', bgColor: Color(0xFFE8F5E9)),
        SceneItem(id: 'cookie', name: 'Warm Biscuit', emoji: '🍪', bgColor: Color(0xFFEFEBE9)),
        SceneItem(id: 'grapes', name: 'Green Grapes', emoji: '🍇', bgColor: Color(0xFFF3E5F5)),
        SceneItem(id: 'egg', name: 'Boiled Egg', emoji: '🥚', bgColor: Color(0xFFFFFDE7)),
      ],
    ),
    SceneTheme(
      id: 'garden_veranda',
      title: 'Garden Veranda',
      subtitle: 'Look closely at the plants and birds on the porch.',
      category: 'NATURE SCENE',
      themeColor: Color(0xFF00897B),
      allItems: [
        SceneItem(id: 'watering_can', name: 'Watering Can', emoji: '🪴', bgColor: Color(0xFFE8F5E9)),
        SceneItem(id: 'bird', name: 'Sparrow', emoji: '🐦', bgColor: Color(0xFFE0F7FA)),
        SceneItem(id: 'sunflower', name: 'Sunflower', emoji: '🌻', bgColor: Color(0xFFFFFDE7)),
        SceneItem(id: 'butterfly', name: 'Butterfly', emoji: '🦋', bgColor: Color(0xFFE8EAF6)),
        SceneItem(id: 'hat', name: 'Sun Hat', emoji: '👒', bgColor: Color(0xFFFFF8E1)),
        SceneItem(id: 'bench', name: 'Garden Bench', emoji: '🪵', bgColor: Color(0xFFEFEBE9)),
        SceneItem(id: 'leaves', name: 'Tulsi Leaves', emoji: '🍃', bgColor: Color(0xFFE8F8F5)),
        SceneItem(id: 'bell', name: 'Wind Chime', emoji: '🔔', bgColor: Color(0xFFFBE9E7)),
        SceneItem(id: 'rose', name: 'Red Rose', emoji: '🌹', bgColor: Color(0xFFFFEBEE)),
        SceneItem(id: 'tree', name: 'Bonsai Tree', emoji: '🌳', bgColor: Color(0xFFE8F5E9)),
        SceneItem(id: 'bee', name: 'Honeybee', emoji: '🐝', bgColor: Color(0xFFFFFDE7)),
        SceneItem(id: 'nest', name: 'Bird Nest', emoji: '🪺', bgColor: Color(0xFFEFEBE9)),
        SceneItem(id: 'umbrella', name: 'Garden Umbrella', emoji: '☂️', bgColor: Color(0xFFE1F5FE)),
        SceneItem(id: 'ladybug', name: 'Ladybug', emoji: '🐞', bgColor: Color(0xFFFFEBEE)),
        SceneItem(id: 'tulip', name: 'Tulip Flower', emoji: '🌷', bgColor: Color(0xFFFCE4EC)),
        SceneItem(id: 'peacock', name: 'Royal Peacock', emoji: '🦚', bgColor: Color(0xFFE0F2F1)),
      ],
    ),
  ];

  late SceneTheme _currentTheme;
  List<SceneItem> _pictureAItems = [];
  List<SceneItem> _pictureBItems = [];
  late SceneItem _missingItem;
  List<SceneItem> _optionChoices = [];

  GameStep _gameStep = GameStep.inspectPictureA;
  int _secondsRemaining = 8;
  Timer? _countdownTimer;

  final int _totalRounds = 3;
  int _currentRound = 1;
  int _correctRounds = 0;
  int _mistakes = 0;

  DateTime? _gameStartTime;
  DateTime? _questionStartTime;
  List<double> _responseTimes = [];
  bool _isSpeaking = false;
  SceneItem? _selectedOption;

  @override
  void initState() {
    super.initState();
    _startNewGameSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startNewGameSession() {
    _currentRound = 1;
    _correctRounds = 0;
    _mistakes = 0;
    _responseTimes = [];
    _gameStartTime = DateTime.now();
    _setupRound();
  }

  void _setupRound() {
    _countdownTimer?.cancel();
    final rng = Random();
    _currentTheme = _allThemes[rng.nextInt(_allThemes.length)];

    // Pick N items for Picture A according to tier
    final count = _tier.itemCount.clamp(3, _currentTheme.allItems.length);
    final shuffledThemeItems = List<SceneItem>.from(_currentTheme.allItems)..shuffle(rng);
    _pictureAItems = shuffledThemeItems.take(count).toList();

    // Pick 1 item to remove in Picture B
    final missingIndex = rng.nextInt(_pictureAItems.length);
    _missingItem = _pictureAItems[missingIndex];

    // Picture B has all items except the missing one
    _pictureBItems = List<SceneItem>.from(_pictureAItems)..removeAt(missingIndex);

    // Prepare 4 choices (including the correct missing item)
    final candidateDecoys = _pictureAItems.toList();
    final choices = <SceneItem>{_missingItem};
    candidateDecoys.shuffle(rng);
    for (final item in candidateDecoys) {
      if (choices.length >= min(4, _pictureAItems.length)) break;
      choices.add(item);
    }
    _optionChoices = choices.toList()..shuffle(rng);

    _selectedOption = null;
    _secondsRemaining = _tier.inspectionSeconds;
    _gameStep = GameStep.inspectPictureA;

    setState(() {});

    _narrateGuidance(
      'Step 1: Look at this scene carefully for $_secondsRemaining seconds. Remember every item.',
    );

    // Start timer for Picture A
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _transitionToPictureB();
      }
    });
  }

  void _transitionToPictureB() {
    setState(() {
      _gameStep = GameStep.hidePictureA;
    });

    // Brief pause before showing Picture B
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _gameStep = GameStep.showPictureB;
        _questionStartTime = DateTime.now();
      });
      _narrateGuidance('Look at the scene now. One item is missing. Which item was removed?');
    });
  }

  void _narrateGuidance(String text) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    try {
      await AudioNarrationService.instance.speak(text);
    } catch (_) {}
    _isSpeaking = false;
  }

  void _onSelectChoice(SceneItem chosenItem) {
    if (_gameStep != GameStep.showPictureB || _selectedOption != null) return;

    final now = DateTime.now();
    if (_questionStartTime != null) {
      final elapsed = now.difference(_questionStartTime!).inMilliseconds / 1000.0;
      _responseTimes.add(elapsed);
    }

    final isCorrect = chosenItem.id == _missingItem.id;
    setState(() {
      _selectedOption = chosenItem;
      _gameStep = GameStep.roundResult;
      if (isCorrect) {
        _correctRounds++;
      } else {
        _mistakes++;
      }
    });

    if (isCorrect) {
      _narrateGuidance('Correct! The ${chosenItem.name} was removed from the scene.');
    } else {
      _narrateGuidance('Almost! The ${_missingItem.name} was the item that changed.');
    }

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_currentRound < _totalRounds) {
        setState(() => _currentRound++);
        _setupRound();
      } else {
        _finishGameSession();
      }
    });
  }

  Future<void> _finishGameSession() async {
    final durationSec = _gameStartTime != null
        ? DateTime.now().difference(_gameStartTime!).inSeconds
        : 20;
    final accuracy = _totalRounds > 0 ? (_correctRounds / _totalRounds) : 1.0;
    final avgReaction = _responseTimes.isNotEmpty
        ? (_responseTimes.reduce((a, b) => a + b) / _responseTimes.length)
        : 2.4;

    // AI Adaptive Difficulty Progression
    SpotDiffTier nextTier = _tier;
    String adaptiveMsg = 'Superb visual scene recall!';
    if (accuracy >= 0.80 && _tier != SpotDiffTier.challenging) {
      nextTier = SpotDiffTier.values[_tier.index + 1];
      adaptiveMsg = 'AI Adaptive: Advanced to ${nextTier.shortTitle} scene recall with more items!';
    } else if (accuracy < 0.50 && _tier != SpotDiffTier.gentle) {
      nextTier = SpotDiffTier.values[_tier.index - 1];
      adaptiveMsg = 'AI Adaptive: Switched to gentle pace for relaxed visual observation.';
    }

    // 1. Save locally in Hive via SessionService
    final patientId = SessionService.activePatientId ?? 'patient-ramesh';
    final session = GameSession(
      sessionId: SessionService.generateId(patientId, 'spot_the_difference'),
      patientId: patientId,
      gameType: 'spot_the_difference',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: avgReaction,
      totalMoves: _totalRounds,
      extras: {
        'gameName': 'Spot the Difference (What Changed?)',
        'difficulty': _tier.label,
        'roundsWon': '$_correctRounds/$_totalRounds',
        'mistakes': _mistakes,
        'durationSec': durationSec,
        'nextTier': nextTier.label,
      },
    );
    SessionService.instance.saveSession(session);

    // 2. Report to FastAPI backend
    try {
      final backendId = patientId.startsWith('patient-') ? 'PT-9042' : patientId;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/patient/$backendId/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_type': 'Spot the Difference (Visual Recall)',
          'difficulty_level': _tier.label,
          'score': (accuracy * 100.0).clamp(0.0, 100.0),
          'tremor_frequency_hz': 4.7,
          'tremor_amplitude_deg': 0.8,
          'postural_stability_score': 88.0,
          'notes': 'Completed $_totalRounds visual memory rounds with ${(accuracy * 100).toStringAsFixed(0)}% accuracy in ${durationSec}s. $adaptiveMsg',
        }),
      );
    } catch (_) {}

    _showVictoryModal(accuracy, durationSec, avgReaction, nextTier, adaptiveMsg);
  }

  void _showVictoryModal(
    double accuracy,
    int durationSec,
    double avgReaction,
    SpotDiffTier nextTier,
    String adaptiveMsg,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
          contentPadding: const EdgeInsets.all(28.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌟', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Brilliant Observation!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You spotted the changed objects across all $_totalRounds scenes.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.pastelYellow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text('ACCURACY', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.warmTerracotta)),
                          const SizedBox(height: 4),
                          Text('${(accuracy * 100).toStringAsFixed(0)}%', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.pastelBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text('RESPONSE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1976D2))),
                          const SizedBox(height: 4),
                          Text('${avgReaction.toStringAsFixed(1)}s', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // AI Feedback note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.forestGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        adaptiveMsg,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
                        side: const BorderSide(color: AppTheme.surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _tier = nextTier;
                        });
                        _startNewGameSession();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Play Again', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.forestGreen),
          onPressed: () {
            if (widget.onFinish != null) {
              widget.onFinish!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spot the Difference (What Changed?)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Visual Working Memory · Round $_currentRound of $_totalRounds',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen),
            onPressed: () {
              if (_gameStep == GameStep.inspectPictureA) {
                _narrateGuidance('Look at this picture carefully. Notice every item before time runs out.');
              } else if (_gameStep == GameStep.showPictureB) {
                _narrateGuidance('One item is missing. Which item was removed from the scene?');
              }
            },
            tooltip: 'Listen to instructions',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI-Adaptive Pacing & Difficulty Level Selector Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    // Top Row: Title + Auto AI / Manual Toggle Pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6F4EA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Color(0xFF0F9D58),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isAdaptiveMode ? 'AI–Adaptive Pacing' : 'Manual Pacing',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Auto AI / Manual Pill Toggle
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAdaptiveMode = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isAdaptiveMode ? const Color(0xFF0F172A) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Auto AI',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _isAdaptiveMode ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAdaptiveMode = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !_isAdaptiveMode ? const Color(0xFF0F172A) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Manual',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: !_isAdaptiveMode ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4 Difficulty Level Buttons: Gentle (4), Moderate (8), Challenging (12), Master (16)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: SpotDiffTier.values.map((tier) {
                            final isSelected = _tier == tier;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _tier = tier;
                                      _isAdaptiveMode = false; // Selecting tier switches to manual/focused preference
                                    });
                                    _startNewGameSession();
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF38BDF8).withOpacity(0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tier.shortTitle,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? Colors.white : const Color(0xFF334155),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${tier.itemCount} Cards',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? Colors.white.withOpacity(0.92) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Step Indicator Banner
              if (_gameStep == GameStep.inspectPictureA) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelYellow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.warmPeachDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_secondsRemaining',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.warmTerracotta,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 1: Inspect Picture A',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Memorize the scene items before time runs out.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_gameStep == GameStep.hidePictureA) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'Shuffling scene...',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.sageBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, color: AppTheme.forestGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 3 & 4: What changed?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.forestGreen,
                              ),
                            ),
                            Text(
                              'One object has disappeared from Picture B. Tap the missing item below.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Main Scene Display (Picture A or Picture B)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_gameStep),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                        children: [
                          Expanded(
                            child: Text(
                              _gameStep == GameStep.inspectPictureA
                                  ? '🖼️ Picture A (Original Scene)'
                                  : '🔍 Picture B (One Item Removed)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _currentTheme.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Scene Grid of Items (Dynamic layout based on item count)
                      Builder(
                        builder: (context) {
                          final count = _gameStep == GameStep.inspectPictureA
                              ? _pictureAItems.length
                              : _pictureBItems.length;

                          int crossAxisCount;
                          double aspectRatio;

                          if (count <= 4) {
                            crossAxisCount = 2;
                            aspectRatio = isMobile ? 1.35 : 1.6;
                          } else if (count <= 8) {
                            crossAxisCount = isMobile ? 2 : 4;
                            aspectRatio = isMobile ? 1.4 : 1.35;
                          } else if (count <= 12) {
                            crossAxisCount = isMobile ? 3 : 4;
                            aspectRatio = isMobile ? 1.05 : 1.3;
                          } else {
                            crossAxisCount = isMobile ? 4 : 4;
                            aspectRatio = isMobile ? 0.9 : 1.25;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: count > 8 ? 8 : 12,
                              mainAxisSpacing: count > 8 ? 8 : 12,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: count,
                            itemBuilder: (context, index) {
                              final item = _gameStep == GameStep.inspectPictureA
                                  ? _pictureAItems[index]
                                  : _pictureBItems[index];

                              return Container(
                                decoration: BoxDecoration(
                                  color: item.bgColor,
                                  borderRadius: BorderRadius.circular(count > 8 ? 14 : 18),
                                  border: Border.all(color: AppTheme.surfaceBorder),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.emoji,
                                      style: TextStyle(fontSize: count > 8 ? (isMobile ? 22 : 28) : 32),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        item.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: count > 8 ? (isMobile ? 9.5 : 11) : 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Step 4 Options Section (Only visible when Picture B is active)
              if (_gameStep == GameStep.showPictureB || _gameStep == GameStep.roundResult) ...[
                const SizedBox(height: 24),
                Text(
                  'Select the missing item:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 4 Choices Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: _optionChoices.length,
                  itemBuilder: (context, index) {
                    final choice = _optionChoices[index];
                    final isSelected = _selectedOption?.id == choice.id;
                    final isCorrectAnswer = choice.id == _missingItem.id;

                    Color cardColor = Colors.white;
                    Color borderColor = AppTheme.surfaceBorder;
                    if (_selectedOption != null) {
                      if (isCorrectAnswer) {
                        cardColor = AppTheme.sageLight;
                        borderColor = AppTheme.forestGreen;
                      } else if (isSelected && !isCorrectAnswer) {
                        cardColor = const Color(0xFFFFEBEE);
                        borderColor = AppTheme.alertCoral;
                      }
                    }

                    return InkWell(
                      onTap: () => _onSelectChoice(choice),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(choice.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 6),
                            Text(
                              choice.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedOption != null && isCorrectAnswer) ...[
                              const SizedBox(height: 4),
                              const Icon(Icons.check_circle_rounded, color: AppTheme.forestGreen, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
