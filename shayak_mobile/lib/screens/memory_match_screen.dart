import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/session_service.dart';
import '../services/api_config.dart';

enum GameDifficultyTier {
  gentle,
  moderate,
  challenging,
  master,
}

class _CardThemeInfo {
  final String emoji;
  final String title;
  final List<Color> gradient;
  final Color badgeColor;
  final Color shadowColor;

  const _CardThemeInfo({
    required this.emoji,
    required this.title,
    required this.gradient,
    required this.badgeColor,
    required this.shadowColor,
  });
}

final Map<String, _CardThemeInfo> _kCardThemes = {
  '🍎': const _CardThemeInfo(
    emoji: '🍎',
    title: 'Apple',
    gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    badgeColor: Color(0xFFFFEBEE),
    shadowColor: Color(0x66FF416C),
  ),
  '🌺': const _CardThemeInfo(
    emoji: '🌺',
    title: 'Flower',
    gradient: [Color(0xFFDA22FF), Color(0xFF9733EE)],
    badgeColor: Color(0xFFF3E5F5),
    shadowColor: Color(0x66DA22FF),
  ),
  '☕': const _CardThemeInfo(
    emoji: '☕',
    title: 'Coffee',
    gradient: [Color(0xFFF7971E), Color(0xFFFFD200)],
    badgeColor: Color(0xFFFFF8E1),
    shadowColor: Color(0x66F7971E),
  ),
  '📖': const _CardThemeInfo(
    emoji: '📖',
    title: 'Story',
    gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
    badgeColor: Color(0xFFE1F5FE),
    shadowColor: Color(0x6600C6FF),
  ),
  '🦚': const _CardThemeInfo(
    emoji: '🦚',
    title: 'Peacock',
    gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
    badgeColor: Color(0xFFE8F8F5),
    shadowColor: Color(0x6611998E),
  ),
  '🔔': const _CardThemeInfo(
    emoji: '🔔',
    title: 'Bell',
    gradient: [Color(0xFFFF8008), Color(0xFFFFC837)],
    badgeColor: Color(0xFFFFF3E0),
    shadowColor: Color(0x66FF8008),
  ),
  '🎨': const _CardThemeInfo(
    emoji: '🎨',
    title: 'Art',
    gradient: [Color(0xFF8A2387), Color(0xFFE94057)],
    badgeColor: Color(0xFFFCE4EC),
    shadowColor: Color(0x66E94057),
  ),
  '🌟': const _CardThemeInfo(
    emoji: '🌟',
    title: 'Star',
    gradient: [Color(0xFFFFB75E), Color(0xFFED8F03)],
    badgeColor: Color(0xFFFFFDE7),
    shadowColor: Color(0x66FFB75E),
  ),
  '🕊️': const _CardThemeInfo(
    emoji: '🕊️',
    title: 'Dove',
    gradient: [Color(0xFF4CA1AF), Color(0xFFC4E0E5)],
    badgeColor: Color(0xFFE0F7FA),
    shadowColor: Color(0x664CA1AF),
  ),
  '🍋': const _CardThemeInfo(
    emoji: '🍋',
    title: 'Lemon',
    gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)],
    badgeColor: Color(0xFFF1F8E9),
    shadowColor: Color(0x6656AB2F),
  ),
};

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

  List<Color> get themeGradient {
    switch (this) {
      case GameDifficultyTier.gentle:
        return const [Color(0xFF00B09B), Color(0xFF96C93D)];
      case GameDifficultyTier.moderate:
        return const [Color(0xFF2193B0), Color(0xFF6DD5ED)];
      case GameDifficultyTier.challenging:
        return const [Color(0xFF8E2DE2), Color(0xFF4A00E0)];
      case GameDifficultyTier.master:
        return const [Color(0xFFFF416C), Color(0xFFFF4B2B)];
    }
  }

  int get pairCount {
    switch (this) {
      case GameDifficultyTier.gentle:
        return 2; // 4 cards (2x2)
      case GameDifficultyTier.moderate:
        return 4; // 8 cards (4x2)
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
    const all = ['🍎', '🌺', '☕', '📖', '🦚', '🔔', '🎨', '🌟', '🕊️', '🍋'];
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
  GameDifficultyTier _currentTier = GameDifficultyTier.gentle;
  bool _isAdaptiveMode = true;

  late List<_CardItem> _cards;
  int? _firstFlippedIndex;
  bool _isChecking = false;
  int _matchesFound = 0;
  int _moves = 0;
  DateTime? _gameStartTime;
  String? _lastAdaptationMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientDifficultyPreference();
    _initGame();
  }

  Future<void> _fetchPatientDifficultyPreference() async {
    final patientId = SessionService.activePatientId ?? 'PT-9042';
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/patient/$patientId/history'));
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
        Future.delayed(const Duration(milliseconds: 300), () {
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
        Future.delayed(const Duration(milliseconds: 750), () {
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

  void _recordSessionAndEvaluateAdaptation() {
    final durationSec = _gameStartTime != null
        ? DateTime.now().difference(_gameStartTime!).inSeconds
        : 60;

    final patientId = SessionService.activePatientId ?? 'PT-9042';
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

    // Save to local SessionService
    final responseTimeSec = durationSec > 0 ? durationSec / (_moves > 0 ? _moves : 1) : 3.0;
    SessionService.instance.saveSession(GameSession(
      sessionId: SessionService.generateId(patientId, 'memory_match'),
      patientId: patientId,
      gameType: 'memory_match',
      playedAt: DateTime.now(),
      accuracyRatio: accuracyRatio,
      responseTimeSec: responseTimeSec.toDouble(),
      totalMoves: _moves,
      extras: {
        'pairsMatched': _currentTier.pairCount,
        'difficultyLevel': _currentTier.label,
        'isAdaptive': _isAdaptiveMode,
      },
    ));

    // Broadcast session record to backend
    try {
      final backendId = patientId.startsWith('patient-') ? 'PT-9042' : patientId;
      final sessionRecord = {
        'session_id': 'SES-${DateTime.now().millisecondsSinceEpoch}',
        'patient_id': backendId,
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
        Uri.parse('${ApiConfig.baseUrl}/api/v1/patient/$backendId/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionRecord),
      ).catchError((_) => http.Response('{}', 500));
    } catch (_) {}

    _showCelebrationDialog(score, durationSec, nextTier);
  }

  void _showCelebrationDialog(double score, int durationSec, GameDifficultyTier nextTier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
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
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(child: Text('🏆', style: TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 18),
              Text(
                'Spectacular Match!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Solved ${_currentTier.pairCount} pairs in $_moves turns ($durationSec seconds).',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Performance and Adaptive Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _currentTier.themeGradient[0].withOpacity(0.12),
                      _currentTier.themeGradient[1].withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _currentTier.themeGradient[0].withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Accuracy Score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentTier.themeGradient[0],
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${score.toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_lastAdaptationMessage != null) ...[
                      const Divider(height: 16),
                      Text(
                        _lastAdaptationMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
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
                        side: BorderSide(color: _currentTier.themeGradient[0], width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        _isAdaptiveMode && nextTier != _currentTier ? 'Next Level 🚀' : 'Play Again 🔄',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: _currentTier.themeGradient[0],
                        ),
                      ),
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
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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

  void _onManualDifficultySelected(GameDifficultyTier tier) {
    setState(() {
      _currentTier = tier;
    });
    _initGame();

    final patientId = SessionService.activePatientId ?? 'PT-9042';
    try {
      http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/patient/$patientId/difficulty'),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: widget.onFinish,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _currentTier.themeGradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.extension_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Memory Match Activity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Restart Game',
            onPressed: _initGame,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  _buildDifficultyHeader(),
                  const SizedBox(height: 8),
                  _buildColorfulStatsBar(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxis = _currentTier.gridCrossAxisCount;
                        final rowCount = (_cards.length / crossAxis).ceil();
                        const spacing = 10.0;

                        final availableHeight = constraints.maxHeight - (rowCount - 1) * spacing;
                        final availableWidth = constraints.maxWidth - (crossAxis - 1) * spacing;

                        final cardWidth = availableWidth / crossAxis;
                        final cardHeight = availableHeight / (rowCount > 0 ? rowCount : 1);

                        // Exact aspect ratio guarantees every single tile fits 100% inside the screen
                        final exactAspectRatio = cardWidth / (cardHeight > 0 ? cardHeight : cardWidth);

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cards.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxis,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: exactAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            return _buildCardWidget(card, index, cardHeight);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorfulStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatPill(
            label: 'Turns',
            value: '$_moves',
            icon: Icons.touch_app_rounded,
            gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
          _buildStatPill(
            label: 'Matched',
            value: '$_matchesFound / ${_currentTier.pairCount}',
            icon: Icons.stars_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
          _buildStatPill(
            label: 'Pace Tier',
            value: _currentTier.shortTitle,
            icon: Icons.bolt_rounded,
            gradient: _currentTier.themeGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.0,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isAdaptiveMode ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAdaptiveMode ? Icons.auto_awesome_rounded : Icons.tune_rounded,
                      size: 15,
                      color: _isAdaptiveMode ? const Color(0xFF10B981) : const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isAdaptiveMode ? 'AI-Adaptive Pacing' : 'Manual Pacing',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(100),
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
          const SizedBox(height: 8),
          Row(
            children: GameDifficultyTier.values.map((tier) {
              final isSelected = _currentTier == tier;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    onTap: () => _onManualDifficultySelected(tier),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(colors: tier.themeGradient) : null,
                        color: isSelected ? null : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1),
                          width: isSelected ? 0 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: tier.themeGradient[0].withOpacity(0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tier.shortTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${tier.pairCount * 2} Cards',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCardWidget(_CardItem card, int index, double cardHeight) {
    final showFace = card.isFlipped || card.isMatched;
    final theme = _kCardThemes[card.emoji] ??
        const _CardThemeInfo(
          emoji: '⭐',
          title: 'Star',
          gradient: [Color(0xFFFF9966), Color(0xFFFF5E62)],
          badgeColor: Color(0xFFFFF3E0),
          shadowColor: Color(0x66FF5E62),
        );

    final emojiSize = (cardHeight * 0.38).clamp(24.0, 56.0);
    final iconSize = (cardHeight * 0.28).clamp(20.0, 40.0);

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.0),
          gradient: showFace
              ? LinearGradient(
                  colors: theme.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: card.isMatched
                ? const Color(0xFFFFD700)
                : (showFace ? Colors.white.withOpacity(0.85) : const Color(0xFF475569)),
            width: card.isMatched ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: showFace ? theme.shadowColor : Colors.black.withOpacity(0.12),
              blurRadius: showFace ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.0),
          child: Stack(
            children: [
              // Background playful decorative shapes
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(showFace ? 0.15 : 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(showFace ? 0.10 : 0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Card Content (Face vs Back)
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: showFace
                      ? Column(
                          key: ValueKey('face_${card.id}'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                card.emoji,
                                style: TextStyle(fontSize: emojiSize),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                card.isMatched ? 'MATCH! ⭐' : theme.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w800,
                                  color: card.isMatched ? const Color(0xFFFFD700) : Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: ValueKey('back_${card.id}'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: iconSize * 1.6,
                              height: iconSize * 1.6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.star_rounded,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TAP ME',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
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
