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

enum MemoryStoryTier { gentle, moderate, challenging, master }

extension MemoryStoryTierExtension on MemoryStoryTier {
  String get label {
    switch (this) {
      case MemoryStoryTier.gentle:      return 'Level 1 (Gentle \u2014 2 Questions)';
      case MemoryStoryTier.moderate:    return 'Level 2 (Moderate \u2014 3 Questions)';
      case MemoryStoryTier.challenging: return 'Level 3 (Challenging \u2014 4 Questions)';
      case MemoryStoryTier.master:      return 'Level 4 (Master \u2014 5 Questions)';
    }
  }
  String get shortTitle {
    switch (this) {
      case MemoryStoryTier.gentle:      return 'Gentle';
      case MemoryStoryTier.moderate:    return 'Moderate';
      case MemoryStoryTier.challenging: return 'Challenging';
      case MemoryStoryTier.master:      return 'Master';
    }
  }
  int get questionCount {
    switch (this) {
      case MemoryStoryTier.gentle:      return 2;
      case MemoryStoryTier.moderate:    return 3;
      case MemoryStoryTier.challenging: return 4;
      case MemoryStoryTier.master:      return 5;
    }
  }
  int get readSeconds {
    switch (this) {
      case MemoryStoryTier.gentle:      return 35;
      case MemoryStoryTier.moderate:    return 28;
      case MemoryStoryTier.challenging: return 22;
      case MemoryStoryTier.master:      return 16;
    }
  }
  Color get color {
    switch (this) {
      case MemoryStoryTier.gentle:      return const Color(0xFF22C55E);
      case MemoryStoryTier.moderate:    return const Color(0xFF3B82F6);
      case MemoryStoryTier.challenging: return const Color(0xFFF97316);
      case MemoryStoryTier.master:      return const Color(0xFF8B5CF6);
    }
  }
}

class _StoryQuestion {
  final String question;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  const _StoryQuestion({required this.question, required this.choices, required this.correctIndex, required this.explanation});
}

class _StoryItem {
  final String id, title, emoji, storyText, theme;
  final List<_StoryQuestion> questions;
  final Color cardColor;
  const _StoryItem({required this.id, required this.title, required this.emoji, required this.storyText, required this.questions, required this.cardColor, required this.theme});
}

