import 'package:flutter/foundation.dart';
import '../models/patient_profile.dart';
import 'speech_platform_stub.dart'
    if (dart.library.html) 'speech_platform_web.dart'
    if (dart.library.io) 'speech_platform_io.dart';

class AudioNarrationService extends ChangeNotifier {
  static final AudioNarrationService instance = AudioNarrationService._internal();
  AudioNarrationService._internal();

  bool _isSpeaking = false;
  String? _currentlySpeakingText;

  bool get isSpeaking => _isSpeaking;
  String? get currentlySpeakingText => _currentlySpeakingText;

  Future<void> init() async {}

  Future<void> speak(String text, {AppLanguage? language}) async {
    final targetLang = language ?? PatientProfile.loadFromHive()?.preferredLanguage ?? AppLanguage.english;
    _currentlySpeakingText = text;
    _isSpeaking = true;
    notifyListeners();

    SpeechPlatformHelper.speakText(
      text,
      targetLang,
      onStart: () {
        _isSpeaking = true;
        notifyListeners();
      },
      onDone: () {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      },
      onError: () {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      },
    );
  }

  Future<void> narrate(String text, {AppLanguage? language}) => speak(text, language: language);

  Future<void> stop() async {
    SpeechPlatformHelper.stopSpeech();
    _isSpeaking = false;
    _currentlySpeakingText = null;
    notifyListeners();
  }
}
