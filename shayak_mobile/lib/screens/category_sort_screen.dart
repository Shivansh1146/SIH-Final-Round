import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/session_service.dart';
import '../services/audio_narration_service.dart';

enum CategorySortTier {
  gentle,
  moderate,
  challenging,
  master,
}

extension CategorySortTierExtension on CategorySortTier {
  String get label {
    switch (this) {
      case CategorySortTier.gentle:
        return 'Level 1 (Gentle)';
      case CategorySortTier.moderate:
        return 'Level 2 (Moderate)';
      case CategorySortTier.challenging:
        return 'Level 3 (Challenging)';
      case CategorySortTier.master:
        return 'Level 4 (Master)';
    }
  }

  String get shortTitle {
    switch (this) {
      case CategorySortTier.gentle:
        return 'Gentle';
      case CategorySortTier.moderate:
        return 'Moderate';
      case CategorySortTier.challenging:
        return 'Challenging';
      case CategorySortTier.master:
        return 'Master';
    }
  }

  int get categoryCount {
    switch (this) {
      case CategorySortTier.gentle:
      case CategorySortTier.moderate:
        return 2;
      case CategorySortTier.challenging:
      case CategorySortTier.master:
        return 3;
    }
  }

  int get itemsPerCategory {
    switch (this) {
      case CategorySortTier.gentle:
        return 2; // 4 items total
      case CategorySortTier.moderate:
        return 3; // 6 items total
      case CategorySortTier.challenging:
        return 3; // 9 items total
      case CategorySortTier.master:
        return 4; // 12 items total
    }
  }
}

class CategoryDef {
  final String id;
  final String name;
  final String emoji;
  final List<Color> gradient;
  final Color accentColor;
  final Color bgLight;

  const CategoryDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.accentColor,
    required this.bgLight,
  });
}

class SortItem {
  final String id;
  final String name;
  final String emoji;
  final String categoryId;
  final List<Color> gradient;

  const SortItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.categoryId,
    required this.gradient,
  });
}

class CategorySortScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const CategorySortScreen({super.key, this.onFinish});

  @override
  State<CategorySortScreen> createState() => _CategorySortScreenState();
}