final List<_StoryItem> _storyLibrary = [
  _StoryItem(
    id: 'market_day', title: 'A Day at the Market', emoji: '\ud83d\udecd\ufe0f',
    theme: 'Community & Daily Life', cardColor: const Color(0xFFFFF7ED),
    storyText: 'Today, Meena woke up early in the morning. She put on her blue saree and went to the nearby market. At the market, she bought fresh vegetables \u2014 tomatoes, spinach, and potatoes. She also bought a bunch of yellow marigold flowers for the prayer room. The friendly vegetable seller gave her a small discount. Meena returned home before noon and cooked a warm dal for lunch. After lunch, she sat on the veranda and listened to old film songs on the radio.',
    questions: [
      _StoryQuestion(question: 'Where did Meena go in the morning?', choices: ['To the temple', 'To the market', 'To the school', 'To the river'], correctIndex: 1, explanation: 'Yes! Meena went to the nearby market. \ud83d\udecd\ufe0f'),
      _StoryQuestion(question: 'What colour saree did Meena wear?', choices: ['Red', 'Green', 'Blue', 'Yellow'], correctIndex: 2, explanation: 'Exactly right! She wore her blue saree. \ud83d\udc99'),
      _StoryQuestion(question: 'What vegetables did Meena buy?', choices: ['Onion and garlic', 'Tomatoes, spinach, and potatoes', 'Carrots and beans', 'Bitter gourd'], correctIndex: 1, explanation: 'Well remembered! Tomatoes, spinach, and potatoes. \ud83e\udd66'),
      _StoryQuestion(question: 'What flowers did Meena buy?', choices: ['Red roses', 'White jasmine', 'Yellow marigolds', 'Pink lotus'], correctIndex: 2, explanation: 'Perfect! Yellow marigold flowers for the prayer room! \ud83c\udf3c'),
      _StoryQuestion(question: 'What did Meena do after lunch?', choices: ['She napped', 'She watched TV', 'She listened to old film songs on the radio', 'She visited a neighbour'], correctIndex: 2, explanation: 'Great memory! She sat on the veranda listening to old songs. \ud83c\udfb5'),
    ],
  ),
  _StoryItem(
    id: 'monsoon_evening', title: 'The Monsoon Evening', emoji: '\ud83c\udf27\ufe0f',
    theme: 'Nature & Seasons', cardColor: const Color(0xFFEFF6FF),
    storyText: 'It was a beautiful monsoon evening. Rajan sat on the wooden chair near the window and watched the rain fall. His grandson Arjun brought him a cup of hot ginger tea and two biscuits. Rajan could smell the wet earth \u2014 a scent he loved since childhood. A small sparrow sat on the window ledge and chirped before flying away. Rajan remembered how he used to dance in the rain as a young boy in his village. He smiled and told Arjun stories about the monsoon festivals of his childhood.',
    questions: [
      _StoryQuestion(question: 'Where was Rajan sitting?', choices: ['On the bed', 'In the garden', 'On a wooden chair near the window', 'On the veranda steps'], correctIndex: 2, explanation: 'Well done! Rajan was on his wooden chair near the window. \ud83e\ude91'),
      _StoryQuestion(question: 'Who brought Rajan his tea?', choices: ['His daughter', 'His wife', 'His grandson Arjun', 'His neighbour'], correctIndex: 2, explanation: 'Correct! His grandson Arjun brought the tea. \u2615'),
      _StoryQuestion(question: 'What smell did Rajan love?', choices: ['Fresh flowers', 'Cooking food', 'Wet earth after rain', 'Incense from the temple'], correctIndex: 2, explanation: 'Yes! The wet earth after rain \u2014 a beloved childhood smell. \ud83c\udf3f'),
      _StoryQuestion(question: 'What bird sat on the window ledge?', choices: ['A crow', 'A sparrow', 'A pigeon', 'A parrot'], correctIndex: 1, explanation: 'Excellent! A small sparrow visited the window. \ud83d\udc26'),
      _StoryQuestion(question: 'What did Rajan tell Arjun about?', choices: ['His school days', 'Monsoon festivals from his childhood', 'His favourite foods', 'How to cook dal'], correctIndex: 1, explanation: 'Great! Rajan shared stories of monsoon festivals from his childhood. \ud83c\udf89'),
    ],
  ),
  _StoryItem(
    id: 'radio_programme', title: 'The Old Radio Programme', emoji: '\ud83d\udcfb',
    theme: 'Music & Nostalgia', cardColor: const Color(0xFFFDF4FF),
    storyText: 'Savitri had kept her old transistor radio on the wooden shelf for thirty years. Every Sunday morning, she tuned it to the classical music programme that played from 8 to 10 o\'clock. Today the radio played a bhajan by Lata Mangeshkar \u2014 her all-time favourite. She closed her eyes and gently moved her head to the rhythm. Her son came downstairs and sat beside her, listening quietly. Savitri said, "This song was played at your father\'s wedding." Her son smiled and held her hand.',
    questions: [
      _StoryQuestion(question: 'Where did Savitri keep her radio?', choices: ['On the kitchen counter', 'On the wooden shelf', 'By the window', 'Under the bed'], correctIndex: 1, explanation: 'Correct! Her beloved old radio sat on the wooden shelf. \ud83d\udcfb'),
      _StoryQuestion(question: 'On which day did she listen to the music programme?', choices: ['Saturday', 'Monday', 'Sunday', 'Friday'], correctIndex: 2, explanation: 'Right! Every Sunday morning was the music programme. \ud83c\udfb5'),
      _StoryQuestion(question: 'Whose bhajan was playing?', choices: ['Asha Bhosle', 'Lata Mangeshkar', 'Kishore Kumar', 'Mohammed Rafi'], correctIndex: 1, explanation: 'Yes! A bhajan by Lata Mangeshkar \u2014 her favourite. \ud83c\udfa4'),
      _StoryQuestion(question: 'What did Savitri do while listening?', choices: ['She sang loudly', 'She closed her eyes and moved her head to the rhythm', 'She fell asleep', 'She danced'], correctIndex: 1, explanation: 'Beautiful! She closed her eyes and enjoyed the rhythm. \u2728'),
      _StoryQuestion(question: 'What did Savitri say about the song?', choices: ['Her grandmother loved it', 'It was played at your father\'s wedding', 'She learnt it in school', 'It reminded her of monsoon'], correctIndex: 1, explanation: 'Perfect recall! The song was from her husband\'s wedding. \ud83d\udc8d'),
    ],
  ),
  _StoryItem(
    id: 'kitchen_garden', title: 'The Little Kitchen Garden', emoji: '\ud83c\udf31',
    theme: 'Home & Nature', cardColor: const Color(0xFFF0FDF4),
    storyText: 'Every morning, Kamala watered the small kitchen garden behind her house. She had planted tomatoes, chillies, coriander leaves, and a lemon tree. Her favourite plant was the tulsi (holy basil) that stood near the door. Today she noticed a beautiful green caterpillar on one of the chilli plants. Kamala carefully moved it to a leaf without harming it. Her neighbour Shanta came over and praised her garden. Together they had tea and shared homemade pickle.',
    questions: [
      _StoryQuestion(question: 'What did Kamala do every morning?', choices: ['Swept the courtyard', 'Watered her kitchen garden', 'Cooked breakfast', 'Went for a walk'], correctIndex: 1, explanation: 'Correct! Every morning Kamala watered her garden. \ud83c\udf3f'),
      _StoryQuestion(question: 'Which was Kamala\'s favourite plant?', choices: ['The lemon tree', 'The chilli plant', 'Tulsi (holy basil)', 'Coriander'], correctIndex: 2, explanation: 'Perfect! Her beloved tulsi plant near the door. \ud83c\udf3f'),
      _StoryQuestion(question: 'What did Kamala find on the chilli plant?', choices: ['A butterfly', 'A green caterpillar', 'A ladybug', 'A spider'], correctIndex: 1, explanation: 'Wonderful! A little green caterpillar \u2014 moved gently. \ud83d\udc1b'),
      _StoryQuestion(question: 'Who came to visit Kamala?', choices: ['Her daughter', 'Her sister', 'Her neighbour Shanta', 'Her grandson'], correctIndex: 2, explanation: 'Yes! Her neighbour Shanta came to see the garden. \ud83e\udd1d'),
      _StoryQuestion(question: 'What did Kamala and Shanta share?', choices: ['Sweets and fruit', 'Tea and homemade pickle', 'Rice and curry', 'A music programme'], correctIndex: 1, explanation: 'Exactly right! They had tea together and shared homemade pickle. \u2615'),
    ],
  ),
];

