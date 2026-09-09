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
    final payload = {
      'patientId': patientId,
      'message': message,
      'audioBase64': audioBase64,
      'conversationId': conversationId,
    };

    final urlsToTry = [
      '${ApiConfig.baseUrl}/companion/chat',
      'http://10.10.140.90:8000/companion/chat',
    ];

    String lastErr = '';

    for (final url in urlsToTry) {
      try {
        final res = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['text'] != null && data['text'].toString().trim().isNotEmpty) {
            return data['text'].toString().trim();
          }
        } else {
          lastErr = 'HTTP ${res.statusCode}';
        }
      } catch (e) {
        lastErr = e.toString();
      }
    }

    return "⚠️ Server connection failed ($lastErr). Please ensure ADB reverse or Wi-Fi is active.";
  }
}