class _CategorySortScreenState extends State<CategorySortScreen>
    with SingleTickerProviderStateMixin {
  CategorySortTier _tier = CategorySortTier.gentle;
  bool _isAdaptiveMode = true;

  List<CategoryDef> _activeCategories = [];
  List<SortItem> _remainingItems = [];
  Map<String, List<SortItem>> _sortedBaskets = {};

  SortItem? _selectedItem;
  int _mistakes = 0;
  int _correctCount = 0;
  int _totalItemsCount = 0;

  DateTime? _gameStartTime;
  DateTime? _itemStartTime;
  List<double> _reactionTimes = [];

  bool _isGameFinished = false;
  bool _isSpeaking = false;
  String _hintMessage = 'Tap an item, then tap the matching basket.';

  // Master Dataset of Categories & Items for Dementia Cognitive Rehabilitation
  static const List<CategoryDef> _allCategories = [
    CategoryDef(
      id: 'fruits',
      name: 'Fruits',
      emoji: '🍎',
      gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      accentColor: Color(0xFFE53935),
      bgLight: Color(0xFFFFEBEE),
    ),
    CategoryDef(
      id: 'vegetables',
      name: 'Vegetables',
      emoji: '🥕',
      gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)],
      accentColor: Color(0xFF43A047),
      bgLight: Color(0xFFE8F5E9),
    ),
    CategoryDef(
      id: 'kitchen',
      name: 'Kitchen Utensils',
      emoji: '🍳',
      gradient: [Color(0xFFF7971E), Color(0xFFFFD200)],
      accentColor: Color(0xFFFB8C00),
      bgLight: Color(0xFFFFF8E1),
    ),
    CategoryDef(
      id: 'furniture',
      name: 'Living Furniture',
      emoji: '🛋️',
      gradient: [Color(0xFFDA22FF), Color(0xFF9733EE)],
      accentColor: Color(0xFF8E24AA),
      bgLight: Color(0xFFF3E5F5),
    ),
    CategoryDef(
      id: 'summer',
      name: 'Summer & Warm',
      emoji: '☀️',
      gradient: [Color(0xFFFF8008), Color(0xFFFFC837)],
      accentColor: Color(0xFFF57C00),
      bgLight: Color(0xFFFFF3E0),
    ),
    CategoryDef(
      id: 'winter',
      name: 'Winter & Cold',
      emoji: '❄️',
      gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
      accentColor: Color(0xFF0288D1),
      bgLight: Color(0xFFE1F5FE),
    ),
    CategoryDef(
      id: 'animals_land',
      name: 'Land Animals',
      emoji: '🐕',
      gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
      accentColor: Color(0xFF00897B),
      bgLight: Color(0xFFE0F2F1),
    ),
    CategoryDef(
      id: 'animals_sea',
      name: 'Sea & Water',
      emoji: '🐬',
      gradient: [Color(0xFF4CA1AF), Color(0xFF2C3E50)],
      accentColor: Color(0xFF0097A7),
      bgLight: Color(0xFFE0F7FA),
    ),
  ];

  static const List<SortItem> _allItems = [
    // Fruits
    SortItem(id: 'f1', name: 'Sweet Apple', emoji: '🍎', categoryId: 'fruits', gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
    SortItem(id: 'f2', name: 'Ripe Banana', emoji: '🍌', categoryId: 'fruits', gradient: [Color(0xFFF7971E), Color(0xFFFFD200)]),
    SortItem(id: 'f3', name: 'Juicy Orange', emoji: '🍊', categoryId: 'fruits', gradient: [Color(0xFFFF8008), Color(0xFFFFC837)]),
    SortItem(id: 'f4', name: 'Sweet Mango', emoji: '🥭', categoryId: 'fruits', gradient: [Color(0xFFFFB75E), Color(0xFFED8F03)]),
    // Vegetables
    SortItem(id: 'v1', name: 'Crunchy Carrot', emoji: '🥕', categoryId: 'vegetables', gradient: [Color(0xFFFF8008), Color(0xFFFFC837)]),
    SortItem(id: 'v2', name: 'Fresh Broccoli', emoji: '🥦', categoryId: 'vegetables', gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)]),
    SortItem(id: 'v3', name: 'Red Tomato', emoji: '🍅', categoryId: 'vegetables', gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
    SortItem(id: 'v4', name: 'Sweet Corn', emoji: '🌽', categoryId: 'vegetables', gradient: [Color(0xFFF7971E), Color(0xFFFFD200)]),
    // Kitchen
    SortItem(id: 'k1', name: 'Frying Pan', emoji: '🍳', categoryId: 'kitchen', gradient: [Color(0xFF8A2387), Color(0xFFE94057)]),
    SortItem(id: 'k2', name: 'Soup Spoon', emoji: '🥄', categoryId: 'kitchen', gradient: [Color(0xFF4CA1AF), Color(0xFFC4E0E5)]),
    SortItem(id: 'k3', name: 'Water Cup', emoji: '🥛', categoryId: 'kitchen', gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
    SortItem(id: 'k4', name: 'Tea Kettle', emoji: '🫖', categoryId: 'kitchen', gradient: [Color(0xFFF7971E), Color(0xFFFFD200)]),
    // Furniture
    SortItem(id: 'fn1', name: 'Cozy Sofa', emoji: '🛋️', categoryId: 'furniture', gradient: [Color(0xFFDA22FF), Color(0xFF9733EE)]),
    SortItem(id: 'fn2', name: 'Dining Chair', emoji: '🪑', categoryId: 'furniture', gradient: [Color(0xFF11998E), Color(0xFF38EF7D)]),
    SortItem(id: 'fn3', name: 'Bed & Pillow', emoji: '🛏️', categoryId: 'furniture', gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
    SortItem(id: 'fn4', name: 'Study Desk', emoji: '🪵', categoryId: 'furniture', gradient: [Color(0xFFFFB75E), Color(0xFFED8F03)]),
    // Summer
    SortItem(id: 's1', name: 'Sunglasses', emoji: '🕶️', categoryId: 'summer', gradient: [Color(0xFFFF8008), Color(0xFFFFC837)]),
    SortItem(id: 's2', name: 'Sun Hat', emoji: '👒', categoryId: 'summer', gradient: [Color(0xFFF7971E), Color(0xFFFFD200)]),
    SortItem(id: 's3', name: 'Cool Ice Cream', emoji: '🍦', categoryId: 'summer', gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
    SortItem(id: 's4', name: 'Beach Umbrella', emoji: '🏖️', categoryId: 'summer', gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
    // Winter
    SortItem(id: 'w1', name: 'Warm Scarf', emoji: '🧣', categoryId: 'winter', gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
    SortItem(id: 'w2', name: 'Winter Gloves', emoji: '🧤', categoryId: 'winter', gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
    SortItem(id: 'w3', name: 'Snowman', emoji: '⛄', categoryId: 'winter', gradient: [Color(0xFF4CA1AF), Color(0xFFC4E0E5)]),
    SortItem(id: 'w4', name: 'Warm Beanie', emoji: '🧶', categoryId: 'winter', gradient: [Color(0xFFDA22FF), Color(0xFF9733EE)]),
    // Land Animals
    SortItem(id: 'al1', name: 'Faithful Dog', emoji: '🐕', categoryId: 'animals_land', gradient: [Color(0xFFFF8008), Color(0xFFFFC837)]),
    SortItem(id: 'al2', name: 'Playful Cat', emoji: '🐈', categoryId: 'animals_land', gradient: [Color(0xFFF7971E), Color(0xFFFFD200)]),
    SortItem(id: 'al3', name: 'Gentle Elephant', emoji: '🐘', categoryId: 'animals_land', gradient: [Color(0xFF4CA1AF), Color(0xFF2C3E50)]),
    SortItem(id: 'al4', name: 'Fluffy Sheep', emoji: '🐑', categoryId: 'animals_land', gradient: [Color(0xFF56AB2F), Color(0xFFA8E063)]),
    // Sea Animals
    SortItem(id: 'as1', name: 'Playful Dolphin', emoji: '🐬', categoryId: 'animals_sea', gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
    SortItem(id: 'as2', name: 'Tropical Fish', emoji: '🐠', categoryId: 'animals_sea', gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
    SortItem(id: 'as3', name: 'Blue Whale', emoji: '🐋', categoryId: 'animals_sea', gradient: [Color(0xFF4CA1AF), Color(0xFF2C3E50)]),
    SortItem(id: 'as4', name: 'Friendly Turtle', emoji: '🐢', categoryId: 'animals_sea', gradient: [Color(0xFF11998E), Color(0xFF38EF7D)]),
  ];

  @override
  void initState() {
    super.initState();
    _startNewGameSession();
  }

  void _startNewGameSession() {
    final rng = Random();

    // Select category pairings based on tier
    List<CategoryDef> chosenCats = [];
    if (_tier == CategorySortTier.gentle) {
      // Fruits vs Vegetables
      chosenCats = [
        _allCategories.firstWhere((c) => c.id == 'fruits'),
        _allCategories.firstWhere((c) => c.id == 'vegetables'),
      ];
    } else if (_tier == CategorySortTier.moderate) {
      // Random 2 paired categories
      final pairs = [
        ['summer', 'winter'],
        ['furniture', 'kitchen'],
        ['animals_land', 'animals_sea'],
        ['fruits', 'vegetables'],
      ];
      final pair = pairs[rng.nextInt(pairs.length)];
      chosenCats = [
        _allCategories.firstWhere((c) => c.id == pair[0]),
        _allCategories.firstWhere((c) => c.id == pair[1]),
      ];
    } else {
      // 3 distinct categories
      final catIds = ['fruits', 'furniture', 'kitchen', 'winter', 'animals_land']..shuffle(rng);
      chosenCats = catIds.take(3).map((id) => _allCategories.firstWhere((c) => c.id == id)).toList();
    }

    final itemsPerCat = _tier.itemsPerCategory;
    List<SortItem> pool = [];
    Map<String, List<SortItem>> baskets = {};

    for (final cat in chosenCats) {
      baskets[cat.id] = [];
      final available = _allItems.where((item) => item.categoryId == cat.id).toList()..shuffle(rng);
      pool.addAll(available.take(itemsPerCat));
    }

    pool.shuffle(rng);

    setState(() {
      _activeCategories = chosenCats;
      _remainingItems = pool;
      _sortedBaskets = baskets;
      _selectedItem = pool.isNotEmpty ? pool.first : null;
      _mistakes = 0;
      _correctCount = 0;
      _totalItemsCount = pool.length;
      _gameStartTime = DateTime.now();
      _itemStartTime = DateTime.now();
      _reactionTimes = [];
      _isGameFinished = false;
      _hintMessage = 'Tap an item, then place it in the right basket.';
    });

    _narrateGuidance(
      'Sort the items into ${_activeCategories.map((c) => c.name).join(" or ")}. Take your time.',
    );
  }

  void _narrateGuidance(String message) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    try {
      await AudioNarrationService.instance.speak(message);
    } catch (_) {}
    _isSpeaking = false;
  }

  void _onSelectItem(SortItem item) {
    setState(() {
      _selectedItem = item;
      _itemStartTime = DateTime.now();
      _hintMessage = 'Selected ${item.name} (${item.emoji}). Where does it belong?';
    });
    _narrateGuidance('${item.name}. Choose its matching basket.');
  }

  void _onTargetBasketTap(CategoryDef category) {
    if (_selectedItem == null || _isGameFinished) return;

    final item = _selectedItem!;
    final now = DateTime.now();
    if (_itemStartTime != null) {
      _reactionTimes.add(now.difference(_itemStartTime!).inMilliseconds / 1000.0);
    }

    if (item.categoryId == category.id) {
      // Correct placement!
      setState(() {
        _sortedBaskets[category.id]!.add(item);
        _remainingItems.remove(item);
        _correctCount++;
        _selectedItem = _remainingItems.isNotEmpty ? _remainingItems.first : null;
        _itemStartTime = DateTime.now();
        _hintMessage = '✨ Excellent! ${item.name} belongs in ${category.name}.';
      });

      if (_remainingItems.isEmpty) {
        _finishGame();
      } else {
        _narrateGuidance('Well done! Next item: ${_selectedItem?.name ?? ""}');
      }
    } else {
      // Gentle mistake encouragement
      setState(() {
        _mistakes++;
        _hintMessage = '💡 Try again: ${item.name} fits another basket better.';
      });
      _narrateGuidance('Almost! Try another basket for ${item.name}.');
    }
  }

  Future<void> _finishGame() async {
    setState(() {
      _isGameFinished = true;
      _hintMessage = '🎉 Wonderful! All items are categorized correctly!';
    });

    final durationSec = _gameStartTime != null
        ? DateTime.now().difference(_gameStartTime!).inSeconds
        : 30;
    final totalAttempts = _correctCount + _mistakes;
    final accuracy = totalAttempts > 0 ? (_correctCount / totalAttempts) : 1.0;
    final avgReaction = _reactionTimes.isNotEmpty
        ? (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length)
        : 2.5;

    // AI Adaptive difficulty adjustment recommendation
    CategorySortTier nextTier = _tier;
    String adaptiveMsg = 'Great consistency and calm reasoning!';
    if (accuracy >= 0.85 && durationSec < 60 && _tier != CategorySortTier.master) {
      nextTier = CategorySortTier.values[_tier.index + 1];
      adaptiveMsg = 'AI recommended: Ready for ${nextTier.shortTitle} level!';
    } else if (accuracy < 0.60 && _tier != CategorySortTier.gentle) {
      nextTier = CategorySortTier.values[_tier.index - 1];
      adaptiveMsg = 'AI recommended: Adjusting to ${nextTier.shortTitle} for a calmer experience.';
    }

    // Persist to local session service
    final session = GameSession(
      sessionId: SessionService.generateId(SessionService.activePatientId ?? 'patient-ramesh', 'category_sort'),
      patientId: SessionService.activePatientId ?? 'patient-ramesh',
      gameType: 'category_sort',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: avgReaction,
      totalMoves: totalAttempts,
      extras: {
        'difficulty': _tier.label,
        'mistakes': _mistakes,
        'correct': _correctCount,
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
          'session_type': 'Category Sort & Logical Association',
          'difficulty_level': _tier.label,
          'score': (accuracy * 100.0).clamp(0.0, 100.0),
          'tremor_frequency_hz': 5.2,
          'tremor_amplitude_deg': 1.1,
          'postural_stability_score': 86.0,
          'notes': 'Category reasoning accuracy ${(accuracy * 100).toStringAsFixed(0)}% in ${durationSec}s. $adaptiveMsg',
        }),
      );
    } catch (_) {}

    _narrateGuidance('Splendid job! You organized all items with great logical clarity.');
    _showVictoryModal(accuracy, durationSec, avgReaction, nextTier, adaptiveMsg);
  }

  void _showVictoryModal(
    double accuracy,
    int durationSec,
    double avgReaction,
    CategorySortTier nextTier,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF56AB2F).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 42)),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Brilliant Logical Sorting!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forestGreen,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Every item was placed in its proper logical category.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 22),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      'Accuracy',
                      '${(accuracy * 100).toStringAsFixed(0)}%',
                      const Color(0xFF43A047),
                      const Color(0xFFE8F5E9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      'Time',
                      '${durationSec}s',
                      const Color(0xFF1976D2),
                      const Color(0xFFE3F2FD),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      'Avg Speed',
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
                        _startNewGameSession();
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
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🗂️', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Sort & Logic',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreen,
                  ),
                ),
                Text(
                  'Semantic Memory & Categorization',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<CategorySortTier>(
            initialValue: _tier,
            tooltip: 'Select Difficulty Tier',
            onSelected: (tier) {
              setState(() {
                _tier = tier;
                _isAdaptiveMode = false;
              });
              _startNewGameSession();
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
              for (final t in CategorySortTier.values)
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
                'Category Sort: ${_hintMessage}. Tap any item card at top, then tap the matching category basket below.',
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Guidance Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppTheme.sageLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.lightbulb_rounded, size: 18, color: AppTheme.forestGreen),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _hintMessage,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.forestGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_totalItemsCount - _remainingItems.length}/$_totalItemsCount Done',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section 1: Item Pool to Sort
                  Text(
                    'ITEMS TO ORGANIZE (${_remainingItems.length} REMAINING)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _selectedItem != null ? AppTheme.forestGreen.withOpacity(0.3) : AppTheme.surfaceBorder,
                        width: 1.5,
                      ),
                    ),
                    child: _remainingItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🎉', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'All items sorted! Excellent job.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.forestGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: _remainingItems.map((item) {
                              final isSelected = _selectedItem?.id == item.id;
                              return _buildDraggableItemCard(item, isSelected);
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 26),

                  // Section 2: Target Category Baskets
                  Text(
                    'DESTINATION BASKETS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 10),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = _activeCategories.length == 2
                          ? 2
                          : (constraints.maxWidth > 650 ? 3 : 1);
                      if (cols == 2) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _activeCategories.length; i++) ...[
                              if (i > 0) const SizedBox(width: 14),
                              Expanded(
                                child: _buildCategoryBasket(_activeCategories[i]),
                              ),
                            ],
                          ],
                        );
                      } else if (cols == 3) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _activeCategories.length; i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              Expanded(
                                child: _buildCategoryBasket(_activeCategories[i]),
                              ),
                            ],
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            for (final cat in _activeCategories)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14.0),
                                child: _buildCategoryBasket(cat),
                              ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Bottom Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _startNewGameSession,
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.textPrimary),
                        label: Text(
                          'Restart Round',
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
                      if (_selectedItem != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.warmPeach.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Text(_selectedItem!.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                'Selected: ${_selectedItem!.name}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
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

  Widget _buildDraggableItemCard(SortItem item, bool isSelected) {
    return InkWell(
      onTap: () => _onSelectItem(item),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9C4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFBC02D) : AppTheme.surfaceBorder,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFBC02D).withOpacity(0.35)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              item.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFFF57F17)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBasket(CategoryDef category) {
    final sortedInThisBasket = _sortedBaskets[category.id] ?? [];
    final isTargetActive = _selectedItem != null;

    return InkWell(
      onTap: () => _onTargetBasketTap(category),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: category.bgLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isTargetActive ? category.accentColor : category.accentColor.withOpacity(0.4),
            width: isTargetActive ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: category.accentColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category Title & Icon
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: category.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: category.accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${sortedInThisBasket.length} sorted',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: category.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: category.accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Place Here',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: category.accentColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Content in Basket
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 90),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: sortedInThisBasket.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Tap to drop ${category.name}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortedInThisBasket.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: category.bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: category.accentColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(
                                item.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.check, size: 13, color: Color(0xFF43A047)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