enum _StoryPhase { reading, questioning, result }

class MemoryStoryScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  const MemoryStoryScreen({super.key, this.onFinish});

  @override
  State<MemoryStoryScreen> createState() => _MemoryStoryScreenState();
}

class _MemoryStoryScreenState extends State<MemoryStoryScreen> with TickerProviderStateMixin {
  MemoryStoryTier _tier = MemoryStoryTier.gentle;
  bool _isAdaptiveMode = true;
  int _gamesCompleted = 0;
  int _totalCorrect = 0;
  int _totalQuestions = 0;
  final List<double> _responseTimes = [];
  double _avgResponseMs = 0;

  _StoryPhase _phase = _StoryPhase.reading;
  late _StoryItem _currentStory;
  late List<_StoryQuestion> _activeQuestions;
  int _questionIndex = 0;
  int? _selectedChoice;
  bool _answered = false;
  int _roundCorrect = 0;

  Timer? _readTimer;
  int _readCountdown = 35;
  late AnimationController _timerAnim;
  late AnimationController _fadeAnim;
  late AnimationController _slideAnim;
  DateTime? _questionStartTime;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _timerAnim = AnimationController(vsync: this, duration: Duration(seconds: _tier.readSeconds));
    _fadeAnim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _startNewRound();
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _timerAnim.dispose();
    _fadeAnim.dispose();
    _slideAnim.dispose();
    super.dispose();
  }

  void _startNewRound() {
    final stories = List<_StoryItem>.from(_storyLibrary)..shuffle(_rng);
    _currentStory = stories.first;
    final allQ = List<_StoryQuestion>.from(_currentStory.questions)..shuffle(_rng);
    _activeQuestions = allQ.take(_tier.questionCount).toList();
    _questionIndex = 0;
    _roundCorrect = 0;
    _selectedChoice = null;
    _answered = false;
    _readCountdown = _tier.readSeconds;
    _phase = _StoryPhase.reading;
    _timerAnim.duration = Duration(seconds: _tier.readSeconds);
    _timerAnim.forward(from: 0);
    _fadeAnim.forward(from: 0);
    _readTimer?.cancel();
    _readTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _readCountdown--);
      if (_readCountdown <= 0) { t.cancel(); _startQuestioning(); }
    });
  }

  void _startQuestioning() {
    _readTimer?.cancel();
    _timerAnim.stop();
    setState(() { _phase = _StoryPhase.questioning; _questionIndex = 0; _selectedChoice = null; _answered = false; });
    _slideAnim.forward(from: 0);
    _questionStartTime = DateTime.now();
  }

  void _selectChoice(int idx) {
    if (_answered) return;
    final elapsed = DateTime.now().difference(_questionStartTime!).inMilliseconds.toDouble();
    _responseTimes.add(elapsed);
    _avgResponseMs = _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
    final isCorrect = idx == _activeQuestions[_questionIndex].correctIndex;
    if (isCorrect) _roundCorrect++;
    _totalQuestions++;
    if (isCorrect) _totalCorrect++;
    setState(() { _selectedChoice = idx; _answered = true; });
    Future.delayed(const Duration(milliseconds: 1800), () { if (mounted) _nextQuestion(); });
  }

  void _nextQuestion() {
    if (_questionIndex + 1 >= _activeQuestions.length) {
      _finishRound();
    } else {
      setState(() { _questionIndex++; _selectedChoice = null; _answered = false; });
      _slideAnim.forward(from: 0);
      _questionStartTime = DateTime.now();
    }
  }

  Future<void> _finishRound() async {
    _gamesCompleted++;
    if (_isAdaptiveMode) {
      final acc = _roundCorrect / _activeQuestions.length;
      if (acc >= 0.85 && _tier.index < MemoryStoryTier.values.length - 1) {
        _tier = MemoryStoryTier.values[_tier.index + 1];
      } else if (acc < 0.5 && _tier.index > 0) {
        _tier = MemoryStoryTier.values[_tier.index - 1];
      }
    }
    setState(() => _phase = _StoryPhase.result);
    await _submitSession();
  }

  Future<void> _submitSession() async {
    final accuracy = _totalQuestions > 0 ? (_totalCorrect / _totalQuestions).clamp(0.0, 1.0) : 0.0;
    final responseTimeSec = _avgResponseMs > 0 ? _avgResponseMs / 1000.0 : 3.0;
    // Save to Hive via GameSession object
    final session = GameSession(
      sessionId: SessionService.generateId('PT-9042', 'memory_story'),
      patientId: 'PT-9042',
      gameType: 'memory_story',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: responseTimeSec,
      totalMoves: _totalQuestions,
      extras: {
        'difficulty_tier': _tier.shortTitle,
        'games_completed': _gamesCompleted,
        'story': _currentStory.title,
      },
    );
    SessionService.instance.saveSession(session);
    // Also sync to backend
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/patient/PT-9042/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'game_type': 'memory_story',
          'difficulty_tier': _tier.shortTitle,
          'games_completed': _gamesCompleted,
          'accuracy_percent': (accuracy * 100).toStringAsFixed(1),
          'avg_response_time_ms': _avgResponseMs.toStringAsFixed(0),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: _buildAppBar(),
      body: SafeArea(child: Column(children: [
        _buildProgressBar(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: _buildBody())),
        )),
      ])),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0, centerTitle: false,
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: widget.onFinish ?? () => Navigator.pop(context)),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('\ud83d\udcd6 Memory Story', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        Text(_tier.label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
      actions: [
        Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _tier.color.withOpacity(0.12), borderRadius: BorderRadius.circular(100)),
          child: Text(_tier.shortTitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: _tier.color)),
        ))),
      ],
    );
  }

  Widget _buildProgressBar() {
    final accuracy = _totalQuestions > 0 ? (_totalCorrect / _totalQuestions * 100) : 0.0;
    final avgSec = _avgResponseMs > 0 ? (_avgResponseMs / 1000).toStringAsFixed(1) : '\u2014';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _metricChip('\ud83d\udcd6', 'Stories', '$_gamesCompleted done', const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          _metricChip('\ud83c\udfaf', 'Accuracy', '${accuracy.toStringAsFixed(0)}%', const Color(0xFFF0FDF4), const Color(0xFF22C55E)),
          const SizedBox(width: 10),
          _metricChip('\u26a1', 'Avg Speed', '${avgSec}s', const Color(0xFFFFF7ED), const Color(0xFFF97316)),
          const SizedBox(width: 10),
          _metricChip('\ud83c\udfc6', 'Difficulty', _tier.shortTitle, _tier.color.withOpacity(0.1), _tier.color),
        ])),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(
          value: _totalQuestions > 0 ? (_totalCorrect / _totalQuestions).clamp(0.0, 1.0) : 0.0,
          minHeight: 6, backgroundColor: AppTheme.sageLight, color: _tier.color,
        )),
        const SizedBox(height: 12),
        Row(children: MemoryStoryTier.values.map((t) {
          final sel = t == _tier;
          return Expanded(child: GestureDetector(
            onTap: () { if (_phase != _StoryPhase.questioning) { setState(() { _tier = t; _isAdaptiveMode = false; }); } },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(color: sel ? t.color : Colors.transparent, borderRadius: BorderRadius.circular(100), border: Border.all(color: sel ? t.color : AppTheme.surfaceBorder)),
              child: Text(t.shortTitle, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.textSecondary)),
            ),
          ));
        }).toList()),
      ]),
    );
  }

  Widget _metricChip(String emoji, String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _StoryPhase.reading:     return _buildReadingPhase();
      case _StoryPhase.questioning: return _buildQuestionPhase();
      case _StoryPhase.result:      return _buildResultPhase();
    }
  }

  Widget _buildReadingPhase() {
    return FadeTransition(opacity: _fadeAnim, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _currentStory.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.surfaceBorder)),
        child: Row(children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Center(child: Text(_currentStory.emoji, style: const TextStyle(fontSize: 30)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(100)),
              child: Text(_currentStory.theme.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.8))),
            const SizedBox(height: 6),
            Text(_currentStory.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          ])),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Icon(Icons.timer_outlined, size: 16, color: _readCountdown <= 5 ? Colors.red : AppTheme.forestGreen),
        const SizedBox(width: 8),
        Text('Read carefully \u2014 $_readCountdown seconds remaining', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _readCountdown <= 5 ? Colors.red : AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 4),
      AnimatedBuilder(animation: _timerAnim, builder: (context, _) => ClipRRect(borderRadius: BorderRadius.circular(100), child: LinearProgressIndicator(value: 1 - _timerAnim.value, minHeight: 5, backgroundColor: AppTheme.sageLight, color: _readCountdown <= 5 ? Colors.red : AppTheme.forestGreen))),
      const SizedBox(height: 18),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.surfaceBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_stories_rounded, size: 18, color: AppTheme.forestGreen),
            const SizedBox(width: 8),
            Text('Story', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.forestGreen)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppTheme.textSecondary), onPressed: () => AudioNarrationService.instance.speak(_currentStory.storyText), tooltip: 'Listen to story', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(_currentStory.storyText, style: GoogleFonts.lora(fontSize: 16.5, height: 1.8, color: AppTheme.textPrimary, fontWeight: FontWeight.w400)),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _tier.color.withOpacity(0.07), borderRadius: BorderRadius.circular(16), border: Border.all(color: _tier.color.withOpacity(0.2))),
        child: Row(children: [
          Icon(Icons.quiz_rounded, size: 20, color: _tier.color),
          const SizedBox(width: 12),
          Expanded(child: Text('Get ready! ${_tier.questionCount} questions about this story are coming up.', style: GoogleFonts.inter(fontSize: 13, color: _tier.color, fontWeight: FontWeight.w600))),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _startQuestioning,
        style: ElevatedButton.styleFrom(backgroundColor: _tier.color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), elevation: 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("I'm ready \u2014 Start Questions!", style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ]),
      )),
    ]));
  }

  Widget _buildQuestionPhase() {
    final q = _activeQuestions[_questionIndex];
    final answered = _answered;
    final selected = _selectedChoice;
    final correct = q.correctIndex;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(CurvedAnimation(parent: _slideAnim, curve: Curves.easeOut)),
      child: FadeTransition(opacity: _slideAnim, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(_activeQuestions.length, (i) {
          Color c = i < _questionIndex ? const Color(0xFF22C55E) : i == _questionIndex ? _tier.color : AppTheme.sageLight;
          return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 6, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(100))));
        })),
        const SizedBox(height: 6),
        Text('Question ${_questionIndex + 1} of ${_activeQuestions.length}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.surfaceBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(100)),
              child: Text('RECALL QUESTION', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.forestGreen, letterSpacing: 0.8))),
            const SizedBox(height: 14),
            Text(q.question, style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.3)),
          ]),
        ),
        const SizedBox(height: 16),
        ...List.generate(q.choices.length, (i) {
          final isSelected = selected == i;
          final isCorrect = i == correct;
          Color borderColor = AppTheme.surfaceBorder;
          Color bgColor = Colors.white;
          Widget? trailing;
          if (answered) {
            if (isCorrect) { borderColor = const Color(0xFF22C55E); bgColor = const Color(0xFFF0FDF4); trailing = const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 22); }
            else if (isSelected) { borderColor = const Color(0xFFF97316); bgColor = const Color(0xFFFFF7ED); trailing = const Icon(Icons.highlight_off_rounded, color: Color(0xFFF97316), size: 22); }
          } else if (isSelected) { borderColor = _tier.color; bgColor = _tier.color.withOpacity(0.06); }
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(
            onTap: () => _selectChoice(i),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 1.8)),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: answered && isCorrect ? const Color(0xFF22C55E) : answered && isSelected && !isCorrect ? const Color(0xFFF97316) : AppTheme.background, shape: BoxShape.circle),
                  child: Center(child: Text(String.fromCharCode(65 + i), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: answered && (isCorrect || (isSelected && !isCorrect)) ? Colors.white : AppTheme.textSecondary)))),
                const SizedBox(width: 14),
                Expanded(child: Text(q.choices[i], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                if (trailing != null) trailing,
              ]),
            ),
          ));
        }),
        if (answered) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF86EFAC))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('\u2728', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(q.explanation, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF166534), fontWeight: FontWeight.w600, height: 1.4))),
            ])),
        ],
        const SizedBox(height: 24),
      ])),
    );
  }

  Widget _buildResultPhase() {
    final pct = _activeQuestions.isNotEmpty ? (_roundCorrect / _activeQuestions.length * 100).round() : 0;
    final isExcellent = pct >= 80;
    return Column(children: [
      const SizedBox(height: 16),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isExcellent ? [const Color(0xFF166534), const Color(0xFF15803D)] : [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(children: [
          Text(isExcellent ? '\ud83c\udf1f' : '\ud83d\udc99', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(isExcellent ? 'Wonderful Memory!' : 'Great Effort!', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          Text(isExcellent ? 'You remembered the story beautifully!' : 'Every story helps your memory grow stronger.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.4)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _resultStat('$_roundCorrect/${_activeQuestions.length}', 'Correct'),
            _resultStat('$pct%', 'Score'),
            _resultStat(_tier.shortTitle, 'Level'),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.surfaceBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Session Progress', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _sessionStatCol('\ud83d\udcd6', 'Stories\nDone', '$_gamesCompleted')),
            Expanded(child: _sessionStatCol('\ud83c\udfaf', 'Total\nAccuracy', '${_totalQuestions > 0 ? (_totalCorrect / _totalQuestions * 100).toStringAsFixed(0) : 0}%')),
            Expanded(child: _sessionStatCol('\u26a1', 'Avg Speed', '${_avgResponseMs > 0 ? (_avgResponseMs / 1000).toStringAsFixed(1) : "\u2014"}s')),
            Expanded(child: _sessionStatCol('\ud83c\udfc6', 'Difficulty', _tier.shortTitle)),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: widget.onFinish ?? () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.surfaceBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
          child: Text('Finish', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        )),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _startNewRound,
          style: ElevatedButton.styleFrom(backgroundColor: _tier.color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), elevation: 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Next Story', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 16),
          ]),
        )),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _resultStat(String value, String label) => Column(children: [
    Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
    const SizedBox(height: 2),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
  ]);

  Widget _sessionStatCol(String emoji, String label, String value) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    const SizedBox(height: 4),
    Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9.5, color: AppTheme.textSecondary, height: 1.3)),
    const SizedBox(height: 2),
    Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
  ]);
}
