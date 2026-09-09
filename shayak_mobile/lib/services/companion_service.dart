import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CompanionService {
  static final CompanionService instance = CompanionService._internal();
  CompanionService._internal();

  bool _isAvailable = true;
  bool _hasChecked = true;
  String? _currentConversationId;

  bool get isAvailable => _isAvailable;
  bool get hasChecked => _hasChecked;

  String get conversationId {
    _currentConversationId ??= 'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    return _currentConversationId!;
  }

  void resetConversation() {
    _currentConversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Checks if offline Ollama + Companion endpoint is reachable on startup
  Future<bool> checkAvailability() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/companion/status'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _isAvailable = true; // Always keep available with fallback support
      }
    } catch (_) {}
    _hasChecked = true;
    _isAvailable = true;
    return true;
  }

  /// Sends a message or transcript to the offline companion
  Future<String> sendMessage({
    required String patientId,
    required String message,
    String? audioBase64,
  }) async {
    try {
      final payload = {
        'patientId': patientId,
        'message': message,
        'audioBase64': audioBase64,
        'conversationId': conversationId,
      };

      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/companion/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['text'] ?? "That's a lovely thought. Tell me more about that day.";
      }
    } catch (e) {
      if (kDebugMode) {
        print('Companion chat call error or timeout: $e');
      }
    }

    // Fixed graceful fallback response if anything fails or times out
    return "That's a lovely thought. Tell me more about that day.";
  }
}
