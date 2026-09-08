import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD
import '../services/session_service.dart';
=======
import 'package:http/http.dart' as http;
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
import '../theme/app_theme.dart';

enum GameDifficultyTier {
  gentle,
  moderate,
  challenging,
  master,
}

extension GameDifficultyTierExtension on GameDifficultyTier {
  String get label {
    switch (this) {
      case GameDifficultyTier.gentle:
        return 'Level 1 (Gentle)';
      case GameDifficultyTier.moderate:
        return 'Level 2 (Moderate)';
      case GameDifficultyTier.challenging:
        return 'Level 3 (Challenging)';
      case GameDifficultyTier.master:
        return 'Level 4 (Master)';
    }
  }

  String get shortTitle {
    switch (this) {
      case GameDifficultyTier.gentle:
        return 'Gentle';
      case GameDifficultyTier.moderate:
        return 'Moderate';
      case GameDifficultyTier.challenging:
        return 'Challenging';
      case GameDifficultyTier.master:
        return 'Master';
    }
  }

  int get pairCount {
    switch (this) {
      case GameDifficultyTier.gentle:
        return 2; // 4 cards (2x2)
      case GameDifficultyTier.moderate:
        return 4; // 8 cards (4x2 / 2x4)
      case GameDifficultyTier.challenging:
        return 6; // 12 cards (3x4)
      case GameDifficultyTier.master:
        return 8; // 16 cards (4x4)
    }
  }

  int get gridCrossAxisCount {
    switch (this) {
      case GameDifficultyTier.gentle:
        return 2;
      case GameDifficultyTier.moderate:
        return 4;
      case GameDifficultyTier.challenging:
        return 4;
      case GameDifficultyTier.master:
        return 4;
    }
  }

  List<String> get availableEmojis {
    const all = ['🍎', '🌸', '☕', '🌿', '📖', '🦚', '🎨', '🌟', '🕊️', '🍋'];
    return all.sublist(0, pairCount);
  }
}

class MemoryMatchScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const MemoryMatchScreen({super.key, required this.onFinish});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  GameDifficultyTier _currentTier = GameDifficultyTier.moderate;
  bool _isAdaptiveMode = true;

  late List<_CardItem> _cards;
  int? _firstFlippedIndex;
  bool _isChecking = false;
  int _matchesFound = 0;
  int _moves = 0;
  late DateTime _gameStartTime;

  DateTime? _gameStartTime;
  String? _lastAdaptationMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientDifficultyPreference();
    _initGame();
  }

  Future<void> _fetchPatientDifficultyPreference() async {
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/history'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final levelStr = data['current_difficulty_level'] as String?;
        final isAdaptive = data['is_adaptive_mode'] as bool? ?? true;

        if (mounted && levelStr != null) {
          setState(() {
            _isAdaptiveMode = isAdaptive;
            if (levelStr.contains('Gentle') || levelStr.contains('Level 1')) {
              _currentTier = GameDifficultyTier.gentle;
            } else if (levelStr.contains('Moderate') || levelStr.contains('Level 2')) {
              _currentTier = GameDifficultyTier.moderate;
            } else if (levelStr.contains('Challenging') || levelStr.contains('Level 3')) {
              _currentTier = GameDifficultyTier.challenging;
            } else if (levelStr.contains('Master') || levelStr.contains('Level 4')) {
              _currentTier = GameDifficultyTier.master;
            }
          });
          _initGame();
        }
      }
    } catch (_) {}
  }

  void _initGame() {
    final emojis = _currentTier.availableEmojis;
    final list = <_CardItem>[];
    for (var i = 0; i < emojis.length; i++) {
      list.add(_CardItem(id: i * 2, emoji: emojis[i]));
      list.add(_CardItem(id: i * 2 + 1, emoji: emojis[i]));
    }
    list.shuffle();
    setState(() {
      _cards = list;
      _firstFlippedIndex = null;
      _isChecking = false;
      _matchesFound = 0;
      _moves = 0;
      _gameStartTime = DateTime.now();
    });
  }

  void _onCardTap(int index) {
    if (_isChecking || _cards[index].isFlipped || _cards[index].isMatched) {
      return;
    }

    setState(() {
      _cards[index].isFlipped = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _moves++;
      _isChecking = true;
      final first = _firstFlippedIndex!;
      final second = index;

      if (_cards[first].emoji == _cards[second].emoji) {
        // Match found!
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            setState(() {
              _cards[first].isMatched = true;
              _cards[second].isMatched = true;
              _matchesFound++;
              _firstFlippedIndex = null;
              _isChecking = false;
            });
            if (_matchesFound == _currentTier.pairCount) {
              _recordSessionAndEvaluateAdaptation();
            }
          }
        });
      } else {
        // No match
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _cards[first].isFlipped = false;
              _cards[second].isFlipped = false;
              _firstFlippedIndex = null;
              _isChecking = false;
            });
          }
        });
      }
    }
  }

