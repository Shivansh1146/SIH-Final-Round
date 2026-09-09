import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/patient_profile.dart';
import '../services/audio_narration_service.dart';
import '../services/companion_service.dart';
import '../services/localization_service.dart';

class CompanionModal extends StatefulWidget {
  final String patientId;
  final String patientName;

  const CompanionModal({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  static Future<void> show(BuildContext context, {required String patientId, required String patientName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CompanionModal(patientId: patientId, patientName: patientName),
    );
  }

  @override
  State<CompanionModal> createState() => _CompanionModalState();
}

class _CompanionModalState extends State<CompanionModal> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isHoldingToSpeak = false;
  Timer? _holdTimer;
  int _holdSeconds = 0;

  String _currentPrompt = "Hello! Tell me about something happy from your days.";
  String? _lastUserSpoken;

  @override
  void initState() {
    super.initState();
    // Greet with validation/reminiscence prompt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakResponse(_currentPrompt);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _holdTimer?.cancel();
    AudioNarrationService.instance.stop();
    super.dispose();
  }

  Future<void> _speakResponse(String text) async {
    final lang = LocalizationService.instance.currentLanguage;
    await AudioNarrationService.instance.speak(text, language: lang);
  }

  Future<void> _handleSendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _lastUserSpoken = userText.trim();
      _textController.clear();
    });

    _focusNode.unfocus();

    final reply = await CompanionService.instance.sendMessage(
      patientId: widget.patientId,
      message: userText,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentPrompt = reply;
      });
      await _speakResponse(reply);
    }
  }

  void _onStartHoldSpeak() {
    setState(() {
      _isHoldingToSpeak = true;
      _holdSeconds = 0;
    });
    AudioNarrationService.instance.stop();

    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _holdSeconds++;
        });
      }
    });
  }

  void _onStopHoldSpeak() {
    _holdTimer?.cancel();
    if (!_isHoldingToSpeak) return;

    setState(() {
      _isHoldingToSpeak = false;
    });

    // Simulated speech recognition / native audio pass-through
    final simulatedPhrases = [
      "We used to celebrate Bihu with the whole family in our village.",
      "My grandmother used to make the best pithas during harvest festival.",
      "I was remembering the river bank where we used to walk every evening.",
      "The tea gardens in the morning always smelled so fresh.",
      "We had a big courtyard with mango trees where all the children played.",
    ];
    final chosen = (simulatedPhrases..shuffle()).first;
    _handleSendMessage(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, lang, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top drag handle & header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBorder,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.sageLight,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.sageBorder),
                                ),
                                child: const Center(
                                  child: Text('🌿', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Warm Companion',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.forestGreen,
                                    ),
                                  ),
                                  Text(
                                    'Sharing pleasant memories · Offline',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 24),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.surfaceBorder),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppTheme.surfaceBorder, height: 1),

                // Main Spoken Memory / Story Area (No chat-bubble clutter, natural speaking feel)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_lastUserSpoken != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                const Text('🗣️', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _lastUserSpoken!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Main Companion Response (Large, high legibility for elderly readers)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.sageBorder, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.forestGreen.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.sageLight,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Text(
                                          'Listening & Reminiscing 🌸',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.forestGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen, size: 24),
                                    tooltip: 'Listen again',
                                    onPressed: () => _speakResponse(_currentPrompt),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isLoading) ...[
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppTheme.forestGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Recalling gentle thoughts...',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: AppTheme.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  _currentPrompt,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    height: 1.45,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Suggested gentle reminiscence prompts
                        Text(
                          'Tap a topic to talk about:',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildQuickChip('🌾 Village Festivals', 'Tell me about festivals you celebrated in your village.'),
                            _buildQuickChip('🍲 Favorite Foods', 'What was your favorite home-cooked dish?'),
                            _buildQuickChip('🌸 Childhood Courtyard', 'Tell me about the courtyard in your childhood home.'),
                            _buildQuickChip('🎶 Favorite Songs', 'What songs did people sing during harvests?'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action: Tap-and-hold to speak OR Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hold to speak button (28px rounded primary button)
                      GestureDetector(
                        onTapDown: (_) => _onStartHoldSpeak(),
                        onTapUp: (_) => _onStopHoldSpeak(),
                        onTapCancel: () => _onStopHoldSpeak(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            color: _isHoldingToSpeak ? AppTheme.warmTerracotta : AppTheme.forestGreen,
                            borderRadius: BorderRadius.circular(28.0),
                            boxShadow: [
                              BoxShadow(
                                color: (_isHoldingToSpeak ? AppTheme.warmTerracotta : AppTheme.forestGreen).withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isHoldingToSpeak ? Icons.mic_rounded : Icons.mic_none_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isHoldingToSpeak
                                      ? 'Listening... ($_holdSeconds s) · Release to send'
                                      : 'Hold to Speak / बोलें',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Or type text input field
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Or type your thought here...',
                                  hintStyle: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.textLight),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onSubmitted: (val) => _handleSendMessage(val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppTheme.forestGreen, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.sageLight,
                              padding: const EdgeInsets.all(12),
                            ),
                            onPressed: () => _handleSendMessage(_textController.text),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickChip(String label, String prompt) {
    return InkWell(
      onTap: () => _handleSendMessage(prompt),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.forestGreen,
          ),
        ),
      ),
    );
  }
}
