import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/patient_profile.dart';
import '../services/audio_narration_service.dart';
import '../services/companion_service.dart';
import '../services/localization_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  bool _isHoldingToSpeak = false;
  Timer? _holdTimer;
  int _holdSeconds = 0;

  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initFirstGreeting();
  }

  Future<void> _initFirstGreeting() async {
    setState(() {
      _isLoading = true;
    });

    // Ask Gemma LLM directly for an opening greeting
    final greeting = await CompanionService.instance.sendMessage(
      patientId: widget.patientId,
      message: "Greet me warmly and ask me about a pleasant memory from my youth.",
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: greeting,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _speakResponse(greeting);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _holdTimer?.cancel();
    AudioNarrationService.instance.stop();
    super.dispose();
  }

  Future<void> _speakResponse(String text) async {
    final lang = LocalizationService.instance.currentLanguage;
    await AudioNarrationService.instance.speak(text, language: lang);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final trimmed = userText.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _textController.clear();
    });

    _scrollToBottom();
    _focusNode.unfocus();

    // Call live local Ollama Gemma LLM API
    final reply = await CompanionService.instance.sendMessage(
      patientId: widget.patientId,
      message: trimmed,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
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

    final currentTyped = _textController.text.trim();
    if (currentTyped.isNotEmpty) {
      _handleSendMessage(currentTyped);
    } else {
      _handleSendMessage("Hello Gemma! Tell me a nice story or thought.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, lang, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 2,
                                        children: [
                                          Text(
                                            'Sahayak Companion',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.forestGreen,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE6F4EA),
                                              borderRadius: BorderRadius.circular(100),
                                              border: Border.all(color: const Color(0xFF34A853).withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF34A853),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Gemma 2B LLM',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF137333),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Real-time offline conversational reminiscence',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 22),
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

                // Real-Time Chat Conversation Stream
                Expanded(
                  child: _messages.isEmpty && _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: AppTheme.forestGreen),
                              const SizedBox(height: 16),
                              Text(
                                'Starting Gemma LLM Neural Model...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isLoading) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.sageBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.forestGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Thinking with Gemma...',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            color: AppTheme.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final msg = _messages[index];
                            final isMe = msg.isUser;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppTheme.forestTealCard : Colors.white,
                                    borderRadius: BorderRadius.circular(20).copyWith(
                                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                      bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                                    ),
                                    border: isMe ? null : Border.all(color: AppTheme.sageBorder, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.text,
                                        style: isMe
                                            ? GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                                height: 1.4,
                                              )
                                            : GoogleFonts.plusJakartaSans(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                                height: 1.45,
                                              ),
                                      ),
                                      if (!isMe) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _speakResponse(msg.text),
                                              borderRadius: BorderRadius.circular(100),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.sageLight,
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.volume_up_rounded, size: 14, color: AppTheme.forestGreen),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Listen',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppTheme.forestGreen,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Quick Suggestion Topics
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickTopicChip('🌾 Village Festivals', 'Tell me about festivals you celebrated in your village.'),
                        const SizedBox(width: 8),
                        _buildQuickTopicChip('🍲 Favorite Foods', 'What was your favorite home-cooked dish?'),
                        const SizedBox(width: 8),
                        _buildQuickTopicChip('🌸 Courtyard Days', 'Tell me about the courtyard in your childhood home.'),
                        const SizedBox(width: 8),
                        _buildQuickTopicChip('🌿 Tea Gardens', 'I loved walking through the morning tea gardens.'),
                      ],
                    ),
                  ),
                ),

                // Bottom Input: Hold to speak OR Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isHoldingToSpeak ? AppTheme.warmTerracotta : AppTheme.forestGreen,
                            borderRadius: BorderRadius.circular(28.0),
                            boxShadow: [
                              BoxShadow(
                                color: (_isHoldingToSpeak ? AppTheme.warmTerracotta : AppTheme.forestGreen).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
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
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isHoldingToSpeak
                                      ? 'Listening... ($_holdSeconds s) · Release to send'
                                      : 'Hold to Speak / बोलें',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Text input field
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 46,
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
                                  hintText: 'Type any thought or question...',
                                  hintStyle: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.textLight),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                                onSubmitted: (val) => _handleSendMessage(val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppTheme.forestGreen, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.sageLight,
                              padding: const EdgeInsets.all(10),
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

  Widget _buildQuickTopicChip(String label, String prompt) {
    return InkWell(
      onTap: () => _handleSendMessage(prompt),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.forestGreen,
          ),
        ),
      ),
    );
  }
}