<<<<<<< HEAD
  void _saveSessionResult() {
    final patientId = SessionService.activePatientId ?? 'unknown';
    // Accuracy: matched pairs out of total pairs, penalised by wrong moves
    final totalPairs = _emojis.length;
    final wrongMoves = (_moves - totalPairs).clamp(0, 100);
    final accuracy = (totalPairs / (totalPairs + wrongMoves)).clamp(0.0, 1.0);
    // Response time: total elapsed / number of moves (floor at 0.5s)
    final elapsed =
        DateTime.now().difference(_gameStartTime).inMilliseconds / 1000.0;
    final responseSec = _moves > 0
        ? (elapsed / _moves).clamp(0.5, 30.0)
        : 3.0;
    SessionService.instance.saveSession(GameSession(
      sessionId: SessionService.generateId(patientId, 'memory_match'),
      patientId: patientId,
      gameType: 'memory_match',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: responseSec,
      totalMoves: _moves,
      extras: {
        'matchesFound': _matchesFound,
        'totalPairs': totalPairs,
        'elapsedSec': elapsed,
      },
    ));
  }

  void _showCelebrationDialog() {
    _saveSessionResult(); // ← persist result before showing dialog
=======
  void _recordSessionAndEvaluateAdaptation() {
    final durationSec = _gameStartTime != null
        ? DateTime.now().difference(_gameStartTime!).inSeconds
        : 60;

    // Calculate accuracy ratio and performance score
    final minTurns = _currentTier.pairCount;
    final accuracyRatio = (minTurns / (_moves > 0 ? _moves : minTurns)).clamp(0.2, 1.0);
    final score = (accuracyRatio * 100).roundToDouble();

    GameDifficultyTier nextTier = _currentTier;
    String adaptationNotice = 'Maintaining your comfortable pacing.';

    if (_isAdaptiveMode) {
      if (score >= 85.0) {
        if (_currentTier == GameDifficultyTier.gentle) {
          nextTier = GameDifficultyTier.moderate;
          adaptationNotice = '✨ Excellent recall! Auto-advanced to Level 2 (Moderate).';
        } else if (_currentTier == GameDifficultyTier.moderate) {
          nextTier = GameDifficultyTier.challenging;
          adaptationNotice = '🌟 Superb memory precision! Auto-advanced to Level 3 (Challenging).';
        } else if (_currentTier == GameDifficultyTier.challenging) {
          nextTier = GameDifficultyTier.master;
          adaptationNotice = '🏆 Peak performance! Auto-advanced to Level 4 (Master).';
        } else {
          adaptationNotice = '👑 Top Master Level achieved with stellar accuracy!';
        }
      } else if (score < 55.0) {
        if (_currentTier == GameDifficultyTier.master) {
          nextTier = GameDifficultyTier.challenging;
          adaptationNotice = '🛡️ AI adjusted to Level 3 to maintain a relaxed rhythm.';
        } else if (_currentTier == GameDifficultyTier.challenging) {
          nextTier = GameDifficultyTier.moderate;
          adaptationNotice = '🛡️ AI adjusted to Level 2 for comfortable practice.';
        } else if (_currentTier == GameDifficultyTier.moderate) {
          nextTier = GameDifficultyTier.gentle;
          adaptationNotice = '🛡️ AI adjusted to Gentle Level 1 to keep you confident.';
        }
      }
    } else {
      adaptationNotice = 'Manual difficulty locked on ${_currentTier.shortTitle}.';
    }

    _lastAdaptationMessage = adaptationNotice;

    // Broadcast session record to backend
    try {
      final sessionRecord = {
        'session_id': 'SES-${DateTime.now().millisecondsSinceEpoch}',
        'patient_id': 'PT-9042',
        'activity_type': 'memory_match',
        'score': score,
        'duration_seconds': durationSec,
        'difficulty_level': _currentTier.label,
        'is_adaptive': _isAdaptiveMode,
        'metrics': {
          'pairs_matched': _currentTier.pairCount.toDouble(),
          'total_turns': _moves.toDouble(),
          'accuracy_ratio': accuracyRatio,
          'tier_index': _currentTier.index.toDouble(),
        },
        'notes': 'Memory Match on ${_currentTier.label}. $adaptationNotice',
        'timestamp': DateTime.now().toIso8601String(),
      };

      http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionRecord),
      ).catchError((_) => http.Response('{}', 500));
    } catch (_) {}

    _showCelebrationDialog(score, durationSec, nextTier);
  }

  void _showCelebrationDialog(double score, int durationSec, GameDifficultyTier nextTier) {
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🌟', style: TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 16),
            Text(
<<<<<<< HEAD
              'Wonderful job!',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
=======
              'Wonderful job, Ramesh!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.forestGreen,
              ),
>>>>>>> 0ab6efe45811b2d47d4bed0741cb3eac4c87ca7c
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Completed ${_currentTier.pairCount} pairs in $_moves gentle turns ($durationSec seconds).',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Performance and Adaptive Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.sageLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.sageBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accuracy Score',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '${score.toInt()}%',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
                      ),
                    ],
                  ),
                  if (_lastAdaptationMessage != null) ...[
                    const Divider(height: 14),
                    Text(
                      _lastAdaptationMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.forestGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
                      setState(() {
                        _currentTier = nextTier;
                      });
                      _initGame();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Text(_isAdaptiveMode && nextTier != _currentTier ? 'Next Level' : 'Play again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onFinish();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onManualDifficultySelected(GameDifficultyTier tier) {
    setState(() {
      _currentTier = tier;
    });
    _initGame();

    // Sync preference with backend
    try {
      http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/patient/PT-9042/difficulty'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'difficulty_level': tier.label,
          'is_adaptive': _isAdaptiveMode,
          'caregiver_override': false,
        }),
      ).catchError((_) => http.Response('{}', 500));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.forestGreen),
          onPressed: widget.onFinish,
        ),
        title: Text(
          'Memory Match Activity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.forestGreen),
            tooltip: 'Restart',
            onPressed: _initGame,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  // 1. Difficulty & AI Adaptive Controller Header
                  _buildDifficultyHeader(),

                  const SizedBox(height: 12),

                  // 2. Info stats banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Turns', '$_moves'),
                        Container(width: 1, height: 24, color: AppTheme.surfaceBorder),
                        _buildStat('Matched', '$_matchesFound / ${_currentTier.pairCount}'),
                        Container(width: 1, height: 24, color: AppTheme.surfaceBorder),
                        _buildStat('Current Pace', _currentTier.shortTitle),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Grid of Cards
                  Expanded(
                    child: GridView.builder(
                      itemCount: _cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _currentTier.gridCrossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: _currentTier == GameDifficultyTier.gentle ? 1.0 : 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return _buildCardWidget(card, index);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
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
          // Row 1: Mode Switcher (Adaptive vs Manual)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isAdaptiveMode ? Icons.auto_awesome_rounded : Icons.tune_rounded,
                    size: 18,
                    color: _isAdaptiveMode ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAdaptiveMode ? 'AI-Adaptive Pacing' : 'Manual Difficulty',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              // Segmented Toggle
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
                        _onManualDifficultySelected(_currentTier);
                      },
                    ),
                    _buildModeButton(
                      label: 'Manual',
                      isActive: !_isAdaptiveMode,
                      onTap: () {
                        setState(() => _isAdaptiveMode = false);
                        _onManualDifficultySelected(_currentTier);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Difficulty Selector Chips
          Row(
            children: GameDifficultyTier.values.map((tier) {
              final isSelected = _currentTier == tier;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () => _onManualDifficultySelected(tier),
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
                              fontSize: 12.0,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${tier.pairCount * 2} Cards',
                            style: GoogleFonts.inter(
                              fontSize: 10.0,
                              color: isSelected ? Colors.white.withOpacity(0.85) : AppTheme.textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.forestGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCardWidget(_CardItem card, int index) {
    final showFace = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: showFace
              ? (card.isMatched ? AppTheme.sageLight : Colors.white)
              : AppTheme.sageLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: card.isMatched
                ? AppTheme.forestGreen
                : (showFace ? AppTheme.warmPeach : AppTheme.sageBorder),
            width: card.isMatched ? 2.0 : 1.5,
          ),
          boxShadow: showFace
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: showFace
                ? Text(
                    card.emoji,
                    key: ValueKey('face_${card.id}'),
                    style: TextStyle(
                      fontSize: _currentTier == GameDifficultyTier.gentle ? 48.0 : 34.0,
                    ),
                  )
                : Text(
                    '🌿',
                    key: ValueKey('back_${card.id}'),
                    style: TextStyle(
                      fontSize: _currentTier == GameDifficultyTier.gentle ? 36.0 : 26.0,
                      color: AppTheme.forestGreen.withOpacity(0.6),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CardItem {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  _CardItem({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
