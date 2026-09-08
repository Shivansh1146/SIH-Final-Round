import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/patient_profile.dart';

class AudioNarrationService extends ChangeNotifier {
  static final AudioNarrationService instance = AudioNarrationService._internal();
  AudioNarrationService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String? _currentlySpeakingText;

  bool get isSpeaking => _isSpeaking;
  String? get currentlySpeakingText => _currentlySpeakingText;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _flutterTts.setSpeechRate(0.58); // Natural, clear conversational pacing
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('[AudioNarrationService] TTS Error: $msg');
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[AudioNarrationService] Initialization note: $e');
    }
  }

  String _mapLanguageToLocale(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:     return 'hi-IN';
      case AppLanguage.bengali:   return 'bn-IN';
      case AppLanguage.tamil:     return 'ta-IN';
      case AppLanguage.telugu:    return 'te-IN';
      case AppLanguage.marathi:   return 'mr-IN';
      case AppLanguage.gujarati:  return 'gu-IN';
      case AppLanguage.kannada:   return 'kn-IN';
      case AppLanguage.malayalam: return 'ml-IN';
      case AppLanguage.punjabi:   return 'pa-IN';
      case AppLanguage.english:
      default:                    return 'en-US';
    }
  }

  Future<void> speak(String text, {AppLanguage? language}) async {
    await init();
    if (_isSpeaking) {
      await stop();
    }

    _currentlySpeakingText = text;
    final targetLang = language ?? PatientProfile.load()?.language ?? AppLanguage.english;
    final localeTag = _mapLanguageToLocale(targetLang);

    try {
      await _flutterTts.setLanguage(localeTag);
      await _flutterTts.setSpeechRate(0.58);
    } catch (_) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.58);
    }

    _isSpeaking = true;
    notifyListeners();

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[AudioNarrationService] Speak error: $e');
      _isSpeaking = false;
      _currentlySpeakingText = null;
      notifyListeners();
    }
  }

  Future<void> narrate(String text, {AppLanguage? language}) => speak(text, language: language);

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('[AudioNarrationService] Stop error: $e');
    }
    _isSpeaking = false;
    _currentlySpeakingText = null;
    notifyListeners();
  }
}
