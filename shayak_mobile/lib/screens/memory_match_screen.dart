import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class MemoryMatchScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const MemoryMatchScreen({super.key, required this.onFinish});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  final List<String> _emojis = ['🍎', '🌸', '☕', '🌿', '📖', '🦚'];
  late List<_CardItem> _cards;
  int? _firstFlippedIndex;
  bool _isChecking = false;
  int _matchesFound = 0;
  int _moves = 0;
  late DateTime _gameStartTime;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final list = <_CardItem>[];
    for (var i = 0; i < _emojis.length; i++) {
      list.add(_CardItem(id: i * 2, emoji: _emojis[i]));
      list.add(_CardItem(id: i * 2 + 1, emoji: _emojis[i]));
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
        // Match!
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _cards[first].isMatched = true;
              _cards[second].isMatched = true;
              _matchesFound++;
              _firstFlippedIndex = null;
              _isChecking = false;
            });
            if (_matchesFound == _emojis.length) {
              _showCelebrationDialog();
            }
          }
        });
      } else {
        // No match
        Future.delayed(const Duration(milliseconds: 900), () {
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
              'Wonderful job!',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You found all pairs in $_moves gentle turns. A calm mind is a strong mind.',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _initGame();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('Play again'),
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
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🧠', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(
                              'Matches: $_matchesFound / ${_emojis.length}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          'Turns: $_moves',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cards Grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: _cards.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        final isRevealed = card.isFlipped || card.isMatched;

                        return InkWell(
                          onTap: () => _onCardTap(index),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: isRevealed
                                  ? (card.isMatched ? AppTheme.sageLight : Colors.white)
                                  : AppTheme.forestTealCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: card.isMatched
                                    ? AppTheme.statusGreen
                                    : (isRevealed ? AppTheme.surfaceBorder : AppTheme.forestTealDark),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isRevealed
                                  ? Text(
                                      card.emoji,
                                      style: const TextStyle(fontSize: 34),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppTheme.warmPeach,
                                      size: 26,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
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

class _CardItem {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  _CardItem({
    required this.id,
    required this.emoji,
  })  : isFlipped = false,
        isMatched = false;
}
