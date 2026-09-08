import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'game_menu_screen.dart';

/// ============================================================================
/// SHAYAK-AI: Persistent Accessible 4-Tab Navigation Shell
/// Features large touch targets (64px minimum bar items), persistent high-contrast
/// labels, WCAG AAA compliant active pill indicators, and zero complex gestures.
/// ============================================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToGames: () => _onTabSelected(1)),
      const GameMenuScreen(),
      const VoiceAssistantScreen(),
      const RecordsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.darkNavy,
          border: Border(
            top: BorderSide(color: AppTheme.cardNavyBorder, width: 2.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Play',
                  icon: Icons.games_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Voice',
                  icon: Icons.mic_rounded,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Records',
                  icon: Icons.assignment_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Semantics(
        label: '$label Tab',
        selected: isSelected,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onTabSelected(index),
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              // Exceeds 56x56 minimum accessible touch target
              height: 64.0,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppTheme.cardNavy,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: AppTheme.warmAmber, width: 2.0),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 30.0,
                    color: isSelected ? AppTheme.warmAmber : AppTheme.mutedSlate,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.softWarmCream : AppTheme.mutedSlate,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// ============================================================================
/// Tab 3: Regional Voice Assistant (Bhashini ULCA & Whisper Pipeline)
/// Accessible acoustic biomarker trigger with visual sound-wave feedback.
/// ============================================================================
class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _selectedLanguage = 'Bengali (বাংলা)';
  late AnimationController _waveController;

  final List<String> _languages = [
    'Assamese (অসমীয়া)',
    'Bengali (বাংলা)',
    'Bodo (बड़ो)',
    'Manipuri (মৈতৈলোন্)',
    'Hindi (हिन्दी)',
    'English',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        title: Text(
          'Regional Voice Assistant',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Regional Language Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy,
                  borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                  border: Border.all(color: AppTheme.cardNavyBorder, width: 2.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: AppTheme.warmAmber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          dropdownColor: AppTheme.cardNavy,
                          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.softWarmCream, size: 32),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          isExpanded: true,
                          items: _languages.map((lang) {
                            return DropdownMenuItem(value: lang, child: Text(lang));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLanguage = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Conversational Guidance
              Text(
                _isListening
                    ? 'Listening in $_selectedLanguage...\nSpeak naturally about your day.'
                    : 'Tap the large microphone button below to begin talking with Shayak.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  height: 1.4,
                  color: _isListening ? AppTheme.warmAmber : AppTheme.softWarmCream,
                ),
              ),

              const Spacer(),

              // Visual Sound-Wave Feedback Animation
              if (_isListening)
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(7, (index) {
                        final heights = [28.0, 56.0, 84.0, 110.0, 75.0, 48.0, 30.0];
                        final scale = 0.5 + (_waveController.value * 0.5 * ((index % 3) + 1));
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          width: 10.0,
                          height: (heights[index] * scale).clamp(20.0, 120.0),
                          decoration: BoxDecoration(
                            color: AppTheme.warmAmber,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        );
                      }),
                    );
                  },
                )
              else
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text(
                    'Acoustic Biomarker Pipeline Ready\n(Assessing Phonation & Hesitations)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.mutedSlate, fontSize: 16),
                  ),
                ),

              const Spacer(),

              // Ultra-Large Accessible Microphone Button (> 96px target)
              Semantics(
                label: _isListening ? 'Stop Recording' : 'Start Voice Conversation',
                button: true,
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 110.0,
                    height: 110.0,
                    decoration: BoxDecoration(
                      color: _isListening ? AppTheme.alertCoral : AppTheme.warmAmber,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.softWarmCream, width: 4.0),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppTheme.alertCoral : AppTheme.warmAmber)
                              .withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 60.0,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isListening ? 'Tap to Stop & Analyze' : 'Tap to Start Speaking',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.softWarmCream,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// Tab 4: Patient Longitudinal Records & Doctor Review
/// Visualizes offline-first cached assessments and clinical synchronization.
/// ============================================================================
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        title: Text(
          'My Health Records',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Synchronization Status Badge
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.cardNavy,
                borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                border: Border.all(color: AppTheme.successMint, width: 2.0),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: AppTheme.successMint, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Encrypted & Synced',
                          style: TextStyle(
                            color: AppTheme.successMint,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your caregiver and doctor receive instant updates.',
                          style: TextStyle(color: AppTheme.softWarmCream, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Text(
              'Recent Assessment History',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),

            _buildRecordItem(
              context,
              date: 'Today, 9:30 AM',
              testName: 'Clock Drawing & Tremor Check',
              scoreText: 'Score: 9/10 (Normal Stability)',
              statusColor: AppTheme.successMint,
              icon: Icons.access_time_rounded,
            ),

            const SizedBox(height: 10),

            _buildRecordItem(
              context,
              date: 'Yesterday, 10:15 AM',
              testName: 'Memory Recall Pairs',
              scoreText: 'Score: 8/8 Matches Found',
              statusColor: AppTheme.successMint,
              icon: Icons.psychology_rounded,
            ),

            const SizedBox(height: 10),

            _buildRecordItem(
              context,
              date: '2 Days Ago, 4:00 PM',
              testName: 'Regional Voice Acoustic Biomarker',
              scoreText: 'Low Hesitation / Clear Phonation',
              statusColor: AppTheme.vibrantCyan,
              icon: Icons.mic_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(
    BuildContext context, {
    required String date,
    required String testName,
    required String scoreText,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: AppTheme.cardNavyBorder, width: 2.0),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.darkNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor, width: 1.5),
            ),
            child: Icon(icon, color: statusColor, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: AppTheme.mutedSlate,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  testName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  scoreText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
