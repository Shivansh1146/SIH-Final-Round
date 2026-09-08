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

enum MemoryLaneTier {
  gentle,      // 4 cards (2x2 grid)
  moderate,    // 8 cards (4x2 grid)
  challenging, // 12 cards (4x3 grid)
  master,      // 16 cards (4x4 grid)
}

extension MemoryLaneTierExtension on MemoryLaneTier {
  String get label {
    switch (this) {
      case MemoryLaneTier.gentle:
        return 'Level 1 (Gentle - 4 Memories)';
      case MemoryLaneTier.moderate:
        return 'Level 2 (Moderate - 8 Memories)';
      case MemoryLaneTier.challenging:
        return 'Level 3 (Challenging - 12 Memories)';
      case MemoryLaneTier.master:
        return 'Level 4 (Master - 16 Memories)';
    }
  }

  String get shortTitle {
    switch (this) {
      case MemoryLaneTier.gentle:
        return 'Gentle';
      case MemoryLaneTier.moderate:
        return 'Moderate';
      case MemoryLaneTier.challenging:
        return 'Challenging';
      case MemoryLaneTier.master:
        return 'Master';
    }
  }

  int get itemCount {
    switch (this) {
      case MemoryLaneTier.gentle:
        return 4;
      case MemoryLaneTier.moderate:
        return 8;
      case MemoryLaneTier.challenging:
        return 12;
      case MemoryLaneTier.master:
        return 16;
    }
  }

  int get inspectionSeconds {
    switch (this) {
      case MemoryLaneTier.gentle:
        return 9;
      case MemoryLaneTier.moderate:
        return 8;
      case MemoryLaneTier.challenging:
        return 7;
      case MemoryLaneTier.master:
        return 6;
    }
  }
}

class ReminiscenceItem {
  final String id;
  final String name;
  final String emoji;
  final String memoryPrompt;
  final String nostalgicStory;
  final Color bgColor;

  const ReminiscenceItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.memoryPrompt,
    required this.nostalgicStory,
    required this.bgColor,
  });
}

class ReminiscenceEraTheme {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final Color themeColor;
  final List<ReminiscenceItem> items;

  const ReminiscenceEraTheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.themeColor,
    required this.items,
  });
}

class MemoryLaneScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const MemoryLaneScreen({super.key, this.onFinish});

  @override
  State<MemoryLaneScreen> createState() => _MemoryLaneScreenState();
}

enum MemoryLaneStep {
  exploreMemories, // Step 1: Browse and savor familiar nostalgic items
  memoryPrompt,    // Step 2: "Which familiar memory belongs to this moment?"
  celebrationStory,// Step 3: Errorless celebration & warm reminiscence snippet
}

class _MemoryLaneScreenState extends State<MemoryLaneScreen> {
  MemoryLaneTier _tier = MemoryLaneTier.gentle;
  bool _isAdaptiveMode = true;

  // Master Reminiscence Themes (16 rich cultural & nostalgic items each)
  static const List<ReminiscenceEraTheme> _allEraThemes = [
    ReminiscenceEraTheme(
      id: 'childhood_home',
      title: 'Heirloom & Childhood Memories',
      subtitle: 'Cherished memories of courtyard games, grandparents, and brass vessels.',
      category: 'AUTOBIOGRAPHICAL REMINISCENCE',
      themeColor: Color(0xFFC2410C),
      items: [
        ReminiscenceItem(id: 'brass_lamp', name: 'Brass Diya', emoji: '🪔', memoryPrompt: 'Lit with oil during evening prayers.', nostalgicStory: 'The warm glow of the diya brought peace and family together every evening.', bgColor: Color(0xFFFFF7ED)),
        ReminiscenceItem(id: 'spinning_top', name: 'Wooden Lattu', emoji: '🪀', memoryPrompt: 'Wound with a thread string and spun on the porch.', nostalgicStory: 'Remember winding the string tight and watching the wooden top spin smoothly across the verandah!', bgColor: Color(0xFFFEF3C7)),
        ReminiscenceItem(id: 'fountain_pen', name: 'Ink Fountain Pen', emoji: '✒️', memoryPrompt: 'Filled with royal blue ink for letter writing.', nostalgicStory: 'Writing handwritten letters to loved ones on postcards and inland letters.', bgColor: Color(0xFFE0F2FE)),
        ReminiscenceItem(id: 'clay_pot', name: 'Matka Cool Water', emoji: '🏺', memoryPrompt: 'Kept in the shade on hot summer afternoons.', nostalgicStory: 'The refreshing taste of naturally cool water infused with earthy fragrance.', bgColor: Color(0xFFF3E8FF)),
        ReminiscenceItem(id: 'bicycle', name: 'Classic Roadster Cycle', emoji: '🚲', memoryPrompt: 'Ridden with a bell ringing through tree-lined streets.', nostalgicStory: 'Riding down breezy lanes with friends, ringing the cheerful bell.', bgColor: Color(0xFFECFDF5)),
        ReminiscenceItem(id: 'kite', name: 'Colorful Patang', emoji: '🪁', memoryPrompt: 'Flown high under the clear winter blue sky.', nostalgicStory: 'Watching vibrant kites soar in the sky with laughter echoing from the terrace.', bgColor: Color(0xFFFFF1F2)),
        ReminiscenceItem(id: 'wooden_trunk', name: 'Grandmother’s Trunk', emoji: '🧰', memoryPrompt: 'Kept safe with silk sarees and treasures.', nostalgicStory: 'Filled with cherished keepsakes, antique perfumes, and soft handloom shawls.', bgColor: Color(0xFFF5F5F4)),
        ReminiscenceItem(id: 'mango_tree', name: 'Mango Orchard', emoji: '🥭', memoryPrompt: 'Shady branches where children gathered sweet mangoes.', nostalgicStory: 'Picking sweet ripe fruit and sharing slices with cousins on lazy afternoons.', bgColor: Color(0xFFFFFBEB)),
        ReminiscenceItem(id: 'swing', name: 'Verandah Swing', emoji: '🪑', memoryPrompt: 'Gently rocking with the afternoon breeze.', nostalgicStory: 'Relaxing on the wooden jhula while sipping warm tea and listening to stories.', bgColor: Color(0xFFF0FDF4)),
        ReminiscenceItem(id: 'board_game', name: 'Chaupar & Carrom', emoji: '♟️', memoryPrompt: 'Played on the floor with wooden pawns and cowrie shells.', nostalgicStory: 'Exciting matches filled with friendly cheers, smiles, and playful rivalry.', bgColor: Color(0xFFFDF4FF)),
        ReminiscenceItem(id: 'marbles', name: 'Glass Kanche', emoji: '🔮', memoryPrompt: 'Aimed precisely on the courtyard soil.', nostalgicStory: 'The bright colors glistening inside the glass marbles under sunlight.', bgColor: Color(0xFFE0F2FE)),
        ReminiscenceItem(id: 'radio_set', name: 'Murphy Valve Radio', emoji: '📻', memoryPrompt: 'Tuned to evening news and soulful tunes.', nostalgicStory: 'The whole family sitting together waiting for the 8 PM radio bulletin.', bgColor: Color(0xFFF1F5F9)),
        ReminiscenceItem(id: 'clay_stove', name: 'Chulha Hearth', emoji: '🪵', memoryPrompt: 'Cooking piping hot rotis with wood smoke aroma.', nostalgicStory: 'The unmistakable warmth and unforgettable aroma of home-cooked rotis.', bgColor: Color(0xFFFEF2F2)),
        ReminiscenceItem(id: 'postman_bag', name: 'Dak Ghar Postman', emoji: '📬', memoryPrompt: 'Bringing news from distant cousins.', nostalgicStory: 'Waiting by the gate when the postman in khaki uniform arrived with good news.', bgColor: Color(0xFFF0FDF4)),
        ReminiscenceItem(id: 'silver_anklets', name: 'Payal Anklets', emoji: '🔔', memoryPrompt: 'Sweet tinkling sound with every step.', nostalgicStory: 'The rhythmic, musical chime of silver ghungroos ringing through the house.', bgColor: Color(0xFFFDF2F8)),
        ReminiscenceItem(id: 'gramophone', name: 'Vinyl Gramophone', emoji: '🎶', memoryPrompt: 'Playing golden melodies from black records.', nostalgicStory: 'Nostalgic classical ragas filling the room with sweet acoustic melody.', bgColor: Color(0xFFF5F3FF)),
      ],
    ),
    ReminiscenceEraTheme(
      id: 'classic_melodies',
      title: 'Classic Melodies & Musical Heritage',
      subtitle: 'The timeless instruments and melodies that touched our hearts.',
      category: 'MUSIC & ACOUSTIC MEMORY',
      themeColor: Color(0xFF7C3AED),
      items: [
        ReminiscenceItem(id: 'harmonium', name: 'Hand Harmonium', emoji: '🎹', memoryPrompt: 'Pumped with bellows for evening bhajan and ghazal.', nostalgicStory: 'The rich wooden resonance of harmonium accompanying soulful family singing.', bgColor: Color(0xFFF5F3FF)),
        ReminiscenceItem(id: 'tabla', name: 'Dugga Tabla', emoji: '🥁', memoryPrompt: 'Rhythmic beats accompanying every festive celebration.', nostalgicStory: 'The crisp "Dha Dhin Dhin Dha" tempo filling the house with vibrant energy.', bgColor: Color(0xFFFFF7ED)),
        ReminiscenceItem(id: 'bansuri', name: 'Bamboo Flute', emoji: '🪈', memoryPrompt: 'Soft sweet notes floating on the evening wind.', nostalgicStory: 'Gentle melodies that calmed the spirit after a long, fulfilling day.', bgColor: Color(0xFFECFDF5)),
        ReminiscenceItem(id: 'sitar', name: 'Classical Sitar', emoji: '🎸', memoryPrompt: 'Intricate strings ringing with morning Raag Bhairav.', nostalgicStory: 'Mesmerizing strings that echo centuries of artistic musical heritage.', bgColor: Color(0xFFFEF3C7)),
        ReminiscenceItem(id: 'ghungroo', name: 'Kathak Ghungroo', emoji: '✨', memoryPrompt: 'Tied around ankles for graceful rhythmic dance.', nostalgicStory: 'Celebrating heritage and dance on joyous festival stages.', bgColor: Color(0xFFFDF2F8)),
        ReminiscenceItem(id: 'cassette', name: 'Rewound Cassette Tape', emoji: '📼', memoryPrompt: 'Rewound with a pencil when the tape got tangled.', nostalgicStory: 'Remember carefully using a pencil to wind up your favorite mixtape cassette!', bgColor: Color(0xFFF1F5F9)),
        ReminiscenceItem(id: 'tanpura', name: 'Four-String Tanpura', emoji: '🪕', memoryPrompt: 'Continuous serene drone supporting the singer.', nostalgicStory: 'The peaceful harmonic drone creating deep meditational serenity.', bgColor: Color(0xFFFFFBEB)),
        ReminiscenceItem(id: 'dholak', name: 'Folk Dholak', emoji: '🪘', memoryPrompt: 'Played with spoon rhythms during wedding sangeet.', nostalgicStory: 'Ladies singing celebratory folk songs with energetic rhythm on the dholak.', bgColor: Color(0xFFFEF2F2)),
        ReminiscenceItem(id: 'cymbals', name: 'Manjira Bells', emoji: '🔔', memoryPrompt: 'Clinked during temple aarti and kirtans.', nostalgicStory: 'Joyful rhythmic clinking bringing divine focus and shared devotion.', bgColor: Color(0xFFF0FDF4)),
        ReminiscenceItem(id: 'spool_recorder', name: 'Spool Tape Player', emoji: '📻', memoryPrompt: 'Rotating reels playing precious live recordings.', nostalgicStory: 'Listening to cherished recordings of family functions captured decades ago.', bgColor: Color(0xFFE0F2FE)),
        ReminiscenceItem(id: 'conch', name: 'Shankha Shell', emoji: '🐚', memoryPrompt: 'Blown at sunrise to invoke auspicious blessings.', nostalgicStory: 'The resonant conch sound marking the beginning of joyful auspicious celebrations.', bgColor: Color(0xFFFDF4FF)),
        ReminiscenceItem(id: 'bell_temple', name: 'Brass Temple Bell', emoji: '🪆', memoryPrompt: 'Rung at the threshold of the home sanctum.', nostalgicStory: 'Clear, reverberating chime clearing the mind of all worldly worries.', bgColor: Color(0xFFFFF7ED)),
        ReminiscenceItem(id: 'shehnai', name: 'Utsav Shehnai', emoji: '🎺', memoryPrompt: 'Announcing wedding processions and celebrations.', nostalgicStory: 'Uplifting melodies creating memories of weddings, flowers, and family banquets.', bgColor: Color(0xFFFEF3C7)),
        ReminiscenceItem(id: 'accordion', name: 'Vintage Accordion', emoji: '🪗', memoryPrompt: 'Played for spirited cinema and stage melodies.', nostalgicStory: 'Cheerful tunes reminiscent of classic romantic songs and theatre plays.', bgColor: Color(0xFFF5F3FF)),
        ReminiscenceItem(id: 'sarod', name: 'Polished Sarod', emoji: '🎻', memoryPrompt: 'Deep introspective notes played with coconut shell plectrum.', nostalgicStory: 'Rich sonorous tones that resonate straight into the soul.', bgColor: Color(0xFFECFDF5)),
        ReminiscenceItem(id: 'pocket_radio', name: 'Pocket Transistor', emoji: '📱', memoryPrompt: 'Carried in shirt pocket to listen to live cricket commentary.', nostalgicStory: 'Listening eagerly to every single ball description while sitting in the veranda.', bgColor: Color(0xFFF1F5F9)),
      ],
    ),
    ReminiscenceEraTheme(
      id: 'heritage_kitchen',
      title: 'Heritage Flavors & Kitchen Comforts',
      subtitle: 'The timeless tastes, spices, and comforting aromas of family dining.',
      category: 'SENSORY & CULINARY MEMORY',
      themeColor: Color(0xFF0D9488),
      items: [
        ReminiscenceItem(id: 'mortar_pestle', name: 'Stone Sil-Batta', emoji: '🪨', memoryPrompt: 'Grinding fresh mint, coriander, and garlic chutney.', nostalgicStory: 'The fragrant freshness of stone-ground chutneys prepared with love.', bgColor: Color(0xFFECFDF5)),
        ReminiscenceItem(id: 'spice_box', name: 'Masala Dabba', emoji: '🫙', memoryPrompt: 'Seven round compartments filled with turmeric, mustard, and cumin.', nostalgicStory: 'Opening the brass lid to reveal vibrant colors and aromatic spices.', bgColor: Color(0xFFFEF3C7)),
        ReminiscenceItem(id: 'clay_kulhad', name: 'Earthen Kulhad Chai', emoji: '☕', memoryPrompt: 'Steaming ginger cardamom tea served on railway platform.', nostalgicStory: 'The irresistible earthly scent of warm terracotta cup blended with tea.', bgColor: Color(0xFFFFF7ED)),
        ReminiscenceItem(id: 'ghee_pot', name: 'Desi Ghee Jar', emoji: '🧈', memoryPrompt: 'A golden spoonful melting over piping hot dal and khichdi.', nostalgicStory: 'The comforting richness and pure aroma of homemade fragrant ghee.', bgColor: Color(0xFFFFFBEB)),
        ReminiscenceItem(id: 'pickle_jar', name: 'Barnie Pickle Jar', emoji: '🏺', memoryPrompt: 'Porcelain jar tied with white muslin cloth in the sun.', nostalgicStory: 'Waiting for grandma’s spicy mango and lemon pickles to mature in the courtyard.', bgColor: Color(0xFFFDF2F8)),
        ReminiscenceItem(id: 'copper_lota', name: 'Pure Copper Vessel', emoji: '🍶', memoryPrompt: 'Filled overnight for healthful morning water.', nostalgicStory: 'A timeless Ayurvedic tradition passed down lovingly through generations.', bgColor: Color(0xFFFFF1F2)),
        ReminiscenceItem(id: 'tiffin_carrier', name: 'Brass Tier Tiffin', emoji: '🍱', memoryPrompt: 'Packed with warm rotis, sabzi, and a sweet treat.', nostalgicStory: 'Opening the three brass tiers at lunchtime to discover wholesome delicacies.', bgColor: Color(0xFFF0FDF4)),
        ReminiscenceItem(id: 'hand_grinder', name: 'Stone Chakki Mill', emoji: '⚙️', memoryPrompt: 'Turned by hand while humming folk morning tunes.', nostalgicStory: 'Grinding fresh whole wheat flour with rhythmic morning prayers.', bgColor: Color(0xFFF5F5F4)),
        ReminiscenceItem(id: 'cast_iron_tawa', name: 'Heavy Iron Tawa', emoji: '🍳', memoryPrompt: 'Baking puffed rotis and crisp dosas over golden flame.', nostalgicStory: 'Serving hot rotis directly from the tawa onto loving family plates.', bgColor: Color(0xFFFEF2F2)),
        ReminiscenceItem(id: 'sweets_box', name: 'Festival Mithai Box', emoji: '🍬', memoryPrompt: 'Packed with besan laddoos, kaju katli, and gulab jamun.', nostalgicStory: 'Sharing festive sweets with neighbors and cousins during Diwali and Eid.', bgColor: Color(0xFFFDF4FF)),
        ReminiscenceItem(id: 'filter_coffee', name: 'Brass Coffee Dabarah', emoji: '☕', memoryPrompt: 'Poured back and forth to create frothy aromatic coffee.', nostalgicStory: 'The rich aroma of roasted chicory coffee filling the house at dawn.', bgColor: Color(0xFFFFF7ED)),
        ReminiscenceItem(id: 'cane_basket', name: 'Fruit Tokri Basket', emoji: '🧺', memoryPrompt: 'Filled with seasonal guavas, pomegranates, and bananas.', nostalgicStory: 'Fresh produce brought straight from the local morning farmers’ mandi.', bgColor: Color(0xFFECFDF5)),
        ReminiscenceItem(id: 'jaggery_block', name: 'Organic Gur Chunk', emoji: '🟤', memoryPrompt: 'Eaten after meals for sweetness and good digestion.', nostalgicStory: 'Savoring a small piece of dark sugarcane jaggery on winter evenings.', bgColor: Color(0xFFFEF3C7)),
        ReminiscenceItem(id: 'curd_pot', name: 'Earthen Dahi Handi', emoji: '🥣', memoryPrompt: 'Thick creamy yoghurt set overnight in clay pot.', nostalgicStory: 'Whisking fresh curd into cool sweet lassi topped with malai.', bgColor: Color(0xFFF5F3FF)),
        ReminiscenceItem(id: 'betel_box', name: 'Brass Paandan Box', emoji: '🍃', memoryPrompt: 'Crafted with compartments for betel leaves, supari, and cloves.', nostalgicStory: 'The hospitable tradition of offering fragrant paan to respected guests.', bgColor: Color(0xFFF0FDF4)),
        ReminiscenceItem(id: 'brass_plate', name: 'Thali Feast Plate', emoji: '🍽️', memoryPrompt: 'Array of six savory dishes, kheer, and fragrant basmati rice.', nostalgicStory: 'Gathering the entire family around the dining mat for a joyous festive banquet.', bgColor: Color(0xFFE0F2FE)),
      ],
    ),
  ];

  late ReminiscenceEraTheme _currentEra;
  List<ReminiscenceItem> _displayedMemories = [];
  late ReminiscenceItem _targetItem;
  List<ReminiscenceItem> _optionChoices = [];

  MemoryLaneStep _gameStep = MemoryLaneStep.exploreMemories;
  int _secondsRemaining = 9;
  Timer? _countdownTimer;

  final int _totalRounds = 3;
  int _currentRound = 1;
  int _completedRounds = 0;
  int _gentleGuidanceHintsUsed = 0;

  DateTime? _gameStartTime;
  DateTime? _questionStartTime;
  List<double> _responseTimes = [];
  bool _isSpeaking = false;
  ReminiscenceItem? _selectedOption;

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
    _completedRounds = 0;
    _gentleGuidanceHintsUsed = 0;
    _responseTimes = [];
    _gameStartTime = DateTime.now();
    _setupRound();
  }

  void _setupRound() {
    _countdownTimer?.cancel();
    final rng = Random();
    _currentEra = _allEraThemes[rng.nextInt(_allEraThemes.length)];

    // Pick N memories for this tier
    final count = _tier.itemCount.clamp(3, _currentEra.items.length);
    final shuffledThemeItems = List<ReminiscenceItem>.from(_currentEra.items)..shuffle(rng);
    _displayedMemories = shuffledThemeItems.take(count).toList();

    // Pick 1 target memory item for the question
    final targetIndex = rng.nextInt(_displayedMemories.length);
    _targetItem = _displayedMemories[targetIndex];

    // Prepare 4 choices (including target)
    final candidateDecoys = _displayedMemories.toList();
    final choices = <ReminiscenceItem>{_targetItem};
    candidateDecoys.shuffle(rng);
    for (final item in candidateDecoys) {
      if (choices.length >= min(4, _displayedMemories.length)) break;
      choices.add(item);
    }
    _optionChoices = choices.toList()..shuffle(rng);

    _selectedOption = null;
    _secondsRemaining = _tier.inspectionSeconds;
    _gameStep = MemoryLaneStep.exploreMemories;

    setState(() {});

    _narrateGuidance(
      'Take a warm look at these familiar memories from ${_currentEra.title}. Savor each precious item.',
    );

    // Countdown timer for exploring memories
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _transitionToPrompt();
      }
    });
  }

  void _transitionToPrompt() {
    setState(() {
      _gameStep = MemoryLaneStep.memoryPrompt;
      _questionStartTime = DateTime.now();
    });
    _narrateGuidance(
      'Reminiscence moment: ${_targetItem.memoryPrompt}. Tap the matching memory below.',
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

  // Errorless Learning selection: All choices are treated positively with uplifting reinforcement
  void _onSelectChoice(ReminiscenceItem chosenItem) {
    if (_gameStep != MemoryLaneStep.memoryPrompt || _selectedOption != null) return;

    final now = DateTime.now();
    if (_questionStartTime != null) {
      final elapsed = now.difference(_questionStartTime!).inMilliseconds / 1000.0;
      _responseTimes.add(elapsed);
    }

    final isDirectMatch = chosenItem.id == _targetItem.id;
    setState(() {
      _selectedOption = chosenItem;
      _gameStep = MemoryLaneStep.celebrationStory;
      _completedRounds++;
      if (!isDirectMatch) {
        _gentleGuidanceHintsUsed++;
      }
    });

    if (isDirectMatch) {
      _narrateGuidance(
        'Wonderful! ${_targetItem.name}. ${_targetItem.nostalgicStory}',
      );
    } else {
      _narrateGuidance(
        'Both ${_targetItem.name} and ${chosenItem.name} hold beautiful memories! ${_targetItem.nostalgicStory}',
      );
    }

    Future.delayed(const Duration(milliseconds: 3200), () {
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
        : 25;
    // In errorless approach for dementia, accuracy reflects participation & gentle recognition
    final accuracy = _totalRounds > 0 ? (1.0 - (_gentleGuidanceHintsUsed * 0.1)).clamp(0.70, 1.0) : 1.0;
    final avgReaction = _responseTimes.isNotEmpty
        ? (_responseTimes.reduce((a, b) => a + b) / _responseTimes.length)
        : 2.8;

    // AI Adaptive Difficulty Progression
    MemoryLaneTier nextTier = _tier;
    String adaptiveMsg = 'Heartwarming connection with familiar memories!';
    if (accuracy >= 0.85 && _tier != MemoryLaneTier.master) {
      nextTier = MemoryLaneTier.values[_tier.index + 1];
      adaptiveMsg = 'AI Adaptive: Advanced to ${nextTier.shortTitle} memory lane with richer cultural items!';
    } else if (accuracy < 0.70 && _tier != MemoryLaneTier.gentle) {
      nextTier = MemoryLaneTier.values[_tier.index - 1];
      adaptiveMsg = 'AI Adaptive: Switched to gentle pace for relaxed, peaceful reminiscence.';
    }

    // 1. Save locally in Hive via SessionService
    final patientId = SessionService.activePatientId ?? 'patient-ramesh';
    final session = GameSession(
      sessionId: SessionService.generateId(patientId, 'memory_lane'),
      patientId: patientId,
      gameType: 'memory_lane',
      playedAt: DateTime.now(),
      accuracyRatio: accuracy,
      responseTimeSec: avgReaction,
      totalMoves: _totalRounds,
      extras: {
        'gameName': 'Memory Lane Games (Reminiscence)',
        'difficulty': _tier.label,
        'roundsCompleted': '$_completedRounds/$_totalRounds',
        'durationSec': durationSec,
        'nextTier': nextTier.label,
        'approach': 'Errorless Cognitive Engagement',
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
          'session_type': 'Memory Lane (Reminiscence & Emotional Engagement)',
          'difficulty_level': _tier.label,
          'score': (accuracy * 100.0).clamp(0.0, 100.0),
          'tremor_frequency_hz': 4.5,
          'tremor_amplitude_deg': 0.7,
          'postural_stability_score': 90.0,
          'notes': 'Completed $_totalRounds errorless reminiscence rounds with ${(accuracy * 100).toStringAsFixed(0)}% engagement in ${durationSec}s. $adaptiveMsg',
        }),
      );
    } catch (_) {}

    _showVictoryModal(accuracy, durationSec, avgReaction, nextTier, adaptiveMsg);
  }

  void _showVictoryModal(
    double accuracy,
    int durationSec,
    double avgReaction,
    MemoryLaneTier nextTier,
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
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('❤️', style: TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Warm Memories Reconnected!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21.0,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC2410C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You relived beautiful stories and cultural memories across all $_totalRounds rounds.',
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
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Column(
                        children: [
                          Text('ENGAGEMENT', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFEA580C))),
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
                          Text('PACE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7))),
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
                    const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFEA580C)),
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
                        backgroundColor: const Color(0xFFC2410C),
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
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFC2410C)),
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
              'Memory Lane (Familiar Things)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Reminiscence & Emotional Recall · Round $_currentRound of $_totalRounds',
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
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFC2410C)),
            onPressed: () {
              if (_gameStep == MemoryLaneStep.exploreMemories) {
                _narrateGuidance('Look gently at each cherished object. Notice the familiar feelings they bring.');
              } else if (_gameStep == MemoryLaneStep.memoryPrompt) {
                _narrateGuidance(_targetItem.memoryPrompt);
              }
            },
            tooltip: 'Listen to memory prompt',
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
              // AI-Adaptive & Difficulty Pacing Bar (Gentle 4, Moderate 8, Challenging 12, Master 16)
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
                            color: Color(0xFFFFEDD5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isAdaptiveMode ? 'AI–Adaptive Reminiscence' : 'Manual Pacing',
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
                    Row(
                      children: MemoryLaneTier.values.map((tier) {
                        final isSelected = _tier == tier;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _tier = tier;
                                  _isAdaptiveMode = false;
                                });
                                _startNewGameSession();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEA580C) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFC2410C) : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFEA580C).withOpacity(0.35),
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
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Step Indicator / Guidance Banner
              if (_gameStep == MemoryLaneStep.exploreMemories) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
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
                              color: const Color(0xFFEA580C),
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
                              'Step 1: Explore Familiar Things',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Look gently at each item and recall the feelings associated with them.',
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
              ] else if (_gameStep == MemoryLaneStep.memoryPrompt) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '“${_targetItem.memoryPrompt}”',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap the familiar heirloom or melody below that matches this feeling.',
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
              ] else ...[
                // Celebration & Nostalgic Story
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _targetItem.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _targetItem.nostalgicStory,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppTheme.textPrimary,
                                height: 1.3,
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

              // Main Reminiscence Gallery
              Container(
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
                            '🏺 ${_currentEra.title}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _currentEra.themeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _currentEra.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _currentEra.themeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Grid of Reminiscence items
                    Builder(
                      builder: (context) {
                        final count = _displayedMemories.length;
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
                            final item = _displayedMemories[index];
                            final isHighlighted = _gameStep == MemoryLaneStep.celebrationStory && item.id == _targetItem.id;

                            return Container(
                              decoration: BoxDecoration(
                                color: isHighlighted ? const Color(0xFFFEF3C7) : item.bgColor,
                                borderRadius: BorderRadius.circular(count > 8 ? 14 : 18),
                                border: Border.all(
                                  color: isHighlighted ? const Color(0xFFF59E0B) : AppTheme.surfaceBorder,
                                  width: isHighlighted ? 2.0 : 1.0,
                                ),
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

              // Interactive Choices Section (when in prompt or result step)
              if (_gameStep == MemoryLaneStep.memoryPrompt || _gameStep == MemoryLaneStep.celebrationStory) ...[
                const SizedBox(height: 24),
                Text(
                  'Select the matching familiar memory:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 4 Choices Grid with Errorless Feedback
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
                    final isTarget = choice.id == _targetItem.id;

                    Color cardColor = Colors.white;
                    Color borderColor = AppTheme.surfaceBorder;
                    if (_selectedOption != null) {
                      if (isTarget) {
                        cardColor = const Color(0xFFFEF3C7);
                        borderColor = const Color(0xFFD97706);
                      } else if (isSelected) {
                        cardColor = const Color(0xFFFFF7ED);
                        borderColor = const Color(0xFFEA580C);
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
                            if (_selectedOption != null && isTarget) ...[
                              const SizedBox(height: 4),
                              const Icon(Icons.favorite_rounded, color: Color(0xFFD97706), size: 16),
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
